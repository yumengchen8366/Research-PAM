%% B-scan：X 滑台匀速扫描 + 激光触发 + ATS9462 每个触发采一条 A-line
%
%  原理（全部由 Dev1 同一个硬件时钟产生，严格同步）：
%    P0.0 X STEP   ：加速 → 匀速 → 减速（→ 可选自动返回起点）
%    P0.1 X DIR    ：扫描方向，返回时翻转
%    P0.6 DAQ 触发 ：匀速段内每走 K 个脉冲（= DX_UM）发一次 → ATS9462 TRIG IN 采一条 A-line
%    P0.7 激光触发 ：与 DAQ 触发同一时刻（LASER_ENABLE = false 时不发）
%  因为触发是按"走了多少步"来发的，每条 A-line 的位置都正好间隔 DX_UM，不会出现 6.25 这类非整数关系。
%
%  先用 RUN_HARDWARE = false 检查时序和位置图；
%  再用 RUN_HARDWARE = true、LASER_ENABLE = false 测通 电机 + ATS 采集（采到的是无激光背景）；
%  最后确认激光安全后再 LASER_ENABLE = true。
%  运行前关闭 LabVIEW 和其他占用 Dev1 / ATS9462 的程序；滑台留出 扫描长度 + 2 x 加速距离 的余量。

RUN_HARDWARE    = false;   % false：只生成时序并画图，不碰任何硬件
LASER_ENABLE    = false;   % false：P0.7 不发激光触发
RETURN_TO_START = true;    % 扫描完自动以 RETURN_SPEED 退回起点
SAVE_DATA       = false;   % true：保存到 bscan_data 文件夹
COUNT_CHECK     = true;    % true：用 ctr1 数 P0.6 的上升沿，需先用导线把 USER 1 端子（P0.6）并接到 PFI3 (P1.3)

%% 1. 扫描参数
SCAN_LENGTH_UM    = 2000;  % B-scan 长度
DX_UM             = 5;     % A-line 间距（必须是 UM_PER_PULSE 的整数倍）
TRIG_RATE_HZ      = 800;  % 激光 / 采集触发频率 = 每秒 A-line 数；扫描速度 = DX_UM x TRIG_RATE_HZ
DIR_SCAN          = 1;     % 扫描时 DIR 电平（1 或 0）
RAMP_UM           = 200;   % 加速、减速各用多少距离（这段不采数据）
START_FREQ_HZ     = 500;   % 加速起始步频
RETURN_SPEED_MM_S = 2;     % 返回速度

%% 2. 硬件参数
STEP_LINE     = "port0/line0";
DIR_LINE      = "port0/line1";
DAQTRIG_LINE  = "port0/line6";      % → ATS9462 TRIG IN（请确认接线）
LASER_LINE    = "port0/line7";      % → 激光外触发输入（请确认接线和激光的触发要求）
STEPS_PER_REV = 200 * 20;           % SR2 细分设置（以 test2.m 实测校准过的值为准）
UM_PER_PULSE  = 2000 / STEPS_PER_REV;
MAX_SPEED_MM_S = 4;
MAX_TRAVEL_UM  = 20000;             % 单次扫描总行程上限（滑台行程 50 mm）
TRIG_WIDTH_S   = 10e-6;             % 触发脉宽
CLOCK_AI       = "ai1";             % 给数字输出提供时钟的 AI 通道（只读）
FS_MAX         = 250e3;             % AI 时钟上限
DIR_SETUP_S    = 100e-6;
PAUSE_S        = 0.05;              % 扫描结束到返回之间的停顿

