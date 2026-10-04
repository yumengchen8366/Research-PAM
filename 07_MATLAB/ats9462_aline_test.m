%---------------------------------------------------------------------------
%
% Copyright (c) 2008-2023 AlazarTech, Inc.
%
% AlazarTech, Inc. licenses this software under specific terms and
% conditions. Use of any of the software or derivatives thereof in any
% product without an AlazarTech digitizer board is strictly prohibited.
%
% AlazarTech, Inc. provides this software AS IS, WITHOUT ANY WARRANTY,
% EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY WARRANTY OF
% MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. AlazarTech makes no
% guarantee or representations regarding the use of, or the results of the
% use of, the software and documentation in terms of correctness, accuracy,
% reliability, currentness, or otherwise; and you rely on the software,
% documentation and results solely at your own risk.
%
% IN NO EVENT SHALL ALAZARTECH BE LIABLE FOR ANY LOSS OF USE, LOSS OF
% BUSINESS, LOSS OF PROFITS, INDIRECT, INCIDENTAL, SPECIAL OR CONSEQUENTIAL
% DAMAGES OF ANY KIND. IN NO EVENT SHALL ALAZARTECH%S TOTAL LIABILITY EXCEED
% THE SUM PAID TO ALAZARTECH FOR THE PRODUCT LICENSED HEREUNDER.
%
%---------------------------------------------------------------------------
% Adapted from the user's ATS-SDK 23.3.0 MATLAB NPT example.
% 目标：ATS9462 / CH A / 外部触发 / 单次 NPT 记录 / 保存原始数据与参数。
% 修改理由详见 ATS9462_Aline_Edit_Guide_ZH.md。
% 此代码尚未在用户的 Windows MATLAB + ATS9462 上进行真实采集测试。
%
% 使用方法：保存本文件，检查下面参数区，然后在 MATLAB 运行整个脚本。
% 成功后工作区得到 aline；采集失败时保留 SDK 原始错误，aline 保持为空。
% 本脚本只接收 TRIG IN 的触发，不控制 NI、激光、电机或振镜。
% 运行时不要让另一个程序同时操作这张 ATS 卡。

%% [01] 路径与常量：保留原 SDK 接口，用本机已经确认过的 Include 路径
aline = [];  % 避免本次失败后，把上一条结果误认为本次采集结果
sdkInclude = 'C:\AlazarTech\ATS-SDK\23.3.0\Samples_MATLAB\Include';
%初始化
assert(isfolder(sdkInclude), 'ATS SDK Include directory does not exist.');
%不存在报错
addpath(sdkInclude);
%目录加入搜索路径
AlazarDefs;  % 定义 CHANNEL_A、TRIG_EXTERNAL 等名称，本行本身不启动硬件
%厂家在里面定义了 需要详细确认

%% [02] 参数集中到 cfg：以后优先改这里 配置都有什么
cfg = struct();
cfg.systemId = int32(1);
%设备选择ats系统编号1
cfg.boardId = int32(1);
%改系统中的第一张版卡
cfg.sampleRate_Hz = 180e6;     % 180 MS/s，adc采样率 要与 180 kS/s区分
cfg.postTriggerSamples = 1024; % 一条记录的点数；记录长度；每次触发后记录1024个点；1024/180e6 = 5.689 us
cfg.triggerDelay_samples = 0; % ADC 采样点单位；0 = 暂不增加可编程延迟
cfg.timeout_ms = 5000;        % 主机最多等待缓冲区完成5000ms

% 以下是保留自官方示例的输入参数起点，不是已验证的放大器最佳设置。
% ±400 mV 表示输入范围 -0.4 到 +0.4 V，不是 400 mVpp。
% 50 ohm 是否适合放大器，要按放大器输出要求确定；并非由 CH A 接线决定。
cfg.inputRange_V = 0.4;       % 此脚本提供 0.2、0.4、0.8、2、4 V 的映射 +- 0.4v 不是mv +-400mv 全部宽度是800mv

cfg.inputImpedanceId = IMPEDANCE_50_OHM; %输入阻抗的配置 这个应该还需要再确认一下 

cfg.inputCouplingId = DC_COUPLING; 
cfg.bandwidthLimit = 0;      % 0 = 关闭板载带宽限制，仍受模拟前端带宽限制

