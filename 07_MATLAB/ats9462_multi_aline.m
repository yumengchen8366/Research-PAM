function mline = ats9462_multi_aline(simTriggers)
%ATS9462_MULTI_ALINE  一次采集多条 A-line（07 第 1 周 1.4）：硬件触发决定每条的采集时刻，软件只负责接收 DMA buffer。
%
%   mline = ats9462_multi_aline()      真实采集。只能在实验室电脑上运行；运行前先关掉 LabVIEW
%   mline = ats9462_multi_aline(95)    离线模拟：假装收到 95 个触发，不碰硬件，也不存文件。
%                                      用来在家检查"记了几条、哪个 buffer 超时、怎么退出"这些逻辑
%
%   和"软件循环里一条一条采"的区别：
%     这里只调用一次 AlazarBeforeAsyncRead，设好"每条 1024 点、每个 buffer 10 条、一共 100 条"，
%     再预先把 4 个 DMA buffer 交给板卡，然后 AlazarStartCapture。之后每来一个触发，板卡自己记一条，
%     通过 DMA 直接写进内存里的 buffer。程序只是按顺序等每个 buffer 装满、复制出来，再交还给板卡。
%     每条记录在什么时刻开始，完全由触发信号决定，和软件跑得快慢无关。
%     软件循环逐条采集，每条之间都要重新设置、启动、等待；触发来得快时，就会漏掉触发。
%
%   实验室测试（接线同 10/3：发生器 CH1 → 三通 → TRIG IN + 示波器，Imped Load，0→2 V，宽 1 µs）：
%     ① 不发触发：第 1 个 buffer 超时，报告 0 条，正常退出；再运行一次也正常
%     ② CH1 设成 Burst，一次发 100 个（1 kHz）。先运行本程序，看到 "ATS armed" 后再触发发生器
%        → 应得到 100 条。CH2 也接到 CH A 并且和 CH1 一起发的话，每条在同一位置有脉冲；
%        CH2 关着也可以，只看条数
%     ③ Burst 发 95 个 → 90 条完整记录，第 10 个 buffer 超时；这 90 条照样存下来
%   每次测试前改 cfg.note。

    if nargin < 1, simTriggers = []; end
    simulate = ~isempty(simTriggers);

    %% [01] 路径与常量
    here = fileparts(mfilename('fullpath'));
    sdkCandidates = {'C:\AlazarTech\ATS-SDK\23.3.0\Samples_MATLAB\Include', ...            % 实验室电脑
                     fullfile(here, '..', 'ATS-SDK-23.3.0', 'Samples_MATLAB', 'Include')}; % 同步包还原到家里桌面后的位置
    sdkInclude = '';
    for k = 1:numel(sdkCandidates)
        if isfolder(sdkCandidates{k}), sdkInclude = sdkCandidates{k}; break; end
    end
    assert(~isempty(sdkInclude), '找不到 ATS SDK 的 Include 文件夹（里面要有 AlazarDefs.m）。');
    addpath(sdkInclude);
    AlazarDefs;   % 只定义 CHANNEL_A、TRIG_EXTERNAL 这些常量，不碰硬件

    %% [02] 参数：前一半和 ats9462_aline_test_revised.m 一样，后一半是多条采集（DMA）新加的
    cfg = struct();
    cfg.note = '1.4 multi test4: square burst 1000 x 100kHz, 100 rec/buf';  % 每次测试前改成当前设定
    cfg.saveData = ~simulate;                % 模拟时不存文件，免得和真数据混在一起
    cfg.outputFolder = fullfile(here, 'aline_data');
    cfg.systemId = int32(1);
    cfg.boardId  = int32(1);
    cfg.sampleRate_Hz = 180e6;               % 180 MS/s，每点 5.56 ns
    cfg.postTriggerSamples = 1024;           % 每条记录 1024 点 = 5.689 µs（≥ 256 且是 32 的倍数）
    cfg.triggerDelay_samples = 0;            % 采集卡触发延时，单位是采样点，必须是 2 的倍数
    cfg.inputRange_V = 4;                    % ±4 V
    cfg.inputImpedanceId = IMPEDANCE_50_OHM;
    cfg.inputCouplingId  = DC_COUPLING;
    cfg.bandwidthLimit   = 0;                % 0 = 不开约 20 MHz 的低通滤波
    cfg.triggerSourceId  = TRIG_EXTERNAL;    % TRIG IN
    cfg.triggerSlopeId   = TRIGGER_SLOPE_POSITIVE;
    cfg.triggerLevelCode = 150;              % ±5 V 外触发量程下约 0.87 V
    cfg.externalTriggerCouplingId = DC_COUPLING;
    cfg.externalTriggerRangeId    = ETR_5V;
    % ---- 多条采集（DMA）----
    cfg.recordsPerBuffer      = 10;          % 每个 DMA buffer 装 10 条（官方建议：触发频率 / 这个数 < 2 kHz）
    cfg.buffersPerAcquisition = 10;          % 一共 10 个 buffer
    cfg.recordsPerAcquisition = cfg.recordsPerBuffer * cfg.buffersPerAcquisition;   % = 100 条，采满就结束
    cfg.bufferCount = 4;                     % 内存里实际开 4 个 buffer 轮流用（官方示例的做法，至少 3 个）
    cfg.timeout_ms  = 5000;                  % 每个 buffer 最多等 5 s；必须比装满一个 buffer 需要的时间长

    %% [03] 检查参数，并把数值换成 SDK 标识
    switch cfg.sampleRate_Hz
        case 100e6, cfg.sampleRateId = SAMPLE_RATE_100MSPS;
        case 160e6, cfg.sampleRateId = SAMPLE_RATE_160MSPS;
        case 180e6, cfg.sampleRateId = SAMPLE_RATE_180MSPS;
        otherwise,  error('MultiAline:SampleRate', 'Supported: 100, 160 or 180 MS/s.');
    end
    switch cfg.inputRange_V
        case 0.2, cfg.inputRangeId = INPUT_RANGE_PM_200_MV;
        case 0.4, cfg.inputRangeId = INPUT_RANGE_PM_400_MV;
        case 0.8, cfg.inputRangeId = INPUT_RANGE_PM_800_MV;
        case 2,   cfg.inputRangeId = INPUT_RANGE_PM_2_V;
        case 4,   cfg.inputRangeId = INPUT_RANGE_PM_4_V;
        otherwise, error('MultiAline:InputRange', 'Supported: 0.2, 0.4, 0.8, 2, 4 V.');
    end
    assert(cfg.postTriggerSamples >= 256 && mod(cfg.postTriggerSamples, 32) == 0, ...
        'ATS9462: record length must be >= 256 and a multiple of 32.');
    assert(mod(cfg.triggerDelay_samples, 2) == 0, 'ATS9462 (1-2 channels): trigger delay must be a multiple of 2.');
    assert(cfg.bufferCount >= 3, 'Use at least 3 DMA buffers.');

    %% [04] 采集：真实板卡，或者离线模拟
    if simulate
        fprintf('SIMULATION: pretending %d triggers arrive. No hardware is touched.\n', simTriggers);
        [raw, buffersDone, status, msg] = acquireSim(cfg, simTriggers);
    else
        alazarLoadLibrary();
        boardHandle = AlazarGetBoardBySystemID(cfg.systemId, cfg.boardId);
        [~, bitsPerSample] = AlazarGetChannelInfo(boardHandle);
        assert(double(bitsPerSample) == 16, 'Expected the 16-bit ATS9462.');
        configureBoard(boardHandle, cfg);
        [raw, buffersDone, status, msg] = acquireMulti(boardHandle, cfg);
    end

    %% [05] 结果：每一列是一条记录
    S = cfg.postTriggerSamples;
    R = cfg.recordsPerBuffer;
    nRec = size(raw, 2);
    mline = struct();
    mline.raw_u16 = raw;                                               % S × nRec 的原始编码
    mline.volts = (double(raw) / 65535 * 2 - 1) * cfg.inputRange_V;    % 换算成电压，公式同单条 A-line
    mline.time_trigger_s = (cfg.triggerDelay_samples + (0:S-1)') / cfg.sampleRate_Hz;
    mline.recordsRequested = cfg.recordsPerAcquisition;
    mline.recordsCompleted = nRec;
    mline.buffersCompleted = buffersDone;
    mline.status  = status;     % 'complete'：全部采完；'timeout'：某个 buffer 等不满；'error'：其他错误
    mline.message = msg;
    mline.config = cfg;
    mline.simulated = simulate;
    mline.adcRailCount = sum(raw(:) == 0 | raw(:) == 65535);
    mline.hostCompletionTime = datetime('now', 'TimeZone', 'local');

    fprintf('Records: %d of %d (%d of %d buffers). Status: %s.\n', ...
        nRec, cfg.recordsPerAcquisition, buffersDone, cfg.buffersPerAcquisition, status);
    if ~strcmp(status, 'complete')
        k = buffersDone + 1;
        % 第 k 个 buffer 没装满：已经来的触发数在 (k-1)*R 和 k*R-1 之间；不完整的那个 buffer 不要
        fprintf('Buffer %d did not fill (%s): %d to %d triggers arrived; the incomplete buffer is discarded.\n', ...
            k, msg, buffersDone * R, k * R - 1);
    end

    %% [06] 检查：每条记录里有没有脉冲、位置是否一致（用 aline_edge_time）
    mline.edge_us = nan(1, nRec);
    for r = 1:nRec
        v = mline.volts(:, r);
        if max(v) - min(v) > 0.05                       % 有明显的脉冲（> 50 mV）才找边沿
            mline.edge_us(r) = aline_edge_time(v, mline.time_trigger_s) * 1e6;
        end
    end
    nPulse = sum(~isnan(mline.edge_us));
    if nPulse > 0
        e = mline.edge_us(~isnan(mline.edge_us));
        fprintf('Pulse found in %d of %d records: edge mean %.4f us, std %.2f ns, max-min %.2f ns.\n', ...
            nPulse, nRec, mean(e), std(e) * 1e3, (max(e) - min(e)) * 1e3);
    elseif nRec > 0
        fprintf('No pulse on CH A in these records (fine if CH2 was off).\n');
    end

    %% [07] 保存：只要收到了完整的记录就存，包括超时的情况（例如发 95 个触发时的 90 条）
    if cfg.saveData && nRec > 0
        if ~isfolder(cfg.outputFolder), mkdir(cfg.outputFolder); end
        stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
        outputPath = fullfile(cfg.outputFolder, ['maline_' stamp '.mat']);   % maline = multi A-line，和单条的 aline_*.mat 分开
        assert(~isfile(outputPath), 'Output already exists; refusing to overwrite it.');
        mline.savedFile = outputPath;
        save(outputPath, 'mline');
        fprintf('Saved: %s\n', outputPath);
    end

    %% [08] 图：左边是"条号 × 时间"的图（以后 B-scan 就是这种排法），右边是所有记录叠在一起
    if nRec > 0
        fig = figure('Name', 'ATS9462 multi A-line');
        tl = tiledlayout(fig, 1, 2);
        title(tl, sprintf('%d records | %s', nRec, cfg.note), 'Interpreter', 'none');
        ax = nexttile(tl);
        imagesc(ax, 1:nRec, mline.time_trigger_s * 1e6, mline.volts * 1e3); axis(ax, 'xy');
        colorbar(ax); xlabel(ax, 'Record #'); ylabel(ax, 'Time relative to trigger (us)');
        ax = nexttile(tl);
        plot(ax, mline.time_trigger_s * 1e6, mline.volts * 1e3); grid(ax, 'on');
        xlabel(ax, 'Time relative to trigger (us)'); ylabel(ax, 'CH A (mV)'); title(ax, 'all records overlaid');
    end
end

%% [09] 配置板卡：和 ats9462_aline_test_revised.m 完全一样
function configureBoard(boardHandle, cfg)
    AlazarDefs;
    AlazarSetCaptureClock(boardHandle, INTERNAL_CLOCK, cfg.sampleRateId, CLOCK_EDGE_RISING, 0);
    AlazarInputControlEx(boardHandle, CHANNEL_A, cfg.inputCouplingId, cfg.inputRangeId, cfg.inputImpedanceId);
    AlazarSetBWLimit(boardHandle, CHANNEL_A, cfg.bandwidthLimit);
    AlazarSetExternalTrigger(boardHandle, cfg.externalTriggerCouplingId, cfg.externalTriggerRangeId);
    AlazarSetTriggerOperation(boardHandle, TRIG_ENGINE_OP_J, ...
        TRIG_ENGINE_J, cfg.triggerSourceId, cfg.triggerSlopeId, cfg.triggerLevelCode, ...
        TRIG_ENGINE_K, TRIG_DISABLE, TRIGGER_SLOPE_POSITIVE, 128);
    AlazarSetTriggerDelay(boardHandle, cfg.triggerDelay_samples);
    AlazarSetTriggerTimeOut(boardHandle, 0);            % 0 = 一直等硬件触发，不自动触发
    AlazarConfigureAuxIO(boardHandle, AUX_OUT_TRIGGER, 0);
end

%% [10] 真实采集：按官方 ATS9462_NPT.m 的做法，4 个 buffer 轮流用
function [raw, buffersDone, status, msg] = acquireMulti(boardHandle, cfg)
    AlazarDefs;
    S = cfg.postTriggerSamples;            % 每条的点数
    R = cfg.recordsPerBuffer;              % 每个 buffer 的条数
    B = cfg.buffersPerAcquisition;         % 一共要几个 buffer
    K = cfg.bufferCount;                   % 内存里开几个 buffer
    samplesPerBuffer = S * R;              % 只采 CH A 一个通道
    bytesPerBuffer   = 2 * samplesPerBuffer;   % 16 位 = 2 字节

    buffers = cell(1, K);
    for j = 1:K
        buffers{j} = AlazarAllocBuffer(boardHandle, bytesPerBuffer);   % SDK 的 DMA 内存（按页对齐）
    end
    cleanupGuard = onCleanup(@() releaseAll(boardHandle, buffers)); %#ok<NASGU>  正常结束、报错、Ctrl+C 都会清理

    AlazarSetRecordSize(boardHandle, 0, S);                            % 触发前 0 点，触发后 S 点
    AlazarBeforeAsyncRead(boardHandle, CHANNEL_A, 0, S, R, R * B, ...  % 只设一次：一共 R*B 条
        bitor(ADMA_EXTERNAL_STARTCAPTURE, ADMA_NPT));
    for j = 1:K
        AlazarPostAsyncBuffer(boardHandle, buffers{j}, bytesPerBuffer);  % 先把 K 个空 buffer 交给板卡
    end
    AlazarStartCapture(boardHandle);       % 板卡开始等触发；从这里起，每条的时刻只由触发决定
    fprintf('ATS armed. Waiting for %d triggers (%d buffers x %d records; %.1f s timeout per buffer)...\n', ...
        R * B, B, R, cfg.timeout_ms / 1000);

    raw = zeros(S, R * B, 'uint16');
    buffersDone = 0; status = 'complete'; msg = '';
    while buffersDone < B
        j = mod(buffersDone, K) + 1;       % 按顺序轮到第 j 个 buffer：1,2,3,4,1,2,...
        try
            AlazarWaitAsyncBufferComplete(boardHandle, buffers{j}, cfg.timeout_ms);
        catch e
            % 等不满（触发不够或者没来）就停下，前面已经复制出来的记录都保留
            msg = e.message;
            if contains(msg, 'ApiWaitTimeout'), status = 'timeout'; else, status = 'error'; end
            break
        end
        setdatatype(buffers{j}, 'uint16Ptr', 1, samplesPerBuffer);
        % 一个 buffer 里是第 1 条的全部点、第 2 条的全部点……所以 reshape 成 S × R，每一列是一条
        raw(:, buffersDone * R + (1:R)) = reshape(buffers{j}.Value, S, R);
        buffersDone = buffersDone + 1;
        AlazarPostAsyncBuffer(boardHandle, buffers{j}, bytesPerBuffer);  % 复制完再交还给板卡，留给后面的记录用
    end
    raw = raw(:, 1:buffersDone * R);       % 只留装满了的 buffer
end

%% [11] 清理：先中止 DMA，再释放内存（中止失败时不释放，免得板卡还往里写）
function releaseAll(boardHandle, buffers)
    try
        AlazarAbortAsyncRead(boardHandle);
    catch e
        warning('MultiAline:AbortFailed', 'DMA abort failed; buffers were NOT freed. Restart MATLAB before retrying. %s', e.message);
        return
    end
    for j = 1:numel(buffers)
        try
            AlazarFreeBuffer(boardHandle, buffers{j});
        catch e
            warning('MultiAline:FreeFailed', 'DMA buffer %d release failed: %s', j, e.message);
        end
    end
end

%% [12] 离线模拟：不碰硬件。只模拟"触发来了几个、装满了几个 buffer"，用来检查上面的记账和退出逻辑
function [raw, buffersDone, status, msg] = acquireSim(cfg, nTriggers)
    S = cfg.postTriggerSamples; R = cfg.recordsPerBuffer; B = cfg.buffersPerAcquisition;
    fs = cfg.sampleRate_Hz;
    t = (cfg.triggerDelay_samples + (0:S-1)') / fs;
    rng(1);                                            % 每次模拟结果一样
    nRec = min(nTriggers, R * B);                      % 超过 R*B 的触发会被忽略（采集已经结束）
    buffersDone = floor(nRec / R);                     % 只有装满的 buffer 才会交回来
    raw = zeros(S, buffersDone * R, 'uint16');
    rise = 15e-9;                                      % 上升沿约 15 ns（10/3 实测：约 3 个采样点）
    for r = 1:buffersDone * R
        t0 = 1e-6 + rand / fs;                         % 脉冲在 1 µs 附近，每条随机错开不到一个采样点（触发和采样时钟不同步）
        v = max(0, min(1, (t - t0) / rise)) .* (t < t0 + 0.2e-6) + 1e-3 * randn(S, 1);   % 0→1 V、宽 0.2 µs，加 1 mV 噪声
        raw(:, r) = uint16(min(max(round((v / cfg.inputRange_V + 1) * 65535 / 2), 0), 65535));
    end
    if buffersDone < B
        status = 'timeout'; msg = 'SIMULATED ApiWaitTimeout (579)';
    else
        status = 'complete'; msg = '';
    end
end
