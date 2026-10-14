%% C-scan：逐行扫描。行内 = bscan_test 的匀速扫描；行与行之间 = X 回程 + Y 走一步
%
%  原理（每张表都由 Dev1 同一个硬件时钟输出，6 条线严格同步）：
%    行扫描表（每行都一样）：X 加速 → 匀速（每走 K 个脉冲 = DX_UM，P0.6 发一个触发 → ATS 采一条 A-line）→ 减速
%                            这一段和 bscan_test 完全相同（400/400、ctr1 = 400 已验证，docs/13 §3.1–3.3）
%    回程 + Y 表：停稳 → X 以 X_RETURN_SPEED 退回本行起点（不加速）→ Y 前进 DY_UM（不加速）→ 停稳
%    退回起点表：全部扫完（或中途停止）后，按累计命令位置让 X、Y 都回到开工时的位置
%  单向光栅：每行都朝同一个方向扫（X 是快轴，Y 是慢轴），回程不采数据。
%  每行的步骤（docs/14 4.2）：① arm ATS → ② 行扫描表 → ③ 取数、Abort、读 ctr1 → ④ 存盘 → ⑤ 看停止按钮 → ⑥ 回程 + Y。
%  行与行之间没有 P0.6，所以每行重新 arm 的空档不会漏触发；数据在电机再动之前就存好。
%
%  使用顺序（docs/14）：
%    1. RUN_HARDWARE = false：换算、逐表检查、计划图、时长（阶段 1.1–1.3）；
%       MOCK_DATA = true 时再用假数据走一遍 存放 → MAP → 逐行存盘 → 重读（阶段 1.4）
%    2. 做完 Y 标定（阶段 2）后 Y_CALIBRATED = true，再 RUN_HARDWARE = true：
%       先 ATS_ENABLE = false 只动电机（4.1），再打开 ATS（4.2），最后 10 x 10（阶段 5）
%  以后如果行内改成 step-and-settle（docs/14 附 B），只换 buildRowTable 这一个函数，其余不变。
%  运行前关闭 LabVIEW、Python 和其他占用 Dev1 / ATS9462 的程序；两轴先用手轮摇到行程中间（docs/14 0.4）。

RUN_HARDWARE       = false;  % false：只算时序、检查、画图（和假数据），不碰任何硬件
LASER_ENABLE       = false;  % false：P0.7 一直是 0
ATS_ENABLE         = true;   % false：只动电机 + ctr1 计数，ATS 不 arm（docs/14 4.1）
COUNT_CHECK        = true;   % true：用 ctr1 数 P0.6 的上升沿（USER 1 端子并一根线到 PFI3）
SAVE_DATA          = false;  % true：每行做完就写进 cscan_data 文件夹
MOCK_DATA          = true;   % 只在 RUN_HARDWARE = false 时有用：用假数据走一遍数据通路（docs/14 1.4）
PAUSE_BETWEEN_ROWS = false;  % true：每行开始前、扫完后各停一下，按回车继续（docs/14 4.1、6.2）
Y_CALIBRATED       = false;  % Y 的 um/脉冲 和方向在 docs/14 阶段 2 实测之后才能改成 true

%% 1. 扫描参数（docs/14 附 A：第一版 10 x 10）
NX                  = 10;      % 每行 A-line 数 = X 方向像素数（必须是 recordsPerBuffer 的整数倍）
NY                  = 10;      % 行数 = Y 方向像素数
DX_UM               = 10;      % X 像素间距（必须是 X_UM_PER_PULSE 的整数倍）
DY_UM               = 10;      % Y 像素间距（必须是 Y_UM_PER_PULSE 的整数倍）
SCAN_SPEED_MM_S     = 4;       % 行内匀速段速度；触发频率 = 速度 / DX_UM（第 3 节算）
DIR_SCAN            = 1;       % 扫描时 X DIR 电平（1 = 朝电机，docs/01）；回程时翻转
RAMP_UM             = 200;     % 加速、减速各用多少距离（这段不采数据）
START_FREQ_HZ       = 500;     % 加速起始步频
X_RETURN_SPEED_MM_S = 2;       % X 回程速度（不加速）
Y_SPEED_MM_S        = 1;       % Y 走一步的速度（不加速）
DIR_SETUP_S         = 100e-6;  % DIR 改之前、改之后各留多久不发 STEP（手册 DIR >= 50 us）
SETTLE_S            = 0.05;    % 回程前、Y 走完后各停多久（真实停稳时间待测）

%% 2. 硬件参数
X_STEP_LINE    = "port0/line0";   % P0.0 → SR2(X) STEP−（共阳极）
X_DIR_LINE     = "port0/line1";   % P0.1 → SR2(X) DIR−
Y_STEP_LINE    = "port0/line2";   % P0.2 → SR2(Y) STEP−（10/13 看线确认；还要用电确认，docs/14 2.2）
Y_DIR_LINE     = "port0/line3";   % P0.3 → SR2(Y) DIR−
DAQTRIG_LINE   = "port0/line6";   % P0.6 → USER 1 → 发生器 AUX → G1 → ATS TRIG IN（docs/13 §1）
LASER_LINE     = "port0/line7";   % P0.7 → 激光（这次不接，必须一直是 0）
X_UM_PER_PULSE = 0.5;             % X：4000 步/转、导程 2 mm（10/4 实测）
Y_UM_PER_PULSE = 0.5;             % ⚠ 没标定：暂时沿用 X 的值。Y 行程约 15 cm，可能不是同一型号（docs/14 2.1、2.4）
Y_POSITIVE_DIR = 1;               % Y 前进（行号增加）时 DIR 的电平。待确认（docs/14 2.3）
Y_DRIVER_SN    = "待确认";         % Y 的 SR2 序列号（docs/01：243106105 或 243106317）
MAX_SPEED_MM_S = 4;               % 带加速只验证过 4 mm/s；不加速 5 mm/s 会失步（docs/01）
MAX_START_FREQ_HZ = 8000;         % 不加速直接起步的步频上限：X 实测 9.6 kHz 正常、10 kHz 失步（docs/01）。
                                  % 失步看的是步频不是 mm/s：Y 的 um/脉冲 如果比 X 小，同样的 mm/s 步频更高。⚠ Y 待 docs/14 2.5 实测
SOFT_LIMIT_UM  = 5000;            % 软件限位：X、Y 的累计命令位置都不超过 ±5 mm（限位开关没接）
TRIG_WIDTH_S   = 10e-6;           % P0.6 脉宽
CLOCK_AI       = "ai1";           % 给数字输出提供时钟的 AI 通道（只读）
FS_MAX         = 250e3;           % AI 时钟上限
EDGE_TH_V      = 0.5;             % 快速检查的阈值：测试脉冲 1 V 的一半（同 bscan_test）
NOTE           = "测试信号（函数发生器），激光关";   % 每次测试前改成当前设定，存进文件
OUT_DIR        = fullfile(pwd, 'cscan_data');     % 这个文件夹不进 git（.gitignore）：数据要自己拷到别的电脑

% ATS9462：和 bscan_test 一样，只把 recordsPerBuffer 改成 2；阻抗和 TRIG IN 量程写成命名参数（Rui 10/12 要求）
ATS.samplesPerALine    = 1024;    % 每条 A-line 的点数（32 的倍数，>= 256）
ATS.sampleRate_Hz      = 180e6;
ATS.inputRange_V       = 4;       % CH A 量程：0.2 / 0.4 / 0.8 / 2 / 4
ATS.inputImpedance_ohm = 50;      % CH A 输入阻抗：50 或 1e6（= 1 MΩ），代码里可以设
ATS.bandwidthLimit     = 0;       % 0 = 不开约 20 MHz 的低通
ATS.extTrigRange_V     = 5;       % TRIG IN 量程：5（ETR_5V）或 1（ETR_1V）
                                  % TRIG IN 的阻抗代码里设不了：AlazarSetExternalTrigger 只有耦合和量程两个参数，
                                  % ETR_5V = ETR_5V_50OHM = 0。实测 50 Ω（docs/13 §3.3）
ATS.triggerLevelCode   = 150;     % ETR_5V 下约 0.87 V：(150 − 128) / 127 x 5 V；改成 ETR_1V 时同一个码只有约 0.17 V
ATS.triggerDelay       = 0;       % ADC 采样点，2 的倍数
ATS.recordsPerBuffer   = 2;       % 每个 DMA buffer 的 A-line 数：2 x 1024 x 2 B = 4096 B（docs/14 附 A）
ATS.postedBuffers      = Inf;     % Inf：每行的 buffer 一次全部 Post（bscan_test 验证过的做法）
                                  % 4：环形 buffer，Wait 完一个就拷走、再 Post 回去（docs/14 6.11）
ATS.waitTimeout_ms     = 2000;    % 每个 buffer 最多等多久
ATS.sdkInclude         = 'C:\AlazarTech\ATS-SDK\23.3.0\Samples_MATLAB\Include';

%% 3. 换算与检查（docs/14 1.1）
explain('3. 换算与检查（docs/14 1.1）', ...
    '把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。', ...
    '电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。');

assert(~RUN_HARDWARE || Y_CALIBRATED, ['Y 轴还没标定（Y_CALIBRATED = false）：Y_UM_PER_PULSE 和 Y_POSITIVE_DIR ' ...
    '都是假设值。先做完 docs/14 阶段 2（2.1–2.6），把实测值填进第 2 节，再把 Y_CALIBRATED 改成 true。']);
