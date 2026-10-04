function result = pam_aline_start(voltage_V, fs_Hz, firstSampleTime_s)
% PAM_ALINE_START  从一条 A-line 开始理解 MATLAB 数据流程。
% 第一版：模拟数据 / 已转换成电压的实测数据 -> 时间轴 -> 显示。
% 本文件没有采集卡、DO、激光或电机控制命令，不是真实硬件采集程序。
%
% 用法 1：模拟演示，下载后在当前文件夹运行：
%   result = pam_aline_start;
%
% 用法 2：输入已经从 LabVIEW 导出的单通道、单条波形：
%   result = pam_aline_start(myVoltageVector_V, actualADCsampleRate_Hz);
%   第三个参数省略时，时间零点仅代表第一个采样点，不代表激光发射。
%   若已确认第一个采样点相对触发的时间，可显式传入第三个参数：
%   result = pam_aline_start(myVoltageVector_V, actualADCsampleRate_Hz, t0_s);
%
% 保存（自行选择新文件名，避免覆盖旧实验）：
%   save('aline_run01.mat', 'result');
%
% 实测输入要求：
%   1. voltage_V 是已标定为 V 的数值向量，不是原始 ADC 码或 DO 数组。
%   2. 不自动把矩阵展开；先确认通道排列和每条记录的边界。
%   3. fs_Hz 必须是 ADC 采样率，不是 laser rate、DO rate 或 motor rate。
%   4. scan_pattern.mat 的 sampling_rows 含义尚未确定，不直接导入。
%
% 与现有 LabVIEW 的关系（按工程引用提出的模块划分，非已验证调用顺序）：
%   Digitizer_initialization.vi -> 将来的采集卡配置函数
%   GetDAQAsyncData.vi          -> 将来的硬件波形读取函数
%   RawData2Range.vi            -> 将来的 ADC 码到电压转换函数
%   本文件下面的时间轴、绘图、返回结果部分可以保留。
%   Main.vi 为二进制 VI，缺少子 VI 内容，尚未确认其真实内部数据流。
%
% 真实硬件版的下一步需要确认：
%   板卡型号、MATLAB/驱动/SDK 版本、ADC 时钟源与实际采样率、输入通道、
%   量程、耦合、阻抗、触发源/边沿/阈值、预触发点数、触发延迟、
%   每条记录长度、数据格式，以及 GateTrig/DO 与采集卡的连接。
%   硬件版须使用匹配 SDK 的例程，加入等待超时和异常停止/资源释放。
%
% 此版本仅用 MATLAB 基础函数，不需要额外工具箱。

%% 1. 数据入口：现在用模拟数据，以后替换为采集卡返回的一条波形
if nargin == 0
    % 以下全部是教学示例，不是从你的 LabVIEW 提取的真实设置。
    fs_Hz = 100e6;               % 模拟 ADC 采样率：100 MS/s
    numberOfSamples = 1024;      % 模拟一条记录的点数，不是 Xn
    firstSampleTime_s = 0;       % 模拟记录从 t=0 开始
    t = (0:numberOfSamples-1)' / fs_Hz;

    % 生成一个双极性脉冲，加上背景扰动与直流偏置。
    % 它只用于演示，不是探头模型，也不能证明检测到了真实 PA 信号。
    previousRng = rng;
    restoreRng = onCleanup(@() rng(previousRng)); %#ok<NASGU>
    rng(7, 'twister');
    centerTime_s = 4e-6;
    width_s = 0.12e-6;
    u = (t-centerTime_s) / width_s;
    pulse_V = 0.015 * u .* exp(-0.5*u.^2);
    voltage_V = pulse_V + 0.0008*randn(size(t)) + 0.002;
    source = 'SIMULATED - no hardware acquisition';
    timeReference = 'Simulated record start';
elseif nargin == 2 || nargin == 3
    source = 'IMPORTED - caller-supplied voltage waveform';
    if nargin == 2
        firstSampleTime_s = 0;
        timeReference = 'First sample only; trigger/laser timing unknown';
    else
        timeReference = 'Caller-supplied time reference; verify experimentally';
    end