% ATS9462（与 ats9462_aline_test_revised.m 一致）
ATS.samplesPerALine   = 1024;        % 每条 A-line 的点数（32 的倍数，>= 256）
ATS.sampleRate_Hz     = 180e6;
ATS.inputRange_V      = 4;          % 0.2 / 0.4 / 0.8 / 2 / 4
ATS.triggerLevelCode  = 150;        % ETR_5V 下约 0.87 V
ATS.triggerDelay      = 0;          % ADC 采样点，2 的倍数
ATS.recordsPerBuffer  = 50;         % 每个 DMA buffer 的 A-line 数
ATS.sdkInclude        = 'C:\AlazarTech\ATS-SDK\23.3.0\Samples_MATLAB\Include';

%% 3. 换算与检查
K = DX_UM / UM_PER_PULSE;                       % 每条 A-line 之间的脉冲数
assert(abs(K - round(K)) < 1e-9 && K >= 1, 'DX_UM 必须是 %.3f um 的整数倍。', UM_PER_PULSE);
K = round(K);
stepFreq = K * TRIG_RATE_HZ;
scanSpeed = stepFreq * UM_PER_PULSE / 1000;     % mm/s
assert(scanSpeed <= MAX_SPEED_MM_S, '扫描速度 %.2f mm/s 超过上限，请降低 TRIG_RATE_HZ 或 DX_UM。', scanSpeed);
assert(RETURN_SPEED_MM_S <= MAX_SPEED_MM_S, '返回速度超过上限。');

Nx = round(SCAN_LENGTH_UM / DX_UM);
Nx = ceil(Nx / ATS.recordsPerBuffer) * ATS.recordsPerBuffer;   % 凑成 buffer 的整数倍
nRamp = round(RAMP_UM / UM_PER_PULSE);
nScan = Nx * K;
travel = (2 * nRamp + nScan) * UM_PER_PULSE;
assert(travel <= MAX_TRAVEL_UM, '总行程 %.0f um 超过上限 %.0f um。', travel, MAX_TRAVEL_UM);

pScan = floor(FS_MAX / stepFreq);               % 每个脉冲的行数（整数，保证触发间隔精确）
assert(pScan >= 2, '步频太高，DO 时钟不够。');
fs = stepFreq * pScan;
wTrig = max(1, round(TRIG_WIDTH_S * fs));
assert(wTrig < K * pScan, '触发脉宽太长。');