assert(NX >= 1 && NY >= 1 && NX == round(NX) && NY == round(NY), 'NX、NY 必须是正整数。');

K = DX_UM / X_UM_PER_PULSE;                     % 每个 X 像素的脉冲数
assert(abs(K - round(K)) < 1e-9 && K >= 1, 'DX_UM 必须是 %.3f um 的整数倍。', X_UM_PER_PULSE);
K = round(K);
Ky = DY_UM / Y_UM_PER_PULSE;                    % 每个 Y 像素的脉冲数（⚠ 依赖还没标定的 Y_UM_PER_PULSE）
assert(abs(Ky - round(Ky)) < 1e-9 && Ky >= 1, 'DY_UM 必须是 %.3f um 的整数倍。', Y_UM_PER_PULSE);
Ky = round(Ky);

assert(SCAN_SPEED_MM_S <= MAX_SPEED_MM_S, '扫描速度 %.2f mm/s 超过上限 %g mm/s。', SCAN_SPEED_MM_S, MAX_SPEED_MM_S);
assert(X_RETURN_SPEED_MM_S <= MAX_SPEED_MM_S, 'X 回程速度 %.2f mm/s 超过上限 %g mm/s（回程不加速）。', ...
    X_RETURN_SPEED_MM_S, MAX_SPEED_MM_S);
assert(Y_SPEED_MM_S <= MAX_SPEED_MM_S, 'Y 速度 %.2f mm/s 超过上限 %g mm/s（Y 不加速）。', Y_SPEED_MM_S, MAX_SPEED_MM_S);
stepFreq = SCAN_SPEED_MM_S * 1000 / X_UM_PER_PULSE;   % 匀速段步频（4 mm/s → 8000 Hz）
assert(abs(stepFreq - round(stepFreq)) < 1e-6, '扫描速度换算成步频 %.3f Hz，不是整数 Hz：换一个速度。', stepFreq);
stepFreq = round(stepFreq);                     % 先取整数步频，fs 才是整数（DX = 15 um 这类也不会出小数）
TRIG_RATE_HZ = stepFreq / K;                    % 每秒 A-line 数（10 um → 400 Hz）；触发按步数发，不需要是整数

nRamp = round(RAMP_UM / X_UM_PER_PULSE);        % 加速、减速各多少步
nScan = NX * K;                                 % 匀速段步数
pScan = floor(FS_MAX / stepFreq);               % 匀速段每步的行数（整数，保证触发间隔精确）
assert(pScan >= 2, '步频 %.0f Hz 太高，DO 时钟不够（每步至少 2 行）。', stepFreq);
fs = stepFreq * pScan;                          % 所有表共用这个采样率（8 kHz x 31 = 248 kS/s）
wTrig = max(1, round(TRIG_WIDTH_S * fs));       % P0.6 脉宽（行）
assert(wTrig < K * pScan, '触发脉宽太长。');
assert(DIR_SETUP_S >= 50e-6, 'DIR_SETUP_S 不能小于手册的 50 us。');
lead = ceil(DIR_SETUP_S * fs - 1e-9);           % DIR 前后留的行数（向上取整，不会少于 DIR_SETUP_S）
settleRows = round(SETTLE_S * fs);              % 停稳时间（行）
% 回程和 Y 每步的行数：向上取整，实际速度只会比设的慢、不会快
pRet = ceil(fs / (X_RETURN_SPEED_MM_S * 1000 / X_UM_PER_PULSE) - 1e-9);
pY   = ceil(fs / (Y_SPEED_MM_S * 1000 / Y_UM_PER_PULSE) - 1e-9);
assert(pRet >= 2 && pY >= 2, '回程或 Y 的步频太高：每步至少 2 行。');
assert(fs / pRet <= MAX_START_FREQ_HZ, 'X 回程步频 %.0f Hz 超过不加速起步上限 %.0f Hz。', fs / pRet, MAX_START_FREQ_HZ);
assert(fs / pY <= MAX_START_FREQ_HZ, 'Y 步频 %.0f Hz 超过不加速起步上限 %.0f Hz。', fs / pY, MAX_START_FREQ_HZ);
retSpeed = fs / pRet * X_UM_PER_PULSE / 1000;   % 取整后实际的速度（mm/s）
ySpeed   = fs / pY * Y_UM_PER_PULSE / 1000;

spr = ATS.samplesPerALine;
rpb = ATS.recordsPerBuffer;
assert(spr >= 256 && mod(spr, 32) == 0, 'samplesPerALine 必须 >= 256 且是 32 的倍数。');
assert(mod(ATS.triggerDelay, 2) == 0, 'triggerDelay 必须是 2 的倍数。');
assert(mod(2 * spr * rpb, 4096) == 0, ...
    '每个 DMA buffer %d B 不是 4096 的整数倍（docs/12）：只采 CH A 时每条 %d B，recordsPerBuffer 要取 %d 的倍数。', ...
    2 * spr * rpb, 2 * spr, 4096 / gcd(4096, 2 * spr));
% bscan_test 第 64 行会把 Nx 悄悄凑成 rpb 的整数倍。C-scan 里 NX 就是像素网格，悄悄改了，
% 时序表、x_um 和你以为的参数就对不上了，所以这里直接拦下来，让你自己改 NX 或 rpb。
assert(mod(NX, rpb) == 0, 'NX = %d 必须是 recordsPerBuffer = %d 的整数倍（每行正好装满整数个 buffer）。', NX, rpb);
nBuf = NX / rpb;                                % 每行几个 DMA buffer
assert(TRIG_RATE_HZ / rpb < 2000, '每秒装满 %.0f 个 buffer，超过 SDK 建议的 2000 个/s：加大 recordsPerBuffer。', ...
    TRIG_RATE_HZ / rpb);
assert(isinf(ATS.postedBuffers) || (ATS.postedBuffers == round(ATS.postedBuffers) && ATS.postedBuffers >= 2), ...
    'postedBuffers 只能是 Inf 或 >= 2 的整数（SDK 指南：至少 2 个，最好 >= 3 个）。');
nPost = min(ATS.postedBuffers, nBuf);           % 实际分配、每行一开始 Post 的 buffer 个数
if nPost < 2
    fprintf(2, '注意：每行只有 %d 个 buffer（SDK 建议至少 2 个）。没测过，最好让 NX >= 2 x recordsPerBuffer。\n', nPost);
end
if isinf(ATS.postedBuffers) && nBuf > 64
    fprintf(2, '注意：每行要 Post %d 个 buffer；buffer 太多可能 ApiInsufficientResources，建议 postedBuffers = 4（docs/14 6.11）。\n', nBuf);
end
impNames = containers.Map({50, 1e6}, {'IMPEDANCE_50_OHM', 'IMPEDANCE_1M_OHM'});
etrNames = containers.Map({5, 1}, {'ETR_5V', 'ETR_1V'});
assert(isKey(impNames, ATS.inputImpedance_ohm), 'ATS.inputImpedance_ohm 只能是 50 或 1e6。');
assert(isKey(etrNames, ATS.extTrigRange_V), 'ATS.extTrigRange_V 只能是 5 或 1。');
ATS.inputImpedanceName = impNames(ATS.inputImpedance_ohm);    % 存进文件，以后一眼看出用的是哪个
ATS.extTrigRangeName   = etrNames(ATS.extTrigRange_V);

xTravel_um = (2 * nRamp + nScan) * X_UM_PER_PULSE;   % 每行 X 走多远（含两段加速）
yTravel_um = (NY - 1) * Ky * Y_UM_PER_PULSE;         % Y 从第 1 行到最后一行
assert(xTravel_um <= SOFT_LIMIT_UM && yTravel_um <= SOFT_LIMIT_UM, ...
    '行程超过软件限位 %.0f um：X 每行 %.0f um，Y 共 %.0f um。', SOFT_LIMIT_UM, xTravel_um, yTravel_um);

doLines = [X_STEP_LINE X_DIR_LINE Y_STEP_LINE Y_DIR_LINE DAQTRIG_LINE LASER_LINE];   % 顺序 = 时序表的 6 列
COL = struct('XSTEP', 1, 'XDIR', 2, 'YSTEP', 3, 'YDIR', 4, 'TRIG', 5, 'LASER', 6);

