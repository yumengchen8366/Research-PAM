%% Y 轴步进电机移动测试：Dev1 P0.2/P0.3 → 鸣志 SR2（Y，243106105）→ 卓立汉光 CXPF50-80100 电动滑台
%
%  原理：SR2 在 STEP 线的每个下降沿走一步（一个微步）；DIR 线高/低决定方向。
%        移动距离 = 脉冲数 × 每个脉冲的距离；速度 = 脉冲频率 × 每个脉冲的距离。
%        脉冲由采集卡按硬件时钟产生，个数和间隔是精确的。
%
%  CXPF50-80100：行程 50 mm，丝杠导程 2 mm，电机 200 整步/转 → 整步 10 um，最大速度 20 mm/s
%  Y（10/14）：拨码和 X 相同（4000 步/转）；手摇端到端 27 圈 ≈ 54 mm（导程 2 mm）；
%             +1000 um 实测朝电机走约 1 mm。胶带记号在行程中间（从一端回摇 13.5 圈）。
%
%  使用前必须确认：
%   1. SR2 拨码开关的细分（每转步数），算出 UM_PER_PULSE
%   2. 滑台在行程中间，留有余量；已关闭占用 Dev1 的 LabVIEW 程序；激光处于安全状态
%   3. KORAD 开着（23.88 V、C.V），驱动器绿灯闪

RUN_HARDWARE = false;              % false：只计算并画图；确认无误后再改成 true，跑完改回 false
COUNT_CHECK  = true;               % true：用 ctr1 数 P0.2 发出的脉冲，需先把 PFI3 (P1.3) 的并线从 USER 1 挪到 P0.2 端子（docs/14 2.4）

%% 1. 每次移动只改这两行
MOVE_UM    = 10000;                % 移动距离 um：+ = 朝电机，- = 远离电机（10/14 实测）
SPEED_MM_S = 4;                    % 移动速度 mm/s（上限 MAX_SPEED_MM_S）

%% 2. 硬件参数（接线和驱动器设置不变时不用改）
STEP_LINE     = "port0/line2";     % P0.2 → SR2(Y) STEP−
DIR_LINE      = "port0/line3";     % P0.3 → SR2(Y) DIR−
POSITIVE_DIR  = 1;                 % MOVE_UM > 0 时 DIR = 1 → Y 朝电机走（10/14 实测）
STEPS_PER_REV = 200 * 20;          % Y 拨码 SW5–8 = ON OFF ON OFF = 4000 步/转（10/14 照片，同 X）
UM_PER_PULSE  = 2000 / STEPS_PER_REV;  % 导程 2000 um / 每转脉冲数 = 0.5 um（2.4 再用 10 mm 精确核对）
MAX_SPEED_MM_S = 4;                % 不加速起步的可靠上限（X 实测 4.8 mm/s 正常、5 mm/s 失步；Y 待 2.5）
MAX_MOVE_UM    = 10000;            % 单次移动上限 10 mm（2.4 要走 ±10 mm），防止误输入
CLOCK_AI       = "ai1";            % 给数字输出提供时钟的 AI 通道（只读，不输出）

%% 3. 由距离和速度换算出方向、脉冲数、脉冲频率
assert(abs(MOVE_UM) <= MAX_MOVE_UM, '单次移动 %.0f um 超过上限 %.0f um。', MOVE_UM, MAX_MOVE_UM);
assert(SPEED_MM_S > 0 && SPEED_MM_S <= MAX_SPEED_MM_S, '速度必须在 0 ~ %g mm/s 之间。', MAX_SPEED_MM_S);
if MOVE_UM >= 0
    DIRECTION = POSITIVE_DIR;
else
    DIRECTION = 1 - POSITIVE_DIR;
end
N_PULSES  = round(abs(MOVE_UM) / UM_PER_PULSE);
STEP_FREQ = SPEED_MM_S * 1000 / UM_PER_PULSE;   % Hz

% ---- 累计位置：命令位置，不是实测；胶带记号 = 0，+ = 朝电机 ----
POS_FILE       = fullfile(fileparts(mfilename('fullpath')), 'pos_Y.mat');
HALF_TRAVEL_UM = 27000;                % 记号到两端各约 27 mm（手摇 27 圈 ≈ 54 mm，从一端回摇 13.5 圈）
SOFT_LIMIT_UM  = 12000;                % 离记号最远 ±12 mm，两端各留约 15 mm
if isfile(POS_FILE)
    S = load(POS_FILE);  pos_um = S.pos_um;
else
    pos_um = 0;
    fprintf('没有 pos_Y.mat：假设 Y 现在在记号上（0 um）\n');
end
move_um   = sign(MOVE_UM) * N_PULSES * UM_PER_PULSE;   % 按整数脉冲算出的实际距离
target_um = pos_um + move_um;
fprintf('Y 现在 %+.1f um → 走完到 %+.1f um（离电机端约 %.1f mm，离远端约 %.1f mm）\n', ...
    pos_um, target_um, (HALF_TRAVEL_UM - target_um) / 1000, (HALF_TRAVEL_UM + target_um) / 1000);