% 外部触发：对应已确认的 TRIG IN 接线。
% 保留示例的 DC / ETR_5V / Level 150，必须与实际触发信号相容。
% ETR_5V 是触发输入范围，不会输出 5 V，也不表示阈值为 5 V。
% Level 150 是无单位代码；在 ±5 V 范围下，阈值约 (150-128)*5/127=0.866 V。
cfg.triggerSourceId = TRIG_EXTERNAL; % 外部触发 连接到triggerin上的信号决定什么时候开始记录
cfg.triggerSlopeId = TRIGGER_SLOPE_POSITIVE;  %就是一个上升的 电平 还要满足上升的最高坐值 超越过设定的阈值
cfg.triggerLevelCode = 150; % sdk的无单位编码 因为128v对应约为0v 255 对应的量程的最大值 后面的外部触发范围是+—5v 相当于 多少个电压是一个level 
cfg.externalTriggerCouplingId = DC_COUPLING;  %触发的方式dc耦合
cfg.externalTriggerRangeId = ETR_5V;

cfg.saveData = false;   % 是否保留这个数据

cfg.outputFolder = fullfile(pwd, 'aline_data');

%% [03] 检查参数，并把物理数值转换成 SDK 枚举
% 采样率数值与 SDK 标识在一处绑定，避免图的时间轴与硬件配置不一致。 一些转换的配置 switch是查看设置的采样率 要根据我设置的频率选择对应的sdk采集卡可以识别的标识
switch cfg.sampleRate_Hz
    case 100e6
        cfg.sampleRateId = SAMPLE_RATE_100MSPS;
    case 160e6
        cfg.sampleRateId = SAMPLE_RATE_160MSPS;
    case 180e6
        cfg.sampleRateId = SAMPLE_RATE_180MSPS;
    otherwise
        error('Aline:SampleRate', 'This teaching version supports 100, 160 or 180 MS/s.');
end
switch cfg.inputRange_V % 把多少+—v 转换为对应的sdk标识 现在设置的是400mv！！！ 
    case 0.2
        cfg.inputRangeId = INPUT_RANGE_PM_200_MV;
    case 0.4
        cfg.inputRangeId = INPUT_RANGE_PM_400_MV;
    case 0.8
        cfg.inputRangeId = INPUT_RANGE_PM_800_MV;
    case 2
        cfg.inputRangeId = INPUT_RANGE_PM_2_V;
    case 4
        cfg.inputRangeId = INPUT_RANGE_PM_4_V;
    otherwise
        error('Aline:InputRange', 'Choose a supported input range from the mapping above.');
end
% 一些要求的设定 要求记录的点数是 数值型 单个数 真实的 实数 有限的值 还要是整数 还要大于等于256
validateattributes(cfg.postTriggerSamples, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', '>=', 256});
% 计算余数 要检查 点数是否是32 的整数倍 因为采集卡说到 ats9462 最小的记录长度为256 记录长度步进为32
assert(mod(cfg.postTriggerSamples, 32) == 0, ...
    'ATS9462 record length must be a multiple of 32 samples.');
% 检查延迟的点数 是单个 有限 非负整数 
validateattributes(cfg.triggerDelay_samples, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'nonnegative'});
% 这个脚本是按照单通道延迟 以2个采样点对其进行检查 当前设置0 会通过
assert(mod(cfg.triggerDelay_samples, 2) == 0, ...
    'ATS9462 single-channel trigger delay must be a multiple of 2 samples.');
% 要求触发编码是0-255的整数
validateattributes(cfg.triggerLevelCode, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', '>=', 0, '<=', 255});
% 要求软件超时时间是正整数毫秒
validateattributes(cfg.timeout_ms, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'positive'});
assert(cfg.triggerSourceId == TRIG_EXTERNAL, ...
    'This version is configured for external trigger acquisition.');

%% [04] 连接板卡：保留原示例的调用方式
%一些所需要的代码。。。
alazarLoadLibrary();
% 获得目标的handle 能够操作这张卡 
boardHandle = AlazarGetBoardBySystemID(cfg.systemId, cfg.boardId);
[memorySize_samples, bitsPerSample] = AlazarGetChannelInfo(boardHandle);
% 确认返回的是16bit 因为后面读取和电压都按照16bit编写
assert(double(bitsPerSample) == 16, ...
    'This version expects the confirmed 16-bit ATS9462 data format.');

