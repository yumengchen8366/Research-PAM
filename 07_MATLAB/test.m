%% 用 MATLAB 硬件定时数字输出控制 Dev1/port0/line0~7（BNC-2110 弹簧端子 P0.0~P0.7）
%
%  原理：建一个 N x 8 的 0/1 矩阵，每一列控制一条线（一个端口），每一行是一个时间点。
%        采集卡按 fs 的时钟一行一行输出，相邻两行间隔 1/fs 秒，时序由硬件保证，
%        不受 Windows / MATLAB 运行快慢影响。这和 LabVIEW 里 U8 数组输出 DO 是同一种做法。
%
%  位映射（来自 Desktop\System_test_09_25\bscantest.m 的 LabVIEW DO 定义，接线请自行核对）：
%       列 1  line0  X STEP          列 5  line4  Z STEP
%       列 2  line1  X DIR           列 6  line5  Z DIR
%       列 3  line2  Y STEP          列 7  line6  DAQ Trigger（触发 ATS9462 采集）
%       列 4  line3  Y DIR           列 8  line7  Laser Trigger（触发激光）
%
%  !!! 这些线接着电机和激光，RUN_HARDWARE = true 会让电机走步、激光出光 !!!
%  真正输出前：关闭占用 Dev1 的 LabVIEW 程序；确认激光处于安全状态；确认电机可以移动。

RUN_HARDWARE = false;   % false：只生成时序并画图；确认无误后再改成 true

%% 1. 时间轴
fs = 500e3;                 % DO 采样率 500 kS/s（每行 2 us），与 LabVIEW 设置一致
T  = 2e-3;                  % 总时长 2 ms
N  = round(fs * T);
k  = (0:N-1)';              % 样本序号
t  = k / fs;

% 周期脉冲：从 startSample 开始，每 period 个样本出现一次宽 width 个样本的高电平。
% period 可以不是整数（例如 500k/16k = 31.25），脉冲间隔会在 31 和 32 个样本之间交替。
pulse = @(period, width, startSample) ...
    (k >= startSample) & (mod(k - startSample, period) < width);

%% 2. 每个端口的时序（按实验需要修改这里）
do = false(N, 8);
do(:, 8) = pulse(fs / 100e3, 1, 0);   % line7 激光触发：100 kHz，宽 1 个样本 = 2 us
do(:, 7) = do(:, 8);                   % line6 DAQ 触发：与激光同步
do(:, 1) = pulse(fs / 16e3, 2, 0);     % line0 X STEP：16 kHz，宽 4 us
do(:, 2) = true;                       % line1 X DIR：1 = 一个方向（以驱动器定义为准）
% Y、Z 不动：列 3~6 保持 0

do(end, :) = false;                    % 最后一行全部归零，输出结束后各线停在低电平

%% 3. 画图检查
names = ["X STEP" "X DIR" "Y STEP" "Y DIR" "Z STEP" "Z DIR" "DAQ Trig" "Laser Trig"];
figure('Name', 'DO timing', 'Color', 'w');
hold on
for c = 1:8
    stairs(t * 1e6, double(do(:, c)) * 0.8 + (c - 1));
end
hold off
yticks((0:7) + 0.4); yticklabels(names);
xlabel('Time (us)'); ylim([-0.2 8]);
title(sprintf('Dev1/port0/line0:7, %g kS/s, %d samples', fs / 1e3, N));
grid on

fprintf('每个端口的上升沿个数：\n');
for c = 1:8
    fprintf('  %-10s %d\n', names(c), nnz(diff([false; do(:, c)]) == 1));
end

%% 4. 输出到硬件
if RUN_HARDWARE
    dq = daq("ni");
    dq.Rate = fs;
    addoutput(dq, "Dev1", "port0/line0:7", "Digital");   % 8 个通道，顺序对应矩阵 8 列
    write(dq, double(do));     % 按硬件时钟输出整个矩阵，输出完成后返回
    fprintf('输出完成：%d 行，用时 %.3f ms\n', N, N / fs * 1e3);
end