assert(abs(target_um) <= SOFT_LIMIT_UM, '走完会到 %+.0f um，超过软件限位 ±%.0f um。', target_um, SOFT_LIMIT_UM);

fs = min(250e3, 20 * STEP_FREQ);   % 采样率：每个脉冲 20 行；AI 时钟上限 250 kS/s
DIR_SETUP = 100e-6;                % 先设好方向，再开始发脉冲
%% 4. 生成时序矩阵：列 1 = STEP，列 2 = DIR
period = round(fs / STEP_FREQ);              % 每个脉冲周期的行数
high   = max(1, round(period / 2));          % 50% 占空比
lead   = round(DIR_SETUP * fs);
N      = lead + N_PULSES * period + 1;       % 最后一行全部归零

do = false(N, 2);
k  = (0:N_PULSES * period - 1)';
do(lead + 1 : lead + N_PULSES * period, 1) = mod(k, period) < high;
do(1:end-1, 2) = logical(DIRECTION);

actual_freq = fs / period;
dist_um  = N_PULSES * UM_PER_PULSE;
speed_mm = actual_freq * UM_PER_PULSE / 1000;
fprintf('脉冲数 %d，实际频率 %.1f Hz，用时 %.3f s\n', ...
    nnz(diff([false; do(:,1)]) == 1), actual_freq, N / fs);
fprintf('方向 DIR = %d，预计移动 %+.1f um，速度 %.3f mm/s（上限 %g mm/s）\n', ...
    DIRECTION, sign(MOVE_UM) * dist_um, speed_mm, MAX_SPEED_MM_S);
assert(speed_mm <= MAX_SPEED_MM_S, '速度超过滑台上限，请降低 STEP_FREQ。');

% 这张图画的是上面算出来、准备发送的矩阵 do，不是从硬件测到的信号
figure('Name', 'Motor STEP/DIR (planned)', 'Color', 'w');
show = 1:min(N, lead + 5 * period);
stairs((show - 1) / fs * 1e3, double(do(show, 1)) * 0.8 + 0); hold on
stairs((show - 1) / fs * 1e3, double(do(show, 2)) * 0.8 + 1); hold off
yticks([0.4 1.4]); yticklabels(["STEP" "DIR"]); ylim([-0.2 2]);
xlabel('Time (ms)'); title('计划发送的前 5 个脉冲（计算值）'); grid on

%% 5. 输出到硬件
if ~RUN_HARDWARE
    fprintf('\n*** 检查模式：没有向硬件发送任何信号。要让电机动，把 RUN_HARDWARE 改成 true ***\n');
    return
end

% 释放 MATLAB 里之前创建、还占着 Dev1 的 daq 对象（例如命令行里建的 d、上次运行留下的 dq），
% 否则会报 "Hardware is reserved"。注意：LabVIEW 占用的资源这里释放不了，需要关闭 LabVIEW。
clear d dq cnt
daqreset

if COUNT_CHECK
    cnt = daq("ni");
    addinput(cnt, "Dev1", "ctr1", "EdgeCount");   % 计数输入在 PFI3 (P1.3)
    resetcounters(cnt);
    c0 = read(cnt, "OutputFormat", "Matrix");
end

% MATLAB 的 daq 工具箱规定：定时数字输出必须借用同一对象里模拟通道的采样时钟。
% 这里加一个 AI 通道当时钟（只读，不输出任何东西）。
dq = daq("ni");
dq.Rate = fs;
ai = addinput(dq, "Dev1", CLOCK_AI, "Voltage");
ai.TerminalConfig = "Differential";
addoutput(dq, "Dev1", STEP_LINE, "Digital");
addoutput(dq, "Dev1", DIR_LINE,  "Digital");
meas = readwrite(dq, double(do), "OutputFormat", "Matrix");   % meas 只有接了 STEP 回环才有意义
fprintf('完成：已发送 %d 个脉冲，移动 %+.1f um\n', N_PULSES, sign(MOVE_UM) * dist_um);

% readwrite 跑完才更新位置；中途出错时走不到这里，位置不确定，要用手轮回到记号再归零
pos_um = target_um;
save(POS_FILE, 'pos_um');
fprintf('已记录：Y 现在 %+.1f um（命令位置）\n', pos_um);

clear dq    % 用完立即释放 Dev1，LabVIEW 或下一次运行才能使用

if COUNT_CHECK
    c1 = read(cnt, "OutputFormat", "Matrix");
    % 2.4：PFI3 并在 P0.2 上，应 = N_PULSES；2.6 串扰检查时 PFI3 接回 USER 1，应 = 0
    fprintf('ctr1 实测上升沿：%d（PFI3 在 P0.2 上时应为 %d）\n', c1 - c0, N_PULSES);
end