% 把参数打包：本地函数用它，也原样存进数据文件（cscan.params）
P = struct();
P.RUN_HARDWARE = RUN_HARDWARE;  P.MOCK_DATA = MOCK_DATA;
P.NX = NX;  P.NY = NY;  P.DX_UM = DX_UM;  P.DY_UM = DY_UM;
P.SCAN_SPEED_MM_S = SCAN_SPEED_MM_S;  P.TRIG_RATE_HZ = TRIG_RATE_HZ;  P.DIR_SCAN = DIR_SCAN;
P.RAMP_UM = RAMP_UM;  P.START_FREQ_HZ = START_FREQ_HZ;
P.X_RETURN_SPEED_MM_S = X_RETURN_SPEED_MM_S;  P.Y_SPEED_MM_S = Y_SPEED_MM_S;
P.DIR_SETUP_S = DIR_SETUP_S;  P.SETTLE_S = SETTLE_S;
P.X_UM_PER_PULSE = X_UM_PER_PULSE;  P.Y_UM_PER_PULSE = Y_UM_PER_PULSE;
P.Y_POSITIVE_DIR = Y_POSITIVE_DIR;  P.Y_CALIBRATED = Y_CALIBRATED;  P.Y_DRIVER_SN = Y_DRIVER_SN;
P.MAX_SPEED_MM_S = MAX_SPEED_MM_S;  P.MAX_START_FREQ_HZ = MAX_START_FREQ_HZ;  P.SOFT_LIMIT_UM = SOFT_LIMIT_UM;
P.TRIG_WIDTH_S = TRIG_WIDTH_S;  P.FS_MAX = FS_MAX;  P.CLOCK_AI = CLOCK_AI;  P.doLines = doLines;  P.COL = COL;
P.LASER_ENABLE = LASER_ENABLE;  P.ATS_ENABLE = ATS_ENABLE;  P.COUNT_CHECK = COUNT_CHECK;
P.SAVE_DATA = SAVE_DATA;  P.PAUSE_BETWEEN_ROWS = PAUSE_BETWEEN_ROWS;  P.EDGE_TH_V = EDGE_TH_V;
P.K = K;  P.Ky = Ky;  P.stepFreq = stepFreq;  P.fs = fs;  P.pScan = pScan;  P.wTrig = wTrig;
P.lead = lead;  P.settleRows = settleRows;  P.nRamp = nRamp;  P.nScan = nScan;
P.pRet = pRet;  P.pY = pY;  P.retSpeed = retSpeed;  P.ySpeed = ySpeed;  P.nBuf = nBuf;  P.nPost = nPost;
P.ATS = ATS;

%% 4. 生成时序表（docs/14 1.2）：每张表 6 列 = [X_STEP X_DIR Y_STEP Y_DIR DAQ_TRIG LASER]
explain('4. 生成时序表（docs/14 1.2）', ...
    '生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。', ...
    '硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。');
rowTable   = buildRowTable(P);                                   % 每行一样
moveMid    = buildMoveTable(-(2 * nRamp + nScan), Ky, P, true);  % 第 1 … NY−1 行之后：X 回程 + Y 前进一步
moveLast   = buildMoveTable(-(2 * nRamp + nScan), 0,  P, true);  % 最后一行之后（或要停时）：只回程，Y 不动
finalTable = buildMoveTable(0, -(NY - 1) * Ky, P, false);        % 全部结束：Y 退回第 1 行（= 运行时 homeTable 算出的表）

%% 5. 逐表检查、时长、计划图（docs/14 1.2、1.3；全部由表推算，不是实测）
explain('5. 逐表检查和计划图（docs/14 1.2、1.3）', ...
    '从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。', ...
    '矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。');
pos = checkTables(rowTable, moveMid, moveLast, finalTable, P);

dur.row   = size(rowTable, 1) / fs;
dur.mid   = size(moveMid, 1) / fs;
dur.last  = size(moveLast, 1) / fs;
dur.final = size(finalTable, 1) / fs;
dur.total = NY * dur.row + (NY - 1) * dur.mid + dur.last + dur.final;
dataBytes = 2 * spr * NX * NY;

fprintf('K = %d，Ky = %d（Y 未标定时只是假设），fs = %d，NX = %d，NY = %d，wTrig = %d 行（%.2f us），lead = %d 行\n', ...
    K, Ky, fs, NX, NY, wTrig, wTrig / fs * 1e6, lead);
fprintf('触发 %.1f Hz，步频 %d Hz，扫描 %.2f mm/s；X 回程 %.2f mm/s；Y %.2f mm/s\n', ...
    TRIG_RATE_HZ, stepFreq, SCAN_SPEED_MM_S, retSpeed, ySpeed);
fprintf('像素 %d x %d，间距 %.2f x %.2f um；第一个像素在本行起点 + %.0f um；每行 X 走 %.0f um，Y 共 %.0f um\n', ...
    NX, NY, DX_UM, DY_UM, pos.xFirst_um, xTravel_um, yTravel_um);
fprintf('ATS：每条 %d 点，每个 buffer %d 条（%d B），每行 %d 个 buffer，一次 Post %d 个；CH A %s，TRIG IN %s\n', ...
    spr, rpb, 2 * spr * rpb, nBuf, nPost, ATS.inputImpedanceName, ATS.extTrigRangeName);
fprintf('时长：行扫描表 %.3f s（不含停稳），回程 + Y 表 %.3f s（含 2 次停稳；最后一行 %.3f s），Y 退回表 %.3f s\n', ...
    dur.row, dur.mid, dur.last, dur.final);
fprintf('每行 %.3f s，全程 %.2f s（硬件时间下限，不含 readwrite 启动和 ATS arm）\n', dur.row + dur.mid, dur.total);
if NX == 10 && NY == 10 && DX_UM == 10 && DY_UM == 10 && SCAN_SPEED_MM_S == 4 && SETTLE_S == 0.05
    fprintf(['  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），\n' ...
             '  本程序两次停稳都在回程 + Y 表里（%.2f + %.2f s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= %.2f s。\n'], ...
        dur.row, dur.mid, dur.row);
end
fprintf('数据：raw uint16 %d x %d x %d = %d B（%.1f kB）\n', spr, NX, NY, dataBytes, dataBytes / 1024);
plotPlan(P, pos, rowTable);

%% 6. 数据结构（硬件和假数据共用）
cscan = struct();
cscan.raw_u16   = zeros(spr, NX, NY, 'uint16');  % 只存原始编码；电压随时可以算，不存 double（docs/14 附 A）
                                                 % ⚠ 整个 raw 都在内存里：10 x 10 没问题，3 x 3 mm 时要改成只留当前这一行
