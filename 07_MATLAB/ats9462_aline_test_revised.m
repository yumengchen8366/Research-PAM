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
% 目标：ATS9462 / CH A / 外部触发 / 单次 NPT 记录 No Pre-Trigger/ 保存原始数据与参数。
% 修改理由详见 ATS9462_Aline_Edit_Guide_ZH.md。
% 10/1 已用 ats9462_aline_once.m 实测（1 MHz 方波）；本文件从 10/3 起用于 A-line 测试
%
% 使用方法：保存本文件，检查下面参数区，然后在 MATLAB 运行整个脚本。
% 成功后工作区得到 aline；采集失败时保留 SDK 原始错误，aline 保持为空。
% 本脚本只接收 TRIG IN 的触发，不控制 NI、激光、电机或振镜。
% 运行时不要让另一个程序同时操作这张 ATS 卡。
% 每条记录 = postTriggerSamples 个点；每个 buffer 1 条；一次运行 1 个 buffer = 1 条

%% [01] 路径与常量：保留原 SDK 接口，用本机已经确认过的 Include 路径
aline = [];  % 避免本次失败后，把上一条结果误认为本次采集结果
raw_u16 = []; % 同上：采集失败时，工作区里不会留下上一次的原始数据
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
% ±400 mV 表示输入范围 -0.4 到 +0.4 V，不是 400 mVpp。 输入量程需要容纳实际端口电压的最大值、最小值和偏置，并留出适当余量；不能为了让数字看起来更大，就盲目选最小量程。
%还要区分：测量量程不是器件的过压安全额定值，不能用这里的 ±400 mV 推断接口可以承受多大的异常电压。


% 50 ohm 是否适合放大器，要按放大器输出要求确定；并非由 CH A 接线决定。
cfg.inputRange_V = 4;       % 量程 = ±inputRange_V，全宽是它的 2 倍（例如 4 表示 −4 到 +4 V，全宽 8 V）；此脚本支持 0.2、0.4、0.8、2、4

cfg.inputImpedanceId = IMPEDANCE_50_OHM; %输入阻抗的配置 这个应该还需要再确认一下 从信号源看进去，采集卡输入端呈现什么样的电气负载，设置采集卡这一端，不是把放大器输出阻抗设置成 50 Ω
%正确依据应当来自信号源或放大器的输出要求，以及传输链路的终端要求。
cfg.inputCouplingId = DC_COUPLING; 
%描述模拟输入链路能如何传递不同频率的信号。如果所需信号含有重要的更高频成分，打开限制器可能改变波形；如果高频部分主要是无用噪声，限制带宽可能有帮助官方说明约限制到 20 MHz。
cfg.bandwidthLimit = 0;      % 0 = 关闭板载带宽限制，仍受模拟前端带宽限制 

% 外部触发：对应已确认的 TRIG IN 接线。
% 保留示例的 DC / ETR_5V / Level 150，必须与实际触发信号相容。
% ETR_5V 是触发输入范围，不会输出 5 V，也不表示阈值为 5 V。
% Level 150 是无单位代码；在 ±5 V 范围下，阈值约 (150-128)*5/127=0.866 V。
cfg.triggerSourceId = TRIG_EXTERNAL; % 外部触发 连接到triggerin上的信号决定什么时候开始记录
cfg.triggerSlopeId = TRIGGER_SLOPE_POSITIVE;  % 上升沿：TRIG IN 电压从阈值以下升到阈值以上的那一刻触发；一直停在高电平不会再触发
cfg.triggerLevelCode = 150; % 触发阈值的编码（0–255，无单位）。128 ≈ 0 V，255 ≈ 外触发量程上限（ETR_5V 下 +5 V），每差 1 个编码约 5/127 ≈ 39 mV。150 比 128 高 22 格，阈值 ≈ 22 × 39.4 mV ≈ 0.87 V
cfg.externalTriggerCouplingId = DC_COUPLING;
cfg.externalTriggerRangeId    = ETR_5V; 
cfg.saveData = true;   % 是否保留这个数据
cfg.note = '1.8 PD trigger: NPL45C, gen CH1 1kHz 0-1V -> laser TRIG IN; PDA10A2 Top 2.9V/15ns -> ATS TRIG IN';
cfg.outputFolder = fullfile(pwd, 'aline_data');