else
    error('pam:Arguments', ...
        'Use pam_aline_start, or pam_aline_start(voltage_V, fs_Hz [, t0_s]).');
end

%% 2. 检查数据：只接受一条波形，避免误把多通道/多条记录拼在一起
validateattributes(voltage_V, {'numeric'}, ...
    {'real', 'finite', 'vector', 'nonempty'}, mfilename, 'voltage_V');
if numel(voltage_V) < 2
    error('pam:TooShort', 'An A-line must contain at least two samples.');
end
validateattributes(fs_Hz, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'positive'}, mfilename, 'fs_Hz');
validateattributes(firstSampleTime_s, {'numeric'}, ...
    {'real', 'finite', 'scalar'}, mfilename, 'firstSampleTime_s');
voltage_V = double(voltage_V(:)); % 统一为 N×1 列向量；不改变输入电压单位
fs_Hz = double(fs_Hz);
firstSampleTime_s = double(firstSampleTime_s);
numberOfSamples = numel(voltage_V);

%% 3. 时间轴：相邻点间隔 = 1 / ADC 采样率
time_s = firstSampleTime_s + (0:numberOfSamples-1)' / fs_Hz;
sampleInterval_s = 1/fs_Hz;
recordDuration_s = numberOfSamples/fs_Hz; % N 个采样间隔的记录时长约定
firstToLastSpan_s = (numberOfSamples-1)/fs_Hz; % 图上首末采样点的间距
% 不自动换算成深度：还需要确认时间零点、系统延迟和声速。

%% 4. 指标：保留原始电压，不默认滤波、平均或去直流
vpp_V = max(voltage_V)-min(voltage_V);
mean_V = mean(voltage_V);
acRms_V = sqrt(mean((voltage_V-mean_V).^2));
% 这里的 AC RMS 含信号和扰动，不能直接称为“噪声 RMS”。

%% 5. 显示：横轴 us，纵轴 mV；标题明确区分模拟/导入
figure('Name', 'PAM A-line starter', 'Color', 'w');
plot(time_s*1e6, voltage_V*1e3, 'Color', [0.08 0.35 0.75], 'LineWidth', 1.2);
grid on;
xlabel('Time (us)');
ylabel('Voltage (mV)');
title({source, sprintf('N = %d | ADC Fs = %.6g MS/s | Vpp = %.3f mV', ...
    numberOfSamples, fs_Hz/1e6, vpp_V*1e3)}, 'Interpreter', 'none');
xlim([time_s(1), time_s(end)]*1e6);

%% 6. 返回数据与元信息：以后可把 result.voltage_V 放入 B-scan 的一列
result.source = source;
result.createdAt = datestr(now, 30);
result.timeReference = timeReference;
result.fs_Hz = fs_Hz;
result.numberOfSamples = numberOfSamples;
result.firstSampleTime_s = firstSampleTime_s;
result.sampleInterval_s = sampleInterval_s;
result.recordDuration_s = recordDuration_s;
result.firstToLastSpan_s = firstToLastSpan_s;
result.time_s = time_s;
result.voltage_V = voltage_V;
result.metrics.vpp_V = vpp_V;
result.metrics.mean_V = mean_V;
result.metrics.acRms_V = acRms_V;

fprintf('%s\n', source);
fprintf('N = %d; ADC Fs = %.6g MS/s; dt = %.6g ns\n', ...
    numberOfSamples, fs_Hz/1e6, sampleInterval_s*1e9);
fprintf('N/Fs = %.6g us; first-to-last span = %.6g us\n', ...
    recordDuration_s*1e6, firstToLastSpan_s*1e6);
fprintf('Vpp = %.3f mV; whole-record AC RMS = %.3f mV\n', vpp_V*1e3, acRms_V*1e3);
fprintf('Time reference: %s\n', timeReference);
end