cscan.x_um      = pos.xPix_um;                   % 命令位置（由时序表算出，不是实测），以第一个像素为 0；+x = 扫描方向（DIR_SCAN）
cscan.y_um      = pos.yPix_um;                   % 同上；+y = Y 前进方向（Y_POSITIVE_DIR）；⚠ Y 没标定时只是假设
cscan.xFirst_um = pos.xFirst_um;                 % 第一个像素离本行起点多远（= 加速段，docs/14 6.2 量位置要用）
cscan.t_us      = (ATS.triggerDelay + (0:spr-1)') / ATS.sampleRate_Hz * 1e6;
cscan.params    = P;
cscan.plannedDur = dur;                          % 由表算的时长（s），和 timing 的实测比较（docs/14 6.10）
cscan.fsActual  = NaN;                           % 上硬件时 dq.Rate 实际的值（NI 可能取整，待确认）
cscan.trigCount = nan(1, NY);                    % 每行 ctr1 数到的 P0.6 上升沿（应为 NX）
cscan.nEdge     = zeros(NY, NX);                 % 每条 A-line 越过阈值的上升沿个数（应为 1）
cscan.tEdge     = nan(NY, NX);                   % 第一个上升沿的时刻（s）
cscan.vMax      = nan(NY, NX);                   % 每条的最大值（V）
cscan.rail      = nan(1, NY);                    % 每行碰到量程边界（0 或 65535）的点数
cscan.timing    = struct('arm', nan(1, NY), 'scan', nan(1, NY), 'collect', nan(1, NY), ...
                         'save', nan(1, NY), 'move', nan(1, NY), 'row', nan(1, NY));   % 秒（docs/14 6.10）
cscan.rowsDone  = 0;
cscan.trigCountTotal = NaN;
cscan.edgeTh_V  = EDGE_TH_V;
cscan.stopReason   = "";
cscan.errorMessage = "";
cscan.failedRow    = 0;
cscan.failedPhase  = "";
cscan.time      = datetime('now');
cscan.note      = NOTE;
cscan.mock      = false;

%% 7. 检查模式到此为止；MOCK_DATA = true 时先用假数据走一遍数据通路（docs/14 1.4）
if ~RUN_HARDWARE
    if MOCK_DATA && NX >= 100
        fprintf('NX = %d >= 100：假数据用 ix/100 编码列号，放不下，跳过假数据。\n', NX);
    elseif MOCK_DATA
        explain('7. 假数据走一遍数据通路（docs/14 1.4）', ...
            '造一组已知图案的 raw（第 iy 行第 ix 条的脉冲高 = iy + ix/100 个单位），走一遍 快速检查 → 逐行存盘 → MAP → 重读。', ...
            '测试信号下 MAP 本来就是均匀的，行列排错了看不出来；用已知图案才能逐点核对。');
        [rawMock, vPerUnit] = makeMockRaw(ATS, NX, NY);
        cscan.note = "假数据（MOCK_DATA，检查模式），不是测量";
        cscan.mock = true;
        cscan.mockVPerUnit = vPerUnit;
        cscan.edgeTh_V = 0.5 * vPerUnit;     % 1 个单位 = vPerUnit 伏，阈值取半个单位（硬件上是 1 V 测试脉冲的一半）
        f = '';
        if SAVE_DATA
            f = newDataFile(cscan, OUT_DIR, 'cscan_mock_');
        end
        fprintf('假数据没有 ctr1 和计时，下面每行的 ctr1、用时显示 NaN。\n');
        for iy = 1:NY
            cscan = storeRow(cscan, iy, rawMock(:, :, iy));     % 和硬件走同一个函数
            if SAVE_DATA
                saveRow(f, cscan, iy);
            end
            printRow(cscan, iy);                                % 和硬件同一句打印
        end
        assert(isequal(cscan.raw_u16, rawMock), 'storeRow 把数据放错了位置。');
        [cscan, MAP] = reportResult(cscan, f);

        expected = (1:NY)' + (1:NX) / 100;   % 第 iy 行第 ix 列应该是 iy + ix/100
        decoded  = MAP / vPerUnit;
        iyS = min(3, NY);  ixS = min(7, NX);
        fprintf('MAP(%d,%d) = %.2f（应为 %.2f）；MAP(%d,%d) = %.2f（应为 %.2f）\n', ...
            iyS, ixS, decoded(iyS, ixS), expected(iyS, ixS), NY, 1, decoded(NY, 1), expected(NY, 1));
        nGood = nnz(abs(decoded - expected) < 0.005);
        fprintf('逐点核对：%d/%d 个像素对得上（误差 < 0.005 个单位）\n', nGood, NX * NY);
        assert(nGood == NX * NY, '假数据的 MAP 对不上：检查 raw 的维度顺序和 computeMAP。');
    end
    fprintf('\n*** 检查模式：没有向硬件发送任何信号。确认无误后把 RUN_HARDWARE 改成 true ***\n');
    return
end

%% 8. 运行硬件（docs/14 阶段 3–6）
assert(RUN_HARDWARE && Y_CALIBRATED, 'Cscan:NotArmed', '检查模式或 Y 未标定：不碰硬件。');   % 单独运行这一节时也拦住
explain('8. 上硬件（docs/14 阶段 3–6）', ...
    '循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。', ...
    'DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。');
clear d dq cnt     % 释放命令行里留下的 daq 对象，否则会报 "Hardware is reserved"（LabVIEW 占用的要关掉 LabVIEW）
daqreset           % 整个 C-scan 只做一次
f = '';
if SAVE_DATA
    f = newDataFile(cscan, OUT_DIR, 'cscan_');
end
plan = struct('rowTable', rowTable, 'moveMid', moveMid, 'moveLast', moveLast);
plan.pos = pos;
cscan = runCscan(plan, P, ATS, cscan, f);

%% 9. 结果：快速检查汇总、MAP、重读（docs/14 6.1、6.3、6.4）
if ATS_ENABLE && cscan.rowsDone > 0
    explain('9. 结果（docs/14 6.1、6.3、6.4）', ...
        '汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。', ...
        '条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。');
    [cscan, MAP] = reportResult(cscan, f);
end

%% ===== 本地函数 =====
function explain(titleText, what, why)
% 每一节开头打印两句话：在做什么、为什么（docs/14 的写法）
    fprintf('\n== %s ==\n【在做什么】%s\n【为什么】%s\n', titleText, what, why);
end

function p = rampPeriods(n, f0, f1, fs, pMin)
% 线性加速：步频从 f0 增加到 f1，返回每一步的行数（同 bscan_test）
    if n == 0
        p = zeros(0, 1);
        return
    end
    f = linspace(min(f0, f1), f1, n)';
    p = max(pMin, round(fs ./ f));
end

function col = stepColumn(periods)
% 每一步：前一半行为高，后一半为低（同 bscan_test）
    starts = [0; cumsum(periods(1:end-1))];
    col = false(sum(periods), 1);
    for i = 1:numel(periods)
        col(starts(i) + (1:max(1, floor(periods(i) / 2)))) = true;
    end
end

function T = buildRowTable(P)
% 行扫描表：和 bscan_test 第 4 节一样（加速 → 匀速 + 每 K 步一个触发 → 减速），只是没有返回段，列数变成 6。
% 以后改成 step-and-settle（docs/14 附 B）只换这个函数：输出仍然是"开头 lead 行、NX 个触发、最后一行全 0"。
    C = P.COL;
    up     = rampPeriods(P.nRamp, P.START_FREQ_HZ, P.stepFreq, P.fs, P.pScan);
    seg    = [up; repmat(P.pScan, P.nScan, 1); flipud(up)];         % 每一步占几行
    trigOn = [false(P.nRamp, 1); mod((0:P.nScan-1)', P.K) == 0; false(P.nRamp, 1)];
    stepX  = stepColumn(seg);
    starts = [0; cumsum(seg(1:end-1))];                             % 每一步从第几行开始（0 起）
    trig   = false(size(stepX));
    idx    = starts(trigOn) + (1:P.wTrig);                          % 触发和这一步的 STEP 同时开始
    trig(idx(:)) = true;

    N = P.lead + numel(stepX) + 1;                                  % 开头 lead 行等 DIR，最后一行全部归零
    T = false(N, 6);
    r = P.lead + (1:numel(stepX));
    T(r, C.XSTEP) = stepX;
    T(r, C.TRIG)  = trig;
    if P.LASER_ENABLE
        T(r, C.LASER) = trig;                                       % 激光和采集同一时刻
    end
    T(1:N-1, C.XDIR) = logical(P.DIR_SCAN);
end

function T = buildMoveTable(dxPulses, dyPulses, P, withSettle)
% 行与行之间的移动表：[停稳] → X 走 dxPulses 步 → Y 走 dyPulses 步 → [停稳] → 最后一行全 0
%   dxPulses > 0 = 扫描方向（DIR_SCAN），< 0 = 回程；dyPulses > 0 = Y 前进（Y_POSITIVE_DIR）
%   都不加速（所以步频要 <= MAX_START_FREQ_HZ）；每一段前后各给 lead 行，只设 DIR、不发 STEP
    C = P.COL;
    if dxPulses >= 0, xDir = logical(P.DIR_SCAN);       else, xDir = ~logical(P.DIR_SCAN);       end
    if dyPulses >= 0, yDir = logical(P.Y_POSITIVE_DIR); else, yDir = ~logical(P.Y_POSITIVE_DIR); end
    nSettle = 0;
    if withSettle
        nSettle = P.settleRows;
    end
    segX = axisSegment(abs(dxPulses), xDir, P.pRet, P.lead, C.XSTEP, C.XDIR);
    segY = axisSegment(abs(dyPulses), yDir, P.pY,   P.lead, C.YSTEP, C.YDIR);
    T = [false(nSettle, 6); segX; segY; false(nSettle, 6); false(1, 6)];
end

function seg = axisSegment(n, dirLevel, period, lead, stepCol, dirCol)
% 一个轴匀速走 n 步：前 lead 行只设 DIR（建立），中间每步 period 行（前一半 STEP 为高），后 lead 行 DIR 不变（保持）
    if n == 0
        seg = false(0, 6);
        return
    end
    stepCol1 = stepColumn(repmat(period, n, 1));
    seg = false(lead + numel(stepCol1) + lead, 6);
    seg(:, dirCol) = dirLevel;
    seg(lead + (1:numel(stepCol1)), stepCol) = stepCol1;
end

function s = tablePos(T, P)
% 从一张表反推：每一行时 X、Y 已经走了多少步（脉冲；正 = 扫描方向 / Y 前进方向），以及 P0.6 上升沿在哪几行
    C = P.COL;
    T0 = [false(1, size(T, 2)); T];                     % 前面补一行 0：上一张表的最后一行全是 0
    % 数 P0 的下降沿（同 bscan_test 第 116 行）。手册说的是光耦电流的下降沿 = 共阳极下 P0 的上升沿（docs/01）。
    % 两种数法步数一样；只是触发那一刻的位置差 1 步（0.5 um），x_um 以第一个像素为 0，不受影响（待确认）。
    fallX = diff(T0(:, C.XSTEP)) == -1;
    fallY = diff(T0(:, C.YSTEP)) == -1;
    sgnX = 2 * (T(:, C.XDIR) == logical(P.DIR_SCAN)) - 1;
    sgnY = 2 * (T(:, C.YDIR) == logical(P.Y_POSITIVE_DIR)) - 1;
    s.x = cumsum(fallX .* sgnX);
    s.y = cumsum(fallY .* sgnY);
    s.trig = find(diff(T0(:, C.TRIG)) == 1);
    s.dx = s.x(end);
    s.dy = s.y(end);
    s.xRange = [min([0; s.x]) max([0; s.x])];           % 这张表里 X 相对起点最远到哪
    s.yRange = [min([0; s.y]) max([0; s.y])];
end

function ok = dirSetupOK(T, stepCol, dirCol, lead)
% DIR 每次变化的前后各 lead 行内，这个轴的 STEP 不能有任何边沿（前 = 保持，后 = 建立）。
% 上升、下降沿都算：共阳极接法下 P0.x 的电平是反的，SR2 到底在哪个边沿走步要看光耦（docs/01），两个都避开最保险。
    T0 = [false(1, size(T, 2)); T];
    dirChange  = find(diff(T0(:, dirCol)) ~= 0);        % 第几行 DIR 变成新值
    stepChange = find(diff(T0(:, stepCol)) ~= 0);       % 第几行 STEP 变成新值
    ok = true;
    for r = dirChange'
        nxt = stepChange(find(stepChange >= r, 1));          % DIR 变了之后的第一个 STEP 边沿
        prv = stepChange(find(stepChange < r, 1, 'last'));   % DIR 变之前的最后一个 STEP 边沿
        if (~isempty(nxt) && nxt - r < lead) || (~isempty(prv) && r - prv < lead)
            ok = false;
        end
    end
end

function checkSoftLimit(xNow, yNow, s, P)
% 软件限位（限位开关没接）：一张表开跑之前，用当前命令位置 + 这张表的范围算一遍会走到哪
    xr = (xNow + s.xRange) * P.X_UM_PER_PULSE;
    yr = (yNow + s.yRange) * P.Y_UM_PER_PULSE;
    assert(all(abs(xr) <= P.SOFT_LIMIT_UM) && all(abs(yr) <= P.SOFT_LIMIT_UM), 'Cscan:SoftLimit', ...
        '软件限位：这张表会把 X 带到 %.0f ~ %.0f um、Y 带到 %.0f ~ %.0f um，超过 ±%.0f um。', ...
        xr(1), xr(2), yr(1), yr(2), P.SOFT_LIMIT_UM);
end

function s = checkOneTable(T, name, nTrig, P)
% 每张表都要满足的规则（docs/14 1.2）。第 4 节的表和运行时现算的退回表都用它查。返回 tablePos 的结果。
    C = P.COL;
    s = tablePos(T, P);
    assert(size(T, 1) >= 2 || ~any(T(:)), '%s：readwrite 至少要 2 行（只有 1 行的表必须全 0，运行时不发）。', name);
    assert(~any(T(end, :)), '%s：最后一行必须全是 0。', name);
    assert(dirSetupOK(T, C.XSTEP, C.XDIR, P.lead), '%s：X DIR 变化前后不到 %d 行就有 STEP 边沿。', name, P.lead);
    assert(dirSetupOK(T, C.YSTEP, C.YDIR, P.lead), '%s：Y DIR 变化前后不到 %d 行就有 STEP 边沿。', name, P.lead);
    assert(numel(s.trig) == nTrig, '%s：有 %d 个 P0.6 上升沿，应为 %d。', name, numel(s.trig), nTrig);
    if ~P.LASER_ENABLE || nTrig == 0
        assert(~any(T(:, C.LASER)), '%s：P0.7 那一列不全是 0（激光关，或者这张表不该有触发）。', name);
    end
end

function pos = checkTables(rowTable, moveMid, moveLast, finalTable, P)
% 逐表检查（docs/14 1.2）。硬件执行的就是这些表，所以位置、触发都从表里反推，不用公式推。
    C = P.COL;
    % (1) 每张表都要满足的；行扫描表 NX 个触发，其他表 0 个
    pos.row      = checkOneTable(rowTable,   "行扫描表",         P.NX, P);
    pos.moveMid  = checkOneTable(moveMid,    "回程 + Y 表",      0,    P);
    pos.moveLast = checkOneTable(moveLast,   "最后一行的回程表", 0,    P);
    pos.final    = checkOneTable(finalTable, "Y 退回表",         0,    P);

    % (2) 行扫描表：触发间隔正好 K 步，第一个在加速段之后
    r = pos.row;
    xT = r.x(r.trig);
    assert(all(diff(xT) == P.K), '相邻触发之间不是正好 %d 个 X 脉冲。', P.K);
    assert(xT(1) == P.nRamp, '第一个触发不在加速段结束处（第 %d 步）。', P.nRamp);
    assert(r.dx == 2 * P.nRamp + P.nScan && r.dy == 0, '行扫描表：X 应走 %d 步、Y 不动。', 2 * P.nRamp + P.nScan);
    if P.LASER_ENABLE
        assert(isequal(rowTable(:, C.LASER), rowTable(:, C.TRIG)), '激光触发和采集触发不同步。');
    end

    % (3) 回程 / Y 表：X 回程步数 = 去程步数；Y 每行前进 Ky 步
    assert(pos.moveMid.dx == -r.dx && pos.moveLast.dx == -r.dx, '回程步数和去程不相等：每行结束时 X 不在起点。');
    assert(pos.moveMid.dy == P.Ky && pos.moveLast.dy == 0, 'Y 每行应前进 %d 步，最后一行不动。', P.Ky);
    assert(pos.final.dx == 0 && pos.final.dy == -(P.NY - 1) * P.Ky, 'Y 退回表应退回 %d 步。', (P.NY - 1) * P.Ky);

    % (4) 按执行顺序走一遍整个计划：软件限位、总触发数、全程结束后 X、Y 都回到 0
    x0 = 0; y0 = 0; nTrig = 0;
    for iy = 1:P.NY
        checkSoftLimit(x0, y0, pos.row, P);
        x0 = x0 + pos.row.dx;  y0 = y0 + pos.row.dy;  nTrig = nTrig + numel(pos.row.trig);
        if iy < P.NY, s = pos.moveMid; else, s = pos.moveLast; end
        checkSoftLimit(x0, y0, s, P);
        x0 = x0 + s.dx;  y0 = y0 + s.dy;
        assert(x0 == 0, '第 %d 行结束后 X 净位移不是 0。', iy);
    end
    checkSoftLimit(x0, y0, pos.final, P);
    x0 = x0 + pos.final.dx;  y0 = y0 + pos.final.dy;
    assert(x0 == 0 && y0 == 0, '全程结束后没有回到起点：X %d 步，Y %d 步。', x0, y0);
    assert(nTrig == P.NX * P.NY, '总触发数 %d，应为 %d。', nTrig, P.NX * P.NY);

    % (5) 像素的命令位置（以第一个像素为 0）
    pos.xFirst_um = xT(1) * P.X_UM_PER_PULSE;                     % 第一个像素离本行起点多远（= 加速段）
    pos.xPix_um   = (xT(:)' - xT(1)) * P.X_UM_PER_PULSE;
    pos.yPix_um   = (0:P.NY-1) * pos.moveMid.dy * P.Y_UM_PER_PULSE;
    fprintf('逐表检查通过：每行 %d 个触发、间隔 %d 步；X 去程 = 回程 = %d 步；Y 前进 %d x %d 步后退回；总触发 %d；P0.7 全 0：%s\n', ...
        P.NX, P.K, r.dx, P.NY - 1, P.Ky, nTrig, string(~P.LASER_ENABLE));
end

function [T, s] = homeTable(xNow, yNow, P)
% 按累计命令位置算一张"退回起点"表（X、Y 都回到开工时的 0），先逐表检查、再查软件限位。
% 已经在起点就返回空表：没有要走的步就不发（readwrite 不接受只有 1 行的表，NY = 1 时就会碰到）。
% 正常扫完时（X = 0，Y = (NY−1)·Ky）算出来的就是第 4 节的 finalTable。
    T = [];  s = [];
    if xNow == 0 && yNow == 0
        return
    end
    T = buildMoveTable(-xNow, -yNow, P, false);
    s = checkOneTable(T, "退回起点表", 0, P);
    checkSoftLimit(xNow, yNow, s, P);
end

function plotPlan(P, pos, rowTable)
% 计划图（由时序表推算，不是实测）：左上 = 整个光栅的路径，右上 = 像素网格，下 = 第一个触发附近的 6 条线
    ux = P.X_UM_PER_PULSE;  uy = P.Y_UM_PER_PULSE;
    figure('Name', 'C-scan plan (computed)', 'Color', 'w');
    subplot(2, 2, 1); hold on
    x0 = 0; y0 = 0;
    for iy = 1:P.NY
        plotPath(pos.row, x0, y0, ux, uy, '-', [0 0.45 0.74], 2);
        plot((x0 + pos.row.x(pos.row.trig)) * ux, (y0 + pos.row.y(pos.row.trig)) * uy, 'r.', 'MarkerSize', 8);
        x0 = x0 + pos.row.dx;  y0 = y0 + pos.row.dy;
        if iy < P.NY, s = pos.moveMid; else, s = pos.moveLast; end
        plotPath(s, x0, y0, ux, uy, '--', [0.5 0.5 0.5], 0.5);
        x0 = x0 + s.dx;  y0 = y0 + s.dy;
    end
    plotPath(pos.final, x0, y0, ux, uy, '--', [0.5 0.5 0.5], 0.5);
    hold off; grid on
    xlabel('X (um)'); ylabel('Y (um)');
    title({'计划路径（计算值）', sprintf('蓝 = 扫描，灰虚线 = 回程 / Y，红点 = %d 个触发', P.NX * P.NY)});

    subplot(2, 2, 2);
    [xg, yg] = meshgrid(pos.xPix_um, pos.yPix_um);
    plot(xg(:), yg(:), 'r.', 'MarkerSize', 12);
    axis equal; grid on
    xlim([min(pos.xPix_um) - P.DX_UM, max(pos.xPix_um) + P.DX_UM]);
    ylim([min(pos.yPix_um) - P.DY_UM, max(pos.yPix_um) + P.DY_UM]);
    xlabel('X (um，以第一个像素为 0)'); ylabel('Y (um)');
    title({'像素网格', sprintf('%d（宽）x %d（高）', P.NX, P.NY)});

    subplot(2, 1, 2);
    tr = pos.row.trig;
    z = tr(1) - 2 * P.K * P.pScan : tr(min(3, numel(tr))) + P.K * P.pScan;   % bscan_test 第 138 行用 tr(3)，NX < 3 会出错
    z = z(z >= 1 & z <= size(rowTable, 1));
    t = (z - 1) / P.fs * 1e3;
    labels = ["X STEP" "X DIR" "Y STEP" "Y DIR" "DAQ Trig" "Laser Trig"];
    hold on
    for c = 1:6
        stairs(t, double(rowTable(z, c)) * 0.8 + (c - 1));
    end
    hold off
    yticks((0:5) + 0.4); yticklabels(labels); ylim([-0.2 6]);
    xlabel('Time (ms)'); title('行扫描表：第一个触发附近的时序（计算值）'); grid on
end

function plotPath(s, x0, y0, ux, uy, style, color, width)
% 只画位置变化的那些行，避免把几十万行都画出来
    k = [1; find(diff(s.x) ~= 0 | diff(s.y) ~= 0) + 1; numel(s.x)];
    plot((x0 + s.x(k)) * ux, (y0 + s.y(k)) * uy, style, 'Color', color, 'LineWidth', width);
end

function v = toVolts(raw, inputRange_V)
% uint16 编码 → 电压（同 bscan_test 第 176 行）
    v = (double(raw) / 65535 * 2 - 1) * inputRange_V;
end

function qc = quickCheckRow(rawRow, ATS, th)
% 一行的快速检查（同 bscan_test 第 196–215 行）：每条越过阈值的上升沿个数、第一个上升沿的时刻（线性插值）
    v  = toVolts(rawRow, ATS.inputRange_V);
    dt = 1 / ATS.sampleRate_Hz;
    nx = size(v, 2);
    qc.nEdge = zeros(1, nx);
    qc.tEdge = nan(1, nx);
    for k = 1:nx
        above = v(:, k) > th;
        up = find(diff(above) == 1);
        qc.nEdge(k) = numel(up);
        if ~isempty(up)
            i = up(1);                                           % v(i) <= th < v(i+1)
            frac = (th - v(i, k)) / (v(i+1, k) - v(i, k));       % 0~1：阈值落在两个点之间的哪个位置
            qc.tEdge(k) = (ATS.triggerDelay + i - 1 + frac) * dt;
        end
    end
    qc.vMax = max(v, [], 1);
    qc.rail = nnz(rawRow == 0 | rawRow == 65535);
end

function cscan = storeRow(cscan, iy, rawRow)
% 把一行数据放进 cscan，并做快速检查（硬件和假数据走同一个函数；阈值和 ATS 参数都从 cscan 里取）
    cscan.raw_u16(:, :, iy) = rawRow;
    qc = quickCheckRow(rawRow, cscan.params.ATS, cscan.edgeTh_V);
    cscan.nEdge(iy, :) = qc.nEdge;
    cscan.tEdge(iy, :) = qc.tEdge;
    cscan.vMax(iy, :)  = qc.vMax;
    cscan.rail(iy)     = qc.rail;
    cscan.rowsDone     = iy;
end

function printRow(cscan, iy)
% 每行一句（docs/14 4.2、6.10）：条数、每条 1 个沿、上升沿中位数（看行与行之间有没有跳）、ctr1、各段用时
    P = cscan.params;
    tm = cscan.timing;
    if P.ATS_ENABLE
        dataText = sprintf('A-line %d/%d，1 个沿 %d/%d，上升沿中位数 %.4f us，脉冲高 %.3f ~ %.3f V', ...
            P.NX, P.NX, nnz(cscan.nEdge(iy, :) == 1), P.NX, median(cscan.tEdge(iy, :), 'omitnan') * 1e6, ...
            min(cscan.vMax(iy, :)), max(cscan.vMax(iy, :)));
    else
        dataText = 'ATS 关（只动电机）';
    end
    fprintf('第 %d/%d 行：%s；ctr1 = %g（应为 %d）；用时 %.2f s（arm %.3f / 扫描 %.3f / 取数 %.3f / 存 %.3f / 回程+Y %.3f）\n', ...
        iy, P.NY, dataText, cscan.trigCount(iy), P.NX, tm.row(iy), tm.arm(iy), tm.scan(iy), tm.collect(iy), ...
        tm.save(iy), tm.move(iy));
end

function MAP = computeMAP(raw, inputRange_V)
% MAP(iy, ix) = 第 iy 行第 ix 条 A-line 的 max(v − median(v))。
% 一行一行算，不把整个 raw 变成 double（3 x 3 mm 时 double 要 73.7 GB，docs/14 附 A）
    [~, nx, ny] = size(raw);
    MAP = zeros(ny, nx);                                 % 行 = Y，列 = X：imagesc(x_um, y_um, MAP) 直接对上
    for iy = 1:ny
        v = toVolts(raw(:, :, iy), inputRange_V);
        MAP(iy, :) = max(v - median(v, 1), [], 1);
    end
end

function [raw, vPerUnit] = makeMockRaw(ATS, NX, NY)
% 假数据（docs/14 1.4）：第 iy 行第 ix 条 A-line 里有一个脉冲，高 = (iy + ix/100) 个单位。
% 1 个单位 = vPerUnit 伏，让最高的脉冲也在量程以内。脉冲在约 1.93 us、宽 200 ns，和测试信号一样。
    assert(NX < 100, '假数据用 ix/100 编码列号，NX 要小于 100。');
    spr = ATS.samplesPerALine;
    fsA = ATS.sampleRate_Hz;
    t = (ATS.triggerDelay + (0:spr-1)') / fsA;
    vPerUnit = min(0.3, 0.9 * ATS.inputRange_V / (NY + 1));
    rng(1);                                              % 每次结果一样
    raw = zeros(spr, NX, NY, 'uint16');
    for iy = 1:NY
        for ix = 1:NX
            h  = (iy + ix / 100) * vPerUnit;
            t0 = 1.93e-6 + rand / fsA;                   % 触发和采样时钟不同步：每条随机错开不到一个采样点
            v  = h * max(0, min(1, (t - t0) / 15e-9)) .* (t < t0 + 200e-9);   % 上升约 15 ns、宽 200 ns
            raw(:, ix, iy) = uint16(round((v / ATS.inputRange_V + 1) * 65535 / 2));
        end
    end
end

function f = newDataFile(cscan, outDir, prefix)
% 建数据文件（-v7.3 才能按行写入）：先写参数等小变量，raw_u16 只占位，之后每行用 saveRow 写进去。
% 文件里每个字段是一个单独的变量（matfile 只能对顶层变量做部分写入）；load 回来就是一个 struct，和 cscan 一样。
    if ~isfolder(outDir), mkdir(outDir); end
    f = fullfile(outDir, [prefix char(datetime('now', 'Format', 'yyyyMMdd_HHmmss')) '.mat']);
    assert(~isfile(f), '文件已存在，不覆盖：%s', f);
    head = rmfield(cscan, 'raw_u16');
    save(f, '-struct', 'head', '-v7.3');
    m = matfile(f, 'Writable', true);
    [a, b, c] = size(cscan.raw_u16);
    m.raw_u16(a, b, c) = uint16(0);      % 只写最后一个点：文件里就有了 a x b x c 的 raw_u16，其余是 0，几乎不占时间
    fprintf('数据文件：%s\n', f);
end

function saveRow(f, cscan, iy)
% 每行做完就写盘（Rui：一边采一边存）：只写这一行的 raw 和几个小变量
    m = matfile(f, 'Writable', true);
    if size(cscan.raw_u16, 3) > 1
        m.raw_u16(:, :, iy) = cscan.raw_u16(:, :, iy);
    else
        m.raw_u16(:, :) = cscan.raw_u16(:, :, 1);       % NY = 1 时文件里的 raw_u16 是二维的
    end
    m.rowsDone  = cscan.rowsDone;
    m.trigCount = cscan.trigCount;
    m.nEdge     = cscan.nEdge;
    m.tEdge     = cscan.tEdge;
    m.vMax      = cscan.vMax;
    m.rail      = cscan.rail;
    m.timing    = cscan.timing;          % 这一行的回程计时这时还没有，结束（或出错）时再补写一次
end

function [cscan, MAP] = reportResult(cscan, f)
% 汇总快速检查、算 MAP；存过盘的话重读一遍逐点比较（docs/14 6.1、6.3、6.4）
% ⚠ load(f) 会把整个文件读进内存：10 x 10 没问题，大扫描时要改成按行读
    n  = cscan.rowsDone;
    NX = size(cscan.raw_u16, 2);
    ATS = cscan.params.ATS;
    MAP = computeMAP(cscan.raw_u16(:, :, 1:n), ATS.inputRange_V);
    cscan.MAP = MAP;
    tE = cscan.tEdge(1:n, :);
    fprintf('完成 %d/%d 行，A-line %d 条；每条正好 1 个沿：%d/%d；rail 点数 %d\n', ...
        n, cscan.params.NY, n * NX, nnz(cscan.nEdge(1:n, :) == 1), n * NX, sum(cscan.rail(1:n)));
    fprintf('上升沿 %.4f ~ %.4f us，标准差 %.2f ns，峰峰 %.2f ns；MAP %.4f ~ %.4f V（标准差 %.2f mV）\n', ...
        min(tE(:)) * 1e6, max(tE(:)) * 1e6, std(tE(:), 'omitnan') * 1e9, (max(tE(:)) - min(tE(:))) * 1e9, ...
        min(MAP(:)), max(MAP(:)), std(MAP(:)) * 1e3);
    if ~isempty(f)
        m = matfile(f, 'Writable', true);
        m.MAP = MAP;
        S = load(f);
        okRaw = isequal(S.raw_u16(:, :, 1:n), cscan.raw_u16(:, :, 1:n));
        okMap = isequal(computeMAP(S.raw_u16(:, :, 1:n), ATS.inputRange_V), MAP);
        fprintf('重读 %s：isequal(raw) = %d，isequal(MAP) = %d\n', f, okRaw, okMap);
        assert(okRaw && okMap, '重读的数据和内存里的不一样。');
    end
    plotResult(cscan, MAP);
end

function plotResult(cscan, MAP)
% MAP 和上升沿时间图：行 = Y，列 = X；axis xy 让 Y 朝上增加，和计划图一致。只有一行时画曲线（imagesc 只会画一条细带）
    n = cscan.rowsDone;
    tE_us = cscan.tEdge(1:n, :) * 1e6;
    figure('Name', 'C-scan MAP', 'Color', 'w');
    subplot(1, 2, 1);
    if n == 1
        plot(cscan.x_um, MAP, '.-'); grid on; ylabel('MAP (V)');
    else
        imagesc(cscan.x_um, cscan.y_um(1:n), MAP); axis image; axis xy; colorbar; ylabel('Y (um)');
    end
    xlabel('X (um)');
    title({'MAP（V）', sprintf('max(v - median(v))，%d x %d', size(MAP, 2), n)});
    subplot(1, 2, 2);
    if n == 1
        plot(cscan.x_um, tE_us, '.-'); grid on; ylabel('上升沿 (us)');
    else
        imagesc(cscan.x_um, cscan.y_um(1:n), tE_us); axis image; axis xy; colorbar; ylabel('Y (um)');
    end
    xlabel('X (um)'); title('上升沿时间（us）');
end

function n = ctrRead(cnt)
% 读 ctr1 的累计值；COUNT_CHECK = false 时返回 NaN
    if isempty(cnt)
        n = NaN;
    else
        n = double(read(cnt, "OutputFormat", "Matrix"));
    end
end

function cscan = runCscan(plan, P, ATS, cscan, f)
% 真正上硬件。循环外只准备一次；循环里每行：arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
% 写成函数（同 bscan_test 的 runBscan），这样不管正常结束、报错还是 Ctrl+C，onCleanup 都会释放 ATS 的 buffer。
    assert(P.RUN_HARDWARE && P.Y_CALIBRATED, 'Cscan:NotArmed', '检查模式或 Y 未标定：不碰硬件。');
    NX = P.NX;  NY = P.NY;

    % ---- 循环外只做一次 ----
    cnt = [];
    if P.COUNT_CHECK
        cnt = daq("ni");
        addinput(cnt, "Dev1", "ctr1", "EdgeCount");      % 计数输入在 PFI3 (P1.3)
        resetcounters(cnt);
    end
    H = [];
    if P.ATS_ENABLE
        H = atsOpen(ATS);
        H.buffers = cell(1, P.nPost);                    % Inf → 每行的 buffer 全部预先分配；4 → 环形
        for j = 1:P.nPost
            H.buffers{j} = AlazarAllocBuffer(H.board, H.bytesPerBuffer);
        end
        atsGuard = onCleanup(@() releaseAll(H.board, H.buffers));   % 函数结束（包括报错、Ctrl+C）时 Abort + Free
    end
    dq = daq("ni");
    dq.Rate = P.fs;
    cscan.fsActual = dq.Rate;                            % NI 可能把采样率取整（100 MHz / 整数），待确认
    fprintf('DO 时钟：设 %d S/s，实际 %.1f S/s（不一样的话，所有时长和扫描速度按比例变）\n', P.fs, cscan.fsActual);
    if P.SAVE_DATA, m = matfile(f, 'Writable', true); m.fsActual = cscan.fsActual; end
    ai = addinput(dq, "Dev1", P.CLOCK_AI, "Voltage");    % 借 AI 时钟输出数字线（只读，不输出）
    ai.TerminalConfig = "Differential";
    for k = 1:numel(P.doLines)
        addoutput(dq, "Dev1", P.doLines(k), "Digital");
    end
    stopFig = uifigure('Name', 'C-scan', 'Position', [100 100 320 120]);
    stopBtn = uibutton(stopFig, 'push', 'Text', '停止（做完当前这一行）', 'Position', [30 35 260 50], ...
        'ButtonPushedFcn', @(src, ~) set(src, 'UserData', true, 'Text', '收到：这一行做完就停', 'Enable', 'off'));
    stopBtn.UserData = false;
    figGuard = onCleanup(@() delete(stopFig));           % 窗口已经被关掉也没关系，delete 不报错
    drawnow;                                             % 先把窗口画出来，第 1 行就能按
    fprintf('停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。\n');

    xNow = 0;  yNow = 0;     % 累计命令位置（脉冲），开工时的位置 = 0。命令值，不是实测
    posKnown = true;         % false = 有一个 readwrite 正在跑，出错时位置未知
    phase = "准备";          % 正在做哪一步，出错时打印
    iy = 0;
    c0 = ctrRead(cnt);
    cBefore = c0;
    try
        for iy = 1:NY
            if P.PAUSE_BETWEEN_ROWS
                input(sprintf('【暂停】第 %d 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）', iy), 's');
            end
            if isvalid(stopFig), stopFig.Name = sprintf('C-scan 第 %d/%d 行', iy, NY); end   % 窗口标题显示进度
            tRow = tic;              % 从第一次暂停之后开始计；6.10 计时的时候 PAUSE 要关

            % ① arm（行与行之间没有 P0.6，这时 arm 不会漏触发）
            phase = "arm";
            t = tic;
            cBefore = ctrRead(cnt);
            if P.ATS_ENABLE
                atsArmRow(H, ATS, NX);
            end
            cscan.timing.arm(iy) = toc(t);

            % ② 行扫描：readwrite 跑完之前 MATLAB 是卡住的，数据先进 buffer / 板载内存
            phase = "行扫描";
            t = tic;
            checkSoftLimit(xNow, yNow, plan.pos.row, P);
            posKnown = false;
            readwrite(dq, double(plan.rowTable), "OutputFormat", "Matrix");
            posKnown = true;
            xNow = xNow + plan.pos.row.dx;  yNow = yNow + plan.pos.row.dy;
            cscan.timing.scan(iy) = toc(t);

            % ③ 取数 → Abort → 这一行的 ctr1
            phase = "取数";
            t = tic;
            if P.ATS_ENABLE
                rawRow = atsCollectRow(H, ATS, NX, iy);
                AlazarAbortAsyncRead(H.board);           % 下一行 BeforeAsyncRead 之前必须先 Abort
            end
            cscan.trigCount(iy) = ctrRead(cnt) - cBefore;
            cscan.timing.collect(iy) = toc(t);
            if P.COUNT_CHECK && cscan.trigCount(iy) ~= NX
                fprintf(2, '⚠ 第 %d 行 ctr1 = %g，应为 %d\n', iy, cscan.trigCount(iy), NX);
            end

            % ④ 快速检查 + 存盘：电机再动之前先把这一行存好，回程出错也不丢这一行
            phase = "存盘";
            t = tic;
            if P.ATS_ENABLE
                cscan = storeRow(cscan, iy, rawRow);
            else
                cscan.rowsDone = iy;                     % 只动电机：没有数据，只记做到第几行
            end
            if P.SAVE_DATA
                saveRow(f, cscan, iy);
            end
            cscan.timing.save(iy) = toc(t);
            if P.PAUSE_BETWEEN_ROWS
                input(sprintf('【暂停】第 %d 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）', iy), 's');
            end

            % ⑤ 看停止按钮（readwrite 期间按的，在这里的 drawnow 才会被处理）
            drawnow;
            stopNow = iy < NY && (~isvalid(stopBtn) || stopBtn.UserData);

            % ⑥ 回程 + Y 一步；最后一行或者要停的时候只回程，Y 不动
            phase = "回程 + Y";
            t = tic;
            if iy < NY && ~stopNow
                mv = plan.moveMid;   s = plan.pos.moveMid;
            else
                mv = plan.moveLast;  s = plan.pos.moveLast;
            end
            checkSoftLimit(xNow, yNow, s, P);
            posKnown = false;
            readwrite(dq, double(mv), "OutputFormat", "Matrix");
            posKnown = true;
            xNow = xNow + s.dx;  yNow = yNow + s.dy;
            cscan.timing.move(iy) = toc(t);
            cscan.timing.row(iy) = toc(tRow);

            printRow(cscan, iy);
            if stopNow
                cscan.stopReason = "停止按钮";
                fprintf('收到停止：完成 %d/%d 条 A-line（%d/%d 行），不再扫下一行。\n', iy * NX, NX * NY, iy, NY);
                break
            end
        end

        % 回起点：正常扫完和中途停止一样，都按累计命令位置算（正常扫完时就是第 4 节的 finalTable）
        phase = "回起点";
        assert(xNow == 0 && yNow == (iy - 1) * P.Ky, '命令位置和计划不一致：X %d 步，Y %d 步。', xNow, yNow);
        [tbl, s] = homeTable(xNow, yNow, P);
        if ~isempty(tbl)
            posKnown = false;
            readwrite(dq, double(tbl), "OutputFormat", "Matrix");
            posKnown = true;
            xNow = xNow + s.dx;  yNow = yNow + s.dy;
        end
        cscan.trigCountTotal = ctrRead(cnt) - c0;
        fprintf('回到起点：命令位置 X %+.1f um，Y %+.1f um（应为 0 / 0）；ctr1 全程 %g（应为 %d）\n', ...
            xNow * P.X_UM_PER_PULSE, yNow * P.Y_UM_PER_PULSE, cscan.trigCountTotal, NX * cscan.rowsDone);
        if P.SAVE_DATA
            m = matfile(f, 'Writable', true);
            m.trigCountTotal = cscan.trigCountTotal;
            m.stopReason = cscan.stopReason;
            m.timing = cscan.timing;                     % 最后一行的回程计时在存盘之后才有
        end
    catch ME
        % 顺序（docs/14 安全）：先停 DMA → 保存已完成的行 → 打印 ctr1 → 再决定退不退回。
        % 每一步单独 try：哪一步再出错，都不能挡住后面的步骤。
        fprintf(2, '\n*** 第 %d 行（%s）出错：%s\n', iy, phase, ME.message);
        if P.ATS_ENABLE
            try
                AlazarAbortAsyncRead(H.board);
            catch e2
                warning('Cscan:Abort', 'AlazarAbortAsyncRead 失败：%s', e2.message);
            end
        end
        cNow = NaN;
        try
            cNow = ctrRead(cnt);
        catch
        end
        if iy >= 1 && isnan(cscan.trigCount(iy))
            cscan.trigCount(iy) = cNow - cBefore;        % 出错这一行的 ctr1 也记下（docs/14 6.7：应仍是 NX）
        end
        cscan.errorMessage = string(ME.message);
        cscan.failedRow = iy;
        cscan.failedPhase = phase;
        cscan.trigCountTotal = cNow - c0;
        assignin('base', 'cscan_partial', cscan);        % 函数报错时不会返回 cscan，放进工作区方便看
        if P.SAVE_DATA && isfile(f)
            try
                m = matfile(f, 'Writable', true);       % 完成的行在做完时已经写过盘，这里补记出错信息
                m.errorMessage = cscan.errorMessage;
                m.failedRow = iy;
                m.failedPhase = phase;
                m.trigCount = cscan.trigCount;
                m.trigCountTotal = cscan.trigCountTotal;
                m.timing = cscan.timing;
                fprintf('已完成的 %d 行在：%s\n', cscan.rowsDone, f);
            catch e4
                warning('Cscan:Save', '补记出错信息失败：%s', e4.message);
            end
        end
        fprintf('ctr1：全程 %g 个 P0.6 上升沿（已完成的 %d 行应为 %d）；第 %d 行 %g 个（这一行扫完应为 %d）\n', ...
            cscan.trigCountTotal, cscan.rowsDone, NX * cscan.rowsDone, iy, cNow - cBefore, NX);
        if posKnown
            fprintf('出错时没有 readwrite 在跑，命令位置已知：X %+.1f um，Y %+.1f um。\n', ...
                xNow * P.X_UM_PER_PULSE, yNow * P.Y_UM_PER_PULSE);
            try
                tbl = homeTable(xNow, yNow, P);
                if ~isempty(tbl)
                    fprintf('自动退回起点...\n');
                    readwrite(dq, double(tbl), "OutputFormat", "Matrix");
                end
                fprintf('已在起点。用手轮记号核对一下。\n');
            catch e3
                if e3.identifier == "Cscan:SoftLimit"
                    fprintf(2, '退回表超过软件限位，没有移动（%s）。SR2 断电后用手轮摇回记号。\n', e3.message);
                else
                    fprintf(2, '退回失败（%s）：位置未知，SR2 断电后用手轮重新归零（docs/14 0.4）。\n', e3.message);
                end
            end
        else
            fprintf(2, '出错时 readwrite 正在跑，位置未知：不自动移动。SR2 断电后用手轮重新归零（docs/14 0.4）。\n');
        end
        rethrow(ME);
    end
    clear dq cnt                                         % 用完立即释放 Dev1
end

function H = atsOpen(A)
% 加载 SDK、找到板卡、配置一次（同 bscan_test runBscan 第 247–268、280 行），
% 只是 CH A 阻抗、TRIG IN 量程、带宽限制改成了命名参数。A = ATS 参数；返回的 H 里带着每行要用的常量，循环里不用再跑 AlazarDefs。
    addpath(A.sdkInclude);
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
    impIds   = containers.Map({50, 1e6}, {IMPEDANCE_50_OHM, IMPEDANCE_1M_OHM});
    etrIds   = containers.Map({5, 1}, {ETR_5V, ETR_1V});    % ETR_5V = ETR_5V_50OHM = 0（TRIG IN 阻抗不能选）
    AlazarSetCaptureClock(board, INTERNAL_CLOCK, rateIds(A.sampleRate_Hz), CLOCK_EDGE_RISING, 0);
    AlazarInputControlEx(board, CHANNEL_A, DC_COUPLING, rangeIds(A.inputRange_V), impIds(A.inputImpedance_ohm));
    AlazarSetBWLimit(board, CHANNEL_A, A.bandwidthLimit);
    AlazarSetExternalTrigger(board, DC_COUPLING, etrIds(A.extTrigRange_V));
    AlazarSetTriggerOperation(board, TRIG_ENGINE_OP_J, TRIG_ENGINE_J, TRIG_EXTERNAL, ...
        TRIGGER_SLOPE_POSITIVE, A.triggerLevelCode, TRIG_ENGINE_K, TRIG_DISABLE, ...
        TRIGGER_SLOPE_POSITIVE, 128);
    AlazarSetTriggerDelay(board, A.triggerDelay);
    AlazarSetTriggerTimeOut(board, 0);                       % 0 = 一直等硬件触发，不自动触发
    AlazarConfigureAuxIO(board, AUX_OUT_TRIGGER, 0);
    AlazarSetRecordSize(board, 0, A.samplesPerALine);        % 触发前 0 点，触发后 spr 点

    H.board = board;
    H.channel = CHANNEL_A;
    H.admaFlags = bitor(ADMA_EXTERNAL_STARTCAPTURE, ADMA_NPT);
    H.bytesPerBuffer = 2 * A.samplesPerALine * A.recordsPerBuffer;
    H.buffers = {};
end

function atsArmRow(H, ATS, NX)
% 每行 arm 一次（docs/14 4.2）：这一行要 NX 条；先把 buffer 交给板卡，再 StartCapture（同 bscan_test 第 281–286 行）
    AlazarBeforeAsyncRead(H.board, H.channel, 0, ATS.samplesPerALine, ATS.recordsPerBuffer, NX, H.admaFlags);
    for j = 1:numel(H.buffers)
        AlazarPostAsyncBuffer(H.board, H.buffers{j}, H.bytesPerBuffer);
    end
    AlazarStartCapture(H.board);
end

function rawRow = atsCollectRow(H, ATS, NX, iy)
% 依次等每个 buffer 装满、拷出来。环形 buffer（分配的个数 < 每行的 buffer 数）时，拷完再 Post 回去给后面的记录用
% （照 ats9462_multi_aline.m 第 209–224 行）
    spr = ATS.samplesPerALine;
    rpb = ATS.recordsPerBuffer;
    nBuf = NX / rpb;
    nAlloc = numel(H.buffers);
    rawRow = zeros(spr, NX, 'uint16');
    for i = 1:nBuf
        j = mod(i - 1, nAlloc) + 1;                          % 轮到第 j 个 buffer：1, 2, …, nAlloc, 1, 2, …
        try
            AlazarWaitAsyncBufferComplete(H.board, H.buffers{j}, ATS.waitTimeout_ms);   % SDK 包装函数没有返回值，失败时直接抛错
        catch e
            if contains(e.message, ["ApiBufferOverflow" "(582)"])
                hint = '板载内存满了：环形模式 Post 的 buffer 太少，readwrite 期间板卡没地方放（docs/14 6.11）';
            else
                hint = sprintf('这一行收到的触发数在 %d ~ %d 之间，检查 G1 → TRIG IN', (i-1) * rpb, i * rpb - 1);
            end
            error('Cscan:Buffer', '第 %d 行 buffer %d/%d 未完成（%s）：%s。', iy, i, nBuf, e.message, hint);
        end
        setdatatype(H.buffers{j}, 'uint16Ptr', 1, spr * rpb);
        rawRow(:, (i-1) * rpb + (1:rpb)) = reshape(H.buffers{j}.Value, spr, rpb);
        if i + nAlloc <= nBuf
            AlazarPostAsyncBuffer(H.board, H.buffers{j}, H.bytesPerBuffer);   % 拷完再交还给板卡
        end
    end
end

function releaseAll(board, buffers)
% 先中止 DMA，再释放内存；中止失败时不释放，免得板卡还往里写（同 bscan_test）
% 正常结束时这是第二次 Abort（每行已经 Abort 过一次）；会不会报错待 docs/14 3.2 看（出现 Cscan:Abort 警告就要改）
    try
        AlazarAbortAsyncRead(board);
    catch e
        warning('Cscan:Abort', 'DMA abort failed; buffers NOT freed. Restart MATLAB. %s', e.message);
        return
    end
    for i = 1:numel(buffers)
        try
            AlazarFreeBuffer(board, buffers{i});
        catch
        end
    end
end