%% [03] 检查参数，并把物理数值转换成 SDK 枚举
% 采样率数值与 SDK 标识在一处绑定，避免图的时间轴与硬件配置不一致。 一些转换的配置 switch是查看设置的采样率 要根据我设置的频率选择对应的sdk采集卡可以识别的标识
 % 采样率选项：180 MS/s，即每秒 180,000,000 个采样点。
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
switch cfg.inputRange_V % 把量程数值（单位 V）换成 SDK 标识
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
fprintf('Note: %s\n', cfg.note); % 超时没有文件时，命令行里也能看到这次测的是什么

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
%换算成电压：先转成 double，避免 uint16 运算饱和。编码 0 ≈ −量程，32768 ≈ 0 V，65535 ≈ +量程
aline.volts = (double(raw_u16) / 65535 * 2 - 1) * cfg.inputRange_V;
aline.time_record_s = (0:N-1)' / cfg.sampleRate_Hz; % 相对记录第一个点的时间（s）；第 n 个点是 (n-1)/fs
aline.time_trigger_s = (cfg.triggerDelay_samples + (0:N-1)') / cfg.sampleRate_Hz;
% time_trigger_s 是相对于 ATS 触发的名义采样时间；不是已标定的激光时间零点。
aline.config = cfg; % 保存本次配置
aline.channel = 'A';  %标记采集通道
aline.mode = 'NPT, one record, zero pre-trigger samples'; % 标记采集方式
aline.bitsPerSample = double(bitsPerSample); % 保存adc位数
aline.memorySize_samples = double(memorySize_samples); % 保存查询到的板卡板载内存容量（每通道，单位：采样点）
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
title(sprintf('CH A | %.0f MS/s | %d samples | %s', cfg.sampleRate_Hz / 1e6, N, cfg.note), ...
    'Interpreter', 'none'); % none：note 里的下划线不当成下标
grid on;
fprintf('Captured ONE record: %d points; min %.3f mV, max %.3f mV; rail codes %d.\n', ...
    N, min(aline.volts) * 1e3, max(aline.volts) * 1e3, aline.adcRailCount);
% 写一下记录的点数 最低和最高的电压 和边界的编码数量

%% [09] 配置函数：只配置 CH A，但保留完整触发设置
function configureBoard(boardHandle, cfg)
    AlazarDefs;
    % 硬件配置：设置这张卡的 ADC 采样时钟。
    AlazarSetCaptureClock(boardHandle, INTERNAL_CLOCK, ...
        cfg.sampleRateId, CLOCK_EDGE_RISING, 0);
    AlazarInputControlEx(boardHandle, CHANNEL_A, cfg.inputCouplingId, ...
        cfg.inputRangeId, cfg.inputImpedanceId);
    AlazarSetBWLimit(boardHandle, CHANNEL_A, cfg.bandwidthLimit);

    % 先设置外部触发端的范围与耦合，再配置 J 触发引擎；K 不使用。
    AlazarSetExternalTrigger(boardHandle, ...
        cfg.externalTriggerCouplingId, cfg.externalTriggerRangeId);
    % 硬件配置：设置触发判断逻辑。触发逻辑只使用 J 引擎的判断结果，接下来的参数用于配置 J 
    % 当信号从阈值以下上升穿过阈值时触发。 J 的触发阈值代码为 150；这是编码，不是 150 mV
    AlazarSetTriggerOperation(boardHandle, ...
        TRIG_ENGINE_OP_J, TRIG_ENGINE_J, cfg.triggerSourceId, ...
        cfg.triggerSlopeId, cfg.triggerLevelCode, ...
     TRIG_ENGINE_K, TRIG_DISABLE, TRIGGER_SLOPE_POSITIVE, 128); % 接下来填写 K 触发引擎的参数，关闭 K 引擎， K 的斜率参数；由于 K 被关闭，不构成有效触发条件 K 的阈值参数；同样不参与当前有效触发判断
    
    % 软件参数：不额外增加可编程触发延迟，单位是 ADC 采样时钟数。
    AlazarSetTriggerDelay(boardHandle, cfg.triggerDelay_samples);

    % 把这个延迟设置给板卡 表示当前不主动把记录窗口再向后推移。
    % 0 = 不启用“等不到触发就自动触发”；不是主机等待 0 毫秒。
    AlazarSetTriggerTimeOut(boardHandle, 0);
   
    % AUX 未接线，保留明确的输出配置，不把 AUX 用作输入门控。 AUX_OUT_TRIGGER 在数据采集到板上存储期间输出高电平，其他时候为低。
    AlazarConfigureAuxIO(boardHandle, AUX_OUT_TRIGGER, 0);
end

%% [10] 当前配置：1 次有效触发 -> 1 条 NPT record -> 填满 1 个 DMA buffer
function raw_u16 = acquireData(boardHandle, cfg)

% 在当前函数工作区加载 AlazarTech SDK 常量定义；
% 本行不配置硬件，也不开始采集。
AlazarDefs;

% 当前 record 不返回 trigger 之前的样本。
preTriggerSamples = 0;

% 每条 record 返回多少个 post-trigger samples。
% 当前由主程序 cfg.postTriggerSamples 决定，例如 1024。
postTriggerSamples = cfg.postTriggerSamples;

% 一个 DMA buffer 需要多少条 record 才算填满。
% 当前设为 1，因此一次被接受的 trigger 即可产生一条 record 并填满 buffer。
recordsPerBuffer = 1;

% 本教学版本计划只完成一个这样的 buffer。
% 这是 MATLAB sample 用于计算总 record 数的变量，
% 并不是"同时分配多少块 DMA 内存"的 SDK 参数。
buffersPerAcquisition = 1;

% 本次 acquisition 总共请求多少条 record。
% 当前 1 × 1 = 1 record。
recordsPerAcquisition = ...
    recordsPerBuffer * buffersPerAcquisition;

% 本次 AutoDMA 只传输 CH A 的采样数据。
channelMask = CHANNEL_A;

% 当前明确只采一个通道，因此数据量计算中的通道数为 1。
channelCount = 1;

% 每个原始 ADC sample 占 2 bytes。
% 主程序已通过 AlazarGetChannelInfo 确认 bitsPerSample == 16。
bytesPerSample = 2;

% 每条 record 的样本数。
% 当前 preTriggerSamples = 0，因此等于 postTriggerSamples。
samplesPerRecord = ...
    preTriggerSamples + postTriggerSamples;

% 一个 DMA buffer 中包含的总 sample 数。
% 当前 = samplesPerRecord × 1 record × 1 channel。
samplesPerBuffer = ...
    samplesPerRecord * recordsPerBuffer * channelCount;

% 为一个 DMA buffer 需要准备的字节数。
bytesPerBuffer = ...
    bytesPerSample * samplesPerBuffer;

% 使用 AlazarTech SDK 提供的 DMA buffer 分配函数，
% 为本次采集申请一块适合 DMA 传输的主机内存。
% 这里是一次有限采集，只需要一个 buffer，不建立循环复用的多-buffer 队列。
pbuffer = AlazarAllocBuffer(boardHandle, bytesPerBuffer);

% 注册清理函数：
% acquireData 无论正常结束还是因错误退出，都会尝试执行 releaseDMA，
% 先停止异步 DMA，再释放这块 buffer。
cleanupGuard = onCleanup(@() releaseDMA(boardHandle, pbuffer)); %#ok<NASGU>

% 配置每条 record 的长度：
% 当前为 preTriggerSamples 个触发前样本
% + postTriggerSamples 个触发后样本。
% 本行只配置 record size，不开始采集。
AlazarSetRecordSize(boardHandle, preTriggerSamples, postTriggerSamples);

% 组合 AutoDMA 模式和启动方式。
% ADMA_NPT：使用 NPT（No Pre-Trigger）AutoDMA 模式。
% ADMA_EXTERNAL_STARTCAPTURE：
% acquisition 需要由程序显式调用 AlazarStartCapture 启动；
% 这里的 EXTERNAL 不是指 TRIG IN。
% 真正的触发源已在 AlazarSetTriggerOperation 中配置。
admaFlags = bitor(ADMA_EXTERNAL_STARTCAPTURE, ADMA_NPT);

% 配置本次 AutoDMA 数据传输：
% - 采集哪个通道
% - 每条 record 传多少 samples
% - 每个 buffer 包含多少 records
% - 本次 acquisition 总共采多少 records
% - 使用哪些 AutoDMA 模式/flags
AlazarBeforeAsyncRead(boardHandle, channelMask, -int32(preTriggerSamples), ...
    samplesPerRecord, recordsPerBuffer, recordsPerAcquisition, admaFlags);

% 把刚刚申请的 host DMA buffer 提交给驱动，
% 使它进入"可由板卡 DMA 写入"的等待队列。
% 这一步不是把数据发送到板卡。
AlazarPostAsyncBuffer(boardHandle, pbuffer, bytesPerBuffer);

% 启动/arm 已经配置好的 acquisition。
% 本行不会产生外部 trigger；
% 它使板卡进入可以等待触发事件并采集 record 的状态。
AlazarStartCapture(boardHandle);

fprintf('ATS armed. Waiting for ONE external trigger (timeout %.1f s)...\n', ...
    cfg.timeout_ms / 1000);

% 等待这个已提交的 DMA buffer 被填满。
% 当前 recordsPerBuffer = 1，
% 因此一个被接受的有效 trigger -> 一条 record -> buffer 完成。
% 如果在 cfg.timeout_ms 内 buffer 仍未完成，则会出现 timeout。
AlazarWaitAsyncBufferComplete(boardHandle, pbuffer, cfg.timeout_ms);

% 告诉 MATLAB：
% 这块 DMA 内存应解释为 samplesPerBuffer 个 uint16 元素。
% 本行不改变 ADC 的硬件位数，只改变 MATLAB 对内存内容的解释方式。
setdatatype(pbuffer, 'uint16Ptr', 1, samplesPerBuffer);

% 读取 DMA buffer 中的原始 ADC 编码到 MATLAB 变量。
% 此时仍是 uint16 raw ADC codes，还没有换算成 volts。
raw_u16 = pbuffer.Value;

% 统一整理成 N x 1 列向量，方便后续计算和保存。
raw_u16 = raw_u16(:);

% 当前版本每个 buffer 只有一条 record、只有 CH A，
% 因此实际读取到的元素数应等于 samplesPerRecord。
assert(numel(raw_u16) == samplesPerRecord, 'Unexpected record size.');

% acquireData 结束时 cleanupGuard 会请求执行 releaseDMA：
% 先 AbortAsyncRead，再释放 DMA buffer。
%
% 当前 acquisition 只有一条 record，因此不需要再次 Post 这个 buffer。
% 如果以后改为连续采集或多-buffer acquisition，
% 就需要重新设计 buffer repost / 循环逻辑。
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