%% 4. 生成时序：列 1 STEP，列 2 DIR，列 3 DAQ 触发，列 4 激光触发
up      = rampPeriods(nRamp, START_FREQ_HZ, stepFreq, fs, pScan);
segScan = [up; repmat(pScan, nScan, 1); flipud(up)];
trigOn  = [false(nRamp, 1); mod((0:nScan-1)', K) == 0; false(nRamp, 1)];
stepScan = stepColumn(segScan);
startsScan = [0; cumsum(segScan(1:end-1))];
trigScan = false(size(stepScan));
idx = startsScan(trigOn) + (1:wTrig);
trigScan(idx(:)) = true;

if RETURN_TO_START
    fRet = RETURN_SPEED_MM_S * 1000 / UM_PER_PULSE;
    pRet = max(2, round(fs / fRet));
    upR  = rampPeriods(nRamp, START_FREQ_HZ, fRet, fs, pRet);
    segRet = [upR; repmat(pRet, nScan, 1); flipud(upR)];   % 与去程步数相同
    stepRet = stepColumn(segRet);
else
    stepRet = false(0, 1);
end

lead  = round(DIR_SETUP_S * fs);
pause_rows = round(PAUSE_S * fs);
nA = numel(stepScan); nR = numel(stepRet);
N  = lead + nA + pause_rows + nR + 1;           % 最后一行全部归零
do = false(N, 4);
rA = lead + (1:nA);
do(rA, 1) = stepScan;
do(rA, 3) = trigScan;
if LASER_ENABLE
    do(rA, 4) = trigScan;
end
dirSwitch = lead + nA + floor(pause_rows / 2);  % 停顿中途翻转 DIR
do(1:dirSwitch, 2) = logical(DIR_SCAN);
if RETURN_TO_START
    rR = lead + nA + pause_rows + (1:nR);
    do(rR, 1) = stepRet;
    do(dirSwitch+1 : N-1, 2) = ~logical(DIR_SCAN);
end

%% 5. 检查：位置和触发位置（由 do 矩阵推算，不是实测）
fall = [false; diff(do(:,1)) == -1];            % SR2 在 STEP 下降沿走一步
sgn  = 2 * (do(:,2) == logical(DIR_SCAN)) - 1;
pos_um = cumsum(fall .* sgn) * UM_PER_PULSE;
tr = find(diff([false; do(:,3)]) == 1);
xA = pos_um(tr);
spacing = diff(xA);
t = (0:N-1)' / fs;

fprintf('A-line 数 %d，间距 %.2f um（实际 %.2f ~ %.2f um），B-scan 长度 %.2f mm\n', ...
    numel(tr), DX_UM, min(spacing), max(spacing), (xA(end) - xA(1)) / 1000);
fprintf('扫描速度 %.2f mm/s，步频 %.0f Hz，触发 %.0f Hz，DO 采样率 %.0f S/s\n', ...
    scanSpeed, stepFreq, TRIG_RATE_HZ, fs);
fprintf('总行程 %.2f mm，总用时 %.2f s，结束位置 %+.1f um，激光触发：%s\n', ...
    travel / 1000, N / fs, pos_um(end), string(LASER_ENABLE));

figure('Name', 'B-scan plan (computed)', 'Color', 'w');
subplot(2,1,1);
plot(t, pos_um / 1000); hold on
plot(t(tr), xA / 1000, 'r.', 'MarkerSize', 4); hold off
xlabel('Time (s)'); ylabel('X (mm)'); grid on
title(sprintf('计划位置（计算值），红点 = %d 个触发位置', numel(tr)));
subplot(2,1,2);
z = tr(1) - 2*K*pScan : tr(3) + K*pScan;
z = z(z >= 1 & z <= N);
labels = ["X STEP" "X DIR" "DAQ Trig" "Laser Trig"];
hold on
for c = 1:4
    stairs(t(z) * 1e3, double(do(z, c)) * 0.8 + (c - 1));
end
hold off
yticks((0:3) + 0.4); yticklabels(labels); ylim([-0.2 4]);
xlabel('Time (ms)'); title('第一个触发附近的时序（计算值）'); grid on

%% 6. 运行硬件
if ~RUN_HARDWARE
    fprintf('\n*** 检查模式：没有向硬件发送任何信号。确认无误后把 RUN_HARDWARE 改成 true ***\n');
    return
end

clear d dq cnt
daqreset

if COUNT_CHECK
    cnt = daq("ni");
    addinput(cnt, "Dev1", "ctr1", "EdgeCount");   % 计数输入在 PFI3 (P1.3)
    resetcounters(cnt);
    c0 = read(cnt, "OutputFormat", "Matrix");
end

doLines = [STEP_LINE DIR_LINE DAQTRIG_LINE LASER_LINE];
raw = runBscan(do, fs, doLines, CLOCK_AI, Nx, ATS);

if COUNT_CHECK
    c1 = read(cnt, "OutputFormat", "Matrix");
    nTrigCount = c1 - c0;
    fprintf('ctr1 实测 P0.6 上升沿：%d（应为 %d）\n', nTrigCount, Nx);
    clear cnt
end

bscan = struct();
bscan.volts = (double(raw) / 65535 * 2 - 1) * ATS.inputRange_V;   % samples x Nx
bscan.x_um  = xA(:)' - xA(1);
bscan.t_us  = (ATS.triggerDelay + (0:ATS.samplesPerALine-1)') / ATS.sampleRate_Hz * 1e6;
bscan.raw_u16 = raw;
bscan.params = struct('SCAN_LENGTH_UM', SCAN_LENGTH_UM, 'DX_UM', DX_UM, ...
    'TRIG_RATE_HZ', TRIG_RATE_HZ, 'LASER_ENABLE', LASER_ENABLE, ...
    'UM_PER_PULSE', UM_PER_PULSE, 'fs', fs, 'ATS', ATS);
bscan.time = datetime('now');
if COUNT_CHECK
    bscan.trigCount = nTrigCount;               % ctr1 数到的 P0.6 上升沿个数
end

sig = bscan.volts - median(bscan.volts, 1);     % 每条 A-line 减去自身中值
env = abs(hilbert(sig));
figure('Name', 'B-scan', 'Color', 'w');
imagesc(bscan.x_um / 1000, bscan.t_us, env);
xlabel('X (mm)'); ylabel('Time after trigger (us)'); colorbar
title(sprintf('B-scan 包络  %d A-lines, 激光 %s', Nx, string(LASER_ENABLE)));
fprintf('完成：采到 %d 条 A-line，rail 点数 %d\n', size(raw, 2), nnz(raw == 0 | raw == 65535));

%% 快速检查：每条脉冲个数、上升沿时间
v  = bscan.volts;
th = 0.5;                          % V，测试脉冲 1 V 的一半
dt = 1 / ATS.sampleRate_Hz;
nEdge = zeros(1, Nx);
tEdge = nan(1, Nx);
for k = 1:Nx
    above = v(:,k) > th;
    nEdge(k) = nnz(diff(above) == 1);
    i = find(diff(above) == 1, 1);  % 第一个上升沿：v(i) <= th < v(i+1)
    if ~isempty(i)
        frac = (th - v(i,k)) / (v(i+1,k) - v(i,k));          % 0~1：阈值落在两个点之间的哪个位置
        tEdge(k) = (ATS.triggerDelay + i - 1 + frac) * dt;    % 秒
    end
end
fprintf('每条正好 1 个沿：%d/%d；异常的列：%s\n', nnz(nEdge == 1), Nx, mat2str(find(nEdge ~= 1)));
fprintf('上升沿 %.4f ~ %.4f us，标准差 %.2f ns，峰峰 %.2f ns\n', ...
    min(tEdge)*1e6, max(tEdge)*1e6, std(tEdge, 'omitnan')*1e9, (max(tEdge)-min(tEdge))*1e9);

fprintf('脉冲高 %.3f ~ %.3f V\n', min(max(v)), max(max(v)));

if SAVE_DATA
    outDir = fullfile(pwd, 'bscan_data');
    if ~isfolder(outDir), mkdir(outDir); end
    f = fullfile(outDir, ['bscan_' char(datetime('now', 'Format', 'yyyyMMdd_HHmmss')) '.mat']);
    save(f, 'bscan');
    fprintf('已保存：%s\n', f);
end

%% ===== 本地函数 =====
function p = rampPeriods(n, f0, f1, fs, pMin)
% 线性加速：步频从 f0 增加到 f1，返回每一步的行数
    if n == 0
        p = zeros(0, 1);
        return
    end
    f = linspace(min(f0, f1), f1, n)';
    p = max(pMin, round(fs ./ f));
end

function col = stepColumn(periods)
% 每一步：前一半行为高，后一半为低
    starts = [0; cumsum(periods(1:end-1))];
    col = false(sum(periods), 1);
    for i = 1:numel(periods)
        col(starts(i) + (1:max(1, floor(periods(i) / 2)))) = true;
    end
end

function raw = runBscan(do, fs, doLines, clockAI, Nx, P)
% 先把 ATS9462 准备好（所有 DMA buffer 预先提交），再让 Dev1 输出整个时序。
    addpath(P.sdkInclude);
    AlazarDefs;
    alazarLoadLibrary();
    board = AlazarGetBoardBySystemID(int32(1), int32(1));
    [~, bits] = AlazarGetChannelInfo(board);
    assert(double(bits) == 16, 'Expected 16-bit ATS9462.');

    rateIds  = containers.Map({100e6, 160e6, 180e6}, ...
        {SAMPLE_RATE_100MSPS, SAMPLE_RATE_160MSPS, SAMPLE_RATE_180MSPS});
    rangeIds = containers.Map({0.2, 0.4, 0.8, 2, 4}, ...
        {INPUT_RANGE_PM_200_MV, INPUT_RANGE_PM_400_MV, INPUT_RANGE_PM_800_MV, ...
         INPUT_RANGE_PM_2_V, INPUT_RANGE_PM_4_V});
    AlazarSetCaptureClock(board, INTERNAL_CLOCK, rateIds(P.sampleRate_Hz), CLOCK_EDGE_RISING, 0);
    AlazarInputControlEx(board, CHANNEL_A, DC_COUPLING, rangeIds(P.inputRange_V), IMPEDANCE_50_OHM);
    AlazarSetBWLimit(board, CHANNEL_A, 0);
    AlazarSetExternalTrigger(board, DC_COUPLING, ETR_5V);
    AlazarSetTriggerOperation(board, TRIG_ENGINE_OP_J, TRIG_ENGINE_J, TRIG_EXTERNAL, ...
        TRIGGER_SLOPE_POSITIVE, P.triggerLevelCode, TRIG_ENGINE_K, TRIG_DISABLE, ...
        TRIGGER_SLOPE_POSITIVE, 128);
    AlazarSetTriggerDelay(board, P.triggerDelay);
    AlazarSetTriggerTimeOut(board, 0);
    AlazarConfigureAuxIO(board, AUX_OUT_TRIGGER, 0);

    spr = P.samplesPerALine;
    rpb = P.recordsPerBuffer;
    nBuf = Nx / rpb;
    bytesPerBuffer = 2 * spr * rpb;
    buffers = cell(1, nBuf);
    for i = 1:nBuf
        buffers{i} = AlazarAllocBuffer(board, bytesPerBuffer);
    end
    guard = onCleanup(@() releaseAll(board, buffers)); %#ok<NASGU>

    AlazarSetRecordSize(board, 0, spr);
    AlazarBeforeAsyncRead(board, CHANNEL_A, 0, spr, rpb, Nx, ...
        bitor(ADMA_EXTERNAL_STARTCAPTURE, ADMA_NPT));
    for i = 1:nBuf
        AlazarPostAsyncBuffer(board, buffers{i}, bytesPerBuffer);
    end
    AlazarStartCapture(board);
    fprintf('ATS armed：等待 %d 个触发...\n', Nx);

    dq = daq("ni");
    dq.Rate = fs;
    ai = addinput(dq, "Dev1", clockAI, "Voltage");
    ai.TerminalConfig = "Differential";
    for k = 1:numel(doLines)
        addoutput(dq, "Dev1", doLines(k), "Digital");
    end
    readwrite(dq, double(do), "OutputFormat", "Matrix");
    clear dq
    fprintf('Dev1 时序输出完成。\n');

    raw = zeros(spr, Nx, 'uint16');
    for i = 1:nBuf
        try
            AlazarWaitAsyncBufferComplete(board, buffers{i}, 2000);   % SDK 包装函数没有返回值，失败时直接抛错
        catch e
            error('Bscan:Buffer', 'Buffer %d/%d 未完成（%s）：收到的触发数在 %d ~ %d 之间，检查 P0.6 是否接到 ATS TRIG IN。', ...
                i, nBuf, e.message, (i-1)*rpb, i*rpb - 1);
        end
        setdatatype(buffers{i}, 'uint16Ptr', 1, spr * rpb);
        raw(:, (i-1)*rpb + (1:rpb)) = reshape(buffers{i}.Value, spr, rpb);
    end
end

function releaseAll(board, buffers)
    try
        AlazarAbortAsyncRead(board);
    catch e
        warning('Bscan:Abort', 'DMA abort failed; buffers NOT freed. Restart MATLAB. %s', e.message);
        return
    end
    for i = 1:numel(buffers)
        try
            AlazarFreeBuffer(board, buffers{i});
        catch
        end
    end
end