configureBoard(boardHandle, cfg);
fprintf('CH A: %.0f MS/s, %d samples, nominal window %.3f us.\n', ...
    cfg.sampleRate_Hz / 1e6, cfg.postTriggerSamples, ...
    cfg.postTriggerSamples / cfg.sampleRate_Hz * 1e6);

%% [05] 一次采集：若发生 SDK 错误，函数退出时执行 DMA 清理
% 外部触发需在 ATS 已准备好之后出现；持续高电平不等于新的上升沿。
% 若只有原 LabVIEW 才能生成 P0.6，而它没有输出，这里会等待并超时。
%开始第一次采集了 调用下方10的采集函数 raw16 是原始数据 u16是无符号的16位整数  这个是采集卡的编码还不是电压
raw_u16 = acquireData(boardHandle, cfg);

%% [06] 构造结果：先 double 再计算，避免 uint16 的减法/乘法饱和
% 一共采集到了多少个数字 正常情况下aline才多少个点就是多少个n
N = numel(raw_u16);
aline = struct();
aline.raw_u16 = raw_u16;      % 原始 ADC 编码，N x 1 列向量
%换算成电压 换算成浮点数 以免除不开 原始编码0 是-0.4v 32768是0v
aline.volts = (double(raw_u16) / 65535 * 2 - 1) * cfg.inputRange_V;
aline.time_record_s = (0:N-1)' / cfg.sampleRate_Hz;
aline.time_trigger_s = (cfg.triggerDelay_samples + (0:N-1)') / cfg.sampleRate_Hz;
% time_trigger_s 是相对于 ATS 触发的名义采样时间；不是已标定的激光时间零点。
aline.config = cfg; % 保存本次配置
aline.channel = 'A';  %标记采集通道
aline.mode = 'NPT, one record, zero pre-trigger samples'; % 标记采集方式
aline.bitsPerSample = double(bitsPerSample); % 保存adc位数
aline.memorySize_samples = double(memorySize_samples); % 保存查询到的显卡容量
aline.nominalWindow_s = N / cfg.sampleRate_Hz; %保存窗口的长度
aline.adcRailCount = sum(raw_u16 == 0 | raw_u16 == 65535); % 统计有多少点落在最低或者最高的编码上 判断是否相等 判断或 统计满足条件的点数 
aline.hostCompletionTime = datetime('now', 'TimeZone', 'local');
% hostCompletionTime 是电脑完成处理的时间，不是硬件触发时间戳。

%% [07] 采完再保存：同时保存原始数据、换算结果和参数
if cfg.saveData
    if ~isfolder(cfg.outputFolder)
        mkdir(cfg.outputFolder);
    end
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
    outputPath = fullfile(cfg.outputFolder, ['aline_' stamp '.mat']);
    assert(~isfile(outputPath), 'Output already exists; refusing to overwrite it.');
    aline.savedFile = outputPath;
    save(outputPath, 'aline');
    fprintf('Saved: %s\n', outputPath);
end

%% [08] 显示一条曲线：横轴 us，纵轴 mV；不滤波、不平均、不扣基线
figure('Name', 'ATS9462 single A-line'); 
plot(aline.time_trigger_s * 1e6, aline.volts * 1e3); % 改一下单位 微秒和毫伏
xlabel('Nominal time relative to ATS trigger (us)');
ylabel('CH A voltage (mV)');
title(sprintf('CH A | %.0f MS/s | %d samples', cfg.sampleRate_Hz / 1e6, N));
grid on;
fprintf('Captured ONE record: %d points; min %.3f mV, max %.3f mV; rail codes %d.\n', ...
    N, min(aline.volts) * 1e3, max(aline.volts) * 1e3, aline.adcRailCount);
% 写一下记录的点数 最低和最高的电压 和边界的编码数量

%% [09] 配置函数：只配置 CH A，但保留完整触发设置
function configureBoard(boardHandle, cfg)
    AlazarDefs;
    AlazarSetCaptureClock(boardHandle, INTERNAL_CLOCK, ...
        cfg.sampleRateId, CLOCK_EDGE_RISING, 0);
    AlazarInputControlEx(boardHandle, CHANNEL_A, cfg.inputCouplingId, ...
        cfg.inputRangeId, cfg.inputImpedanceId);
    AlazarSetBWLimit(boardHandle, CHANNEL_A, cfg.bandwidthLimit);

    % 先设置外部触发端的范围与耦合，再配置 J 触发引擎；K 不使用。
    AlazarSetExternalTrigger(boardHandle, ...
        cfg.externalTriggerCouplingId, cfg.externalTriggerRangeId);
    AlazarSetTriggerOperation(boardHandle, ...
        TRIG_ENGINE_OP_J, TRIG_ENGINE_J, cfg.triggerSourceId, ...
        cfg.triggerSlopeId, cfg.triggerLevelCode, ...
        TRIG_ENGINE_K, TRIG_DISABLE, TRIGGER_SLOPE_POSITIVE, 128);
    AlazarSetTriggerDelay(boardHandle, cfg.triggerDelay_samples);

    % 0 = 不启用“等不到触发就自动触发”；不是主机等待 0 毫秒。
    AlazarSetTriggerTimeOut(boardHandle, 0);
    % AUX 未接线，保留明确的输出配置，不把 AUX 用作输入门控。
    AlazarConfigureAuxIO(boardHandle, AUX_OUT_TRIGGER, 0);
end

%% [10] 采集函数：一次触发 -> 一条记录 -> 一个 DMA 缓冲区
function raw_u16 = acquireData(boardHandle, cfg)
    AlazarDefs;
    preTriggerSamples = 0;
    postTriggerSamples = cfg.postTriggerSamples;
    recordsPerBuffer = 1;
    buffersPerAcquisition = 1;
    recordsPerAcquisition = recordsPerBuffer * buffersPerAcquisition;
    channelMask = CHANNEL_A;
    channelCount = 1;
    bytesPerSample = 2;  % 主程序已检查 bitsPerSample == 16
    samplesPerRecord = preTriggerSamples + postTriggerSamples;
    samplesPerBuffer = samplesPerRecord * recordsPerBuffer * channelCount;
    bytesPerBuffer = bytesPerSample * samplesPerBuffer;

    % 保留 SDK 的 DMA 分配器，不用普通 zeros 数组替代 DMA 内存。
    % 这里只做一次有限采集，无需连续采集的环形多缓冲区。
    pbuffer = AlazarAllocBuffer(boardHandle, bytesPerBuffer);
    cleanupGuard = onCleanup(@() releaseDMA(boardHandle, pbuffer)); %#ok<NASGU>

    AlazarSetRecordSize(boardHandle, preTriggerSamples, postTriggerSamples);
    % EXTERNAL_STARTCAPTURE 指由应用显式调用 StartCapture，
    % 并不是选择 TRIG IN；触发源在 SetTriggerOperation 中另行选择。
    admaFlags = bitor(ADMA_EXTERNAL_STARTCAPTURE, ADMA_NPT);
    AlazarBeforeAsyncRead(boardHandle, channelMask, -int32(preTriggerSamples), ...
        samplesPerRecord, recordsPerBuffer, recordsPerAcquisition, admaFlags);
    AlazarPostAsyncBuffer(boardHandle, pbuffer, bytesPerBuffer);
    AlazarStartCapture(boardHandle);
    fprintf('ATS armed. Waiting for ONE external trigger (timeout %.1f s)...\n', ...
        cfg.timeout_ms / 1000);
    AlazarWaitAsyncBufferComplete(boardHandle, pbuffer, cfg.timeout_ms);

    setdatatype(pbuffer, 'uint16Ptr', 1, samplesPerBuffer);
    raw_u16 = pbuffer.Value;   % 复制到 MATLAB 数组；之后才允许释放 DMA 内存
    raw_u16 = raw_u16(:);
    assert(numel(raw_u16) == samplesPerRecord, 'Unexpected record size.');
    % 函数正常返回、报错或被 Ctrl+C 中断时，cleanupGuard 请求清理。
    % 不重新 Post：这一条已经采完，本版本没有第二次 DMA 传输。
end

%% [11] 清理顺序：先中止 DMA，再释放它可能仍会写入的内存
function releaseDMA(boardHandle, pbuffer)
    try
        AlazarAbortAsyncRead(boardHandle);
    catch cleanupError
        % 不能确认 DMA 已停止时，不冒险释放驱动可能仍在写入的内存。
        warning('Aline:AbortFailed', ...
            'DMA abort failed; buffer was NOT freed. Restart MATLAB before retrying. %s', ...
            cleanupError.message);
        return
    end
    try
        AlazarFreeBuffer(boardHandle, pbuffer);
    catch cleanupError
        warning('Aline:FreeFailed', 'DMA buffer release failed: %s', cleanupError.message);
    end
end
