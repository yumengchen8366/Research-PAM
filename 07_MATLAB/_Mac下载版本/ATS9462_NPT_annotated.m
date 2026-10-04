% 中文学习版：基于用户上传的 ATS-SDK 23.3.0 ATS9462_NPT.m。
% 保留原作者许可、全部可执行语句和厂家默认参数；尚未改成实验配置。
% 此脚本实际运行时会配置硬件并采集，不是前面 pam_aline_start 的模拟模式。
% 当前默认：内部180 MS/s；CHA；DC；±0.4V；50Ω；CHA正向触发编码150；
% 延迟0；每条2048点；每buffer10条；总共10个buffer即100条；4个循环buffer；
% 保存和绘图均关闭；AUX被设置为触发输出，不是DAQ enable输入。
% 待核对：实际信号线/触发线/AUX门控、MATLAB版本、运行时量程/阻抗/长度/延迟。
% 厂商在线板卡表目前列出ATS9462记录长度最小256、步进32；不能直接把旧VI显示的64点
% 当作原生DMA记录长度。最终应结合本机SDK23.3.0/驱动文档确认。
% 参考：https://docs.alazartech.com/ats-sdk-user-guide/latest/board-specific-info.html
% 阅读顺序：MAIN -> configureBoard -> acquireData -> 等待/处理/归还 -> 清理。
% 本版添加中文注释和注释形式的A-line绘图代码；未做MATLAB/硬件运行验证。
% 建议放回原 NPT 示例所在目录阅读；原相对Include路径依赖MATLAB当前工作目录。
% 如果从别的位置运行，应先核实Include路径，不能只移动这个文件就假定依赖齐全。
% -------------------------------------------------------------------------

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
%
% This sample configures an ATS9462 to make a simple NPT mode
% (No Pre-Trigger) AutoDMA acquisition, optionally saving the data to file 
% and displaying it on screen.
%

% Add path to AlazarTech mfiles
% 【依赖】添加SDK的Include函数目录。此相对路径以MATLAB当前工作目录为依据。
% 你的已知安装路径：C:\AlazarTech\ATS-SDK\23.3.0\Samples_MATLAB\Include
% 不要把不同版本的Include函数混用。
addpath('..\..\..\Include')


%%%%%%%%%%
%% MAIN %%
%%%%%%%%%%

% Call mfile with library definitions
% 【常量】加载CHANNEL_A、SAMPLE_RATE_180MSPS等枚举常量。
% 枚举编码与物理单位不同；采样率标识符本身不一定等于180000000。
AlazarDefs

% Load driver library
% 【驱动】加载厂商驱动库；有PDF手册不等于此接口可以成功加载。
alazarLoadLibrary()

% TODO: Select a board.
% This sample program is designed for single board use. If there are more
% than one board installed, user should use Multi_system sample programs.
% 【设备选择】使用第1个系统、第1块板卡。不是LabVIEW DeviceIn=0的直接翻译。
systemId = int32(1);
boardId = int32(1);

% Get a handle to the board
% 【句柄】返回后续API操作这块板卡所需的标识；不是采样数据。
boardHandle = AlazarGetBoardBySystemID(systemId, boardId);

% Configure the board's sample rate, input, and trigger settings
% 【阶段1】配置采样时钟、模拟输入、触发、延迟和AUX功能。
configureBoard(boardHandle)

% Acquire data, optionally saving it to a file
% 【阶段2】准备DMA缓冲，启动、等待、读取、清理。函数目前没有结果返回值。
acquireData(boardHandle)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Configure board function %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function configureBoard(boardHandle)
    % Configure sample rate, input, and trigger settings

    % Call mfile with library definitions
    AlazarDefs

    % TODO: Select clock parameters as required to generate this sample rate.
    %
    % For example:
    % - For internal clocking, if sample rate is 100.e6 (100 MS/s), then: select 
    % clock source INTERNAL_CLOCK and sample rate SAMPLE_RATE_100MSPS
    %
    % - For external clocking, where the sampling speed is the same as external 
    % clock frequency [K-clock] select clock source FAST_EXTERNAL_CLOCK, sample 
    % rate SAMPLE_RATE_USER_DEF, and connect the external clock signal to the 
    % EXT CLK BNC connector.
    %
    % - For locking the digitizer clock to an external 10 MHz reference clock, 
    % select clock source EXTERNAL_CLOCK_10MHZ_REF, pass the value of the sample 
    % clock to generate in Hertz (for example 100000000 for 100 MS/s), and connect 
    % the 10 MHz external clock signal to the EXT CLK BNC connector.

    % 【ADC时钟】厂家例程选内部180 MS/s，不是截图中的160 MS/s。
    % dt=1/180e6=5.555...ns；不要把DO/laser/motor频率填到这里。
    % 最后一个参数0是本例程传给SDK的decimation参数，不能解释为采样率乘0。
    AlazarSetCaptureClock(boardHandle, ...
                          INTERNAL_CLOCK, ...
                          SAMPLE_RATE_180MSPS, ...
                          CLOCK_EDGE_RISING, ...
                          0);
    % TODO: Select channel A input parameters as required.
    % 【模拟输入】配置该通道的耦合、正负量程和阻抗。
    % 当前±400mV、50Ω是厂家演示设置，不代表已适配你的放大器。
    AlazarInputControlEx(boardHandle, ...
                         CHANNEL_A, ...
                         DC_COUPLING, ...
                         INPUT_RANGE_PM_400_MV, ...
                         IMPEDANCE_50_OHM);
    % TODO: Select channel A bandwidth limit as required
    % 【带宽】0表示本示例不启用该带宽限制。
    AlazarSetBWLimit(boardHandle, ...
                     CHANNEL_A, ...
                     0);
    
    % TODO: Select channel B input parameters as required.
    AlazarInputControlEx(boardHandle, ...
                         CHANNEL_B, ...
                         DC_COUPLING, ...
                         INPUT_RANGE_PM_400_MV, ...
                         IMPEDANCE_50_OHM);
    % TODO: Select channel B bandwidth limit as required
    AlazarSetBWLimit(boardHandle, ...
                     CHANNEL_B, ...
                     0);
    
    % TODO: Select trigger inputs and levels as required. In this example program, the 
    % board is setup to trigger on CHA positive slope, at +17% trigger level. The input 
    % signal amplitude must be at least 30% of the full scale for the board to trigger. 
    % If no signal is supplied, the board will not trigger and acquisition will timeout.

    % 【真正的触发源】此处为TRIG_CHAN_A，正向过阈值触发，编码150。
    % 即使后面配置了外部触发口，本行仍使板卡等待CHA触发，不是External。
    % J引擎启用；K引擎的源为TRIG_DISABLE。阈值编码不是V或mV。
    AlazarSetTriggerOperation(boardHandle, ...
            TRIG_ENGINE_OP_J, ...
            TRIG_ENGINE_J, ...
            TRIG_CHAN_A, ...
            TRIGGER_SLOPE_POSITIVE, ...
            150, ...
            TRIG_ENGINE_K, ...
            TRIG_DISABLE, ...
            TRIGGER_SLOPE_POSITIVE, ...
            128);

    % TODO: Select external trigger parameters as required. 
    % AlazarSetExternalTrigger has no effect unless AlazarSetTriggerOperation 
    % is configured with TRIG_EXTERNAL as Source.

    % 【外部触发端口属性】设置DC耦合和5V档，不会生成5V输出。
    % 只有触发源选择TRIG_EXTERNAL时，该端口设置才参与对应触发。
    % 与LabVIEW Ext Trig显示的AC耦合不同，须核对实际触发信号。
    AlazarSetExternalTrigger(boardHandle, ... % HANDLE -- board handle
            DC_COUPLING, ... % U32 -- external trigger coupling id
            ETR_5V);

    % TODO: Set trigger delay as required. Set the time, in sample clocks, to 
    % wait after receiving a trigger event before capturing a record for the trigger.
    %
    % NOTE: The trigger delay has a board-specific alignment requirement. 
    % Please review the Board-Specific information section of the ATS-SDK guide
    % (https://docs.alazartech.com/ats-sdk-user-guide/latest/board-specific-info.html).

    % 【延迟单位：采样点】这里是0点，不是此前截图中的6.5us。
    % 例如160 MS/s、6.5us -> 1040点；还需符合板卡的延迟对齐要求。
    % 延迟相对电子触发事件，不自动等于激光发光的时间参考。
    triggerDelay_samples = 0;
    AlazarSetTriggerDelay(boardHandle, triggerDelay_samples);

    % TODO: Set trigger timeout as required.
    %
    % NOTE: The board will wait for this amount of time for a
    % trigger event.  If a trigger event does not arrive, then the
    % board will automatically trigger. Set the trigger timeout value
    % to 0 to force the board to wait forever for a trigger event.
    %
    % IMPORTANT: The trigger timeout value should be set to zero after
    % appropriate trigger parameters have been determined, otherwise
    % the board may trigger if the timeout interval expires before a
    % hardware trigger event arrives.

    % 【硬件自动触发超时】此处0表示不因等待超时而自动制造触发。
    % 它不同于后面的timeout_ms=5000（软件等待DMA buffer完成的上限）。
    AlazarSetTriggerTimeOut(boardHandle, ...
                            0);

    % TODO: Configure AUX I/O connector as required. This sample program configures the 
    % AUX I/O to be a trigger output. AUX I/O can also be configured as a frame trigger
    % (AUX_IN_TRIGGER_ENABLE) for imaging applications. Refer to ATS-SDK manual
    % (https://docs.alazartech.com/ats-sdk-user-guide/latest/reference/AlazarConfigureAuxIO.html)

    % 【AUX方向】原例程把AUX设为触发输出。
    % 这不是读取DAQ enable的配置；若现有系统依赖门控，必须先查接线和模式。
    % 本示例没有NI DO、激光或电机控制代码。
    AlazarConfigureAuxIO(boardHandle, ...
                         AUX_OUT_TRIGGER, ...
                         0);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Acquire data function %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

function acquireData(boardHandle)
    % Make an AutoDMA acquisition from dual-ported memory.

    % Call mfile with library definitions
    AlazarDefs
    % NPT mode can only have a limited number of pre-trigger samples. Please 
    % Refer to ATS-SDK manual for maximum number of pre-trigger samples and 
    % pre-trigger alignment (TBD).
    % (https://docs.alazartech.com/ats-sdk-user-guide/latest/board-specific-info.html)
    % 【记录结构】本示例NPT使用0个预触发点。
    preTriggerSamples = 0;

    % TODO: Select the number of post-trigger samples per record. The sum of 
    % pre and post must be a multiple of the record size resolution specified in:
    % https://docs.alazartech.com/ats-sdk-user-guide/latest/board-specific-info.html
    % 【每条记录】2048点，记录长度须满足实际板卡/SDK要求。
    % N/Fs=2048/180e6=11.377777...us。
    % 图上首末采样点跨度是(N-1)/Fs，两者相差一个采样间隔。
    postTriggerSamples = 2048;

    % TODO: Specify the number of records per DMA buffer. recordsPerBuffer should be 
    % high enough so that the number of acquired DMA buffers per second 
    % (trigger rate / recordsPerBuffer) be less than 2kHz. Above this rate, operating 
    % system might loose the end of DMA interrupt. Buffer size should not be too high 
    % to avoid ApiInsufficient errors caused by the operating system. For very large 
    % buffers, refer to our *_VLB sample programs.
    % 【一包数据】一个DMA buffer装10条记录，不是10个ADC点。
    % 触发不足10次时，这一包可能无法填满，最终产生等待超时。
    recordsPerBuffer = 10;

    % TODO: Specify the total number of buffers to capture. The total number of 
    % acquired records will be equal to buffersPerAcquisition * recordsPerBuffer.
    % 【采集总量】总共完成10包；10条/包×10包=100条记录。
    % 不是一次只采一条A-line；“10个完成的buffer”也不代表分配10块内存。
    buffersPerAcquisition = 10;
    

    % TODO: Select which channels to capture (A, B, or both). Channels to capture 
    % should be combined using a bitwise OR.
    % 【实际采集通道】只采A。前面虽然也配置了B，但此处并未选中B。
    % 双通道涉及额外的数据排列，不要直接照单通道reshape。
    channelMask = CHANNEL_A;

    % TODO: Select if you wish to save the sample data to a file. Saving data will 
    % increase the buffer consumption time based on the system writing to disk speed 
    % and might cause a buffer overflow.
    % 【保存】默认不保存。打开后写当前目录的data.bin；原例程模式会覆盖同名文件。
    % 它保存原始ADC码，不包含完整实验配置，不等于带时间轴的MAT文件。
    saveData = false;

    % TODO: Select if you wish to plot the data to a chart
    % 【显示】默认不画图。原例程打开后画整包原始ADC码，没有电压/时间标定。
    % 下方提供注释形式的单条A-line绘图插入代码。
    drawData = false;

    % Calculate the number of enabled channels from the channel mask
    % 【位掩码】A对应位1，B对应位2；循环检查哪些通道被选中。
    % 当前CHANNEL_A -> channelCount=1。
    channelCount = 0;
    channelsPerBoard = 2;
    for channel = 0:channelsPerBoard - 1
        channelId = 2^channel;
        if bitand(channelId, channelMask)
            channelCount = channelCount + 1;
        end
    end

    if (channelCount < 1) || (channelCount > channelsPerBoard)
        fprintf('Error: Invalid channel mask %08X\n', channelMask);
        return
    end

    % Get the sample and memory size
    % 【硬件查询】查询ADC位数；波形的存储容器宽度与有效ADC位数要区分。
    [~, bitsPerSample] = AlazarGetChannelInfo(boardHandle);

    % Calculate the size of each buffer in bytes
    % 【内存计算】向上取整(bit数/8)，得到每个采样值占多少字节。
    % 本例若为2字节/点：
    % samplesPerRecord=0+2048=2048
    % samplesPerBuffer=2048×10×1=20480
    % bytesPerBuffer=20480×2=40960 bytes
    % 完成10包 -> 409600 bytes纯采样数据，不含元信息。
    bytesPerSample = floor((double(bitsPerSample) + 7) / double(8));
    samplesPerRecord = preTriggerSamples + postTriggerSamples;
    samplesPerBuffer = samplesPerRecord * recordsPerBuffer * channelCount;
    bytesPerBuffer = bytesPerSample * samplesPerBuffer;

    % TODO: Select the number of DMA buffers to allocate.
    % The number of DMA buffers must be greater than 2 to allow a board to DMA into
    % one buffer while, at the same time, your application processes another buffer.
    % 【循环缓冲】分配4块内存，按1、2、3、4、1、2...循环复用。
    % 它与buffersPerAcquisition=10是两个不同概念。
    % 在上述2字节/点条件下，4块共4×40960=163840 bytes。
    bufferCount = uint32(4);

    % Create an array of DMA buffers using an Alazar API, which internally uses virtual alloc. It
    % is essential for DMA buffers to be page aligned.
    % 【分配】使用厂商函数分配满足DMA对齐要求的内存，cell里存放指针。
    % pbuffer是指向内存的对象，pbuffer.Value才是其中的采样数据。
    buffers = cell(1, bufferCount);
    for j = 1 : bufferCount
        pbuffer = AlazarAllocBuffer(boardHandle, bytesPerBuffer);
        buffers(1, j) = { pbuffer };
    end

    % Create a data file if required
    fid = -1;
    if saveData
        fid = fopen('data.bin', 'w');
        if fid == -1
            fprintf('Error: Unable to create data file\n');
        end
    end
    % Configure the record size. preTriggerSamples should be equal to -transferOffset 
    % passed to AlazarBeforeAsyncRead. preTriggerSamples + postTriggerSamples 
    % should be equal to transferLength passed to AlazarBeforeAsyncRead.
    % 【记录长度生效】告诉板卡每条记录的预触发/后触发点数。
    AlazarSetRecordSize(boardHandle, preTriggerSamples, postTriggerSamples);

    % TODO: Select AutoDMA flags as required
    % 【DMA模式】ADMA_NPT选择NPT采集。
    % ADMA_EXTERNAL_STARTCAPTURE要求应用随后调用AlazarStartCapture启动。
    % 名称里的EXTERNAL不表示触发来自External Trigger接口！
    admaFlags = ADMA_EXTERNAL_STARTCAPTURE + ADMA_NPT;

    % Configure the board to make an AutoDMA acquisition
    % 【总记录数】10×10=100。下面BeforeAsyncRead设置整个DMA采集任务。
    recordsPerAcquisition = recordsPerBuffer * buffersPerAcquisition;
    AlazarBeforeAsyncRead(boardHandle, channelMask, -int32(preTriggerSamples), samplesPerRecord, recordsPerBuffer, recordsPerAcquisition, admaFlags);

    % Post the buffers to the board
    % 【预先投递】把可用内存交给驱动，准备接收后续数据。
    for bufferIndex = 1 : bufferCount
        pbuffer = buffers{1, bufferIndex};
        AlazarPostAsyncBuffer(boardHandle, pbuffer, bytesPerBuffer);
    end

    % Update status
    if buffersPerAcquisition == hex2dec('7FFFFFFF')
        fprintf('Capturing buffers until aborted...\n');
    else
        fprintf('Capturing %u buffers ...\n', buffersPerAcquisition);
    end

    
    % Arm the board system to wait for a trigger event to begin the acquisition. All board
    % configuration functions should be called before calling AlazarStartCapture.
    % 【启动/布防】板卡开始等待满足条件的触发；此调用不会让激光自动发光。
    AlazarStartCapture(boardHandle);

    % Create a progress window
    waitbarHandle = waitbar(0, ...
                            'Captured 0 buffers', ...
                            'Name','Capturing ...', ...
                            'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
    setappdata(waitbarHandle, 'canceling', 0);

    % Wait for sufficient data to arrive to fill a buffer, process the buffer,
    % and repeat until the acquisition is complete
    startTickCount = tic;
    updateTickCount = tic;
    updateInterval_sec = 0.1;
    buffersCompleted = 0;
    captureDone = false;

    while ~captureDone
        try
            
            % TODO: Set a buffer timeout that is longer than the time required to capture all
            % the records in one buffer. If all triggers for a buffer do not occur within the
            % timeout period, an ApiWaitTimeout error will be returned. This error does not
            % mean a hardware or software failure. It rather indicates that the trigger is
            % slower than expected or not occuring. Please verify trigger or increase timeout
            % value.
            % 【软件等待上限】最多等待5000ms=5s，等待的是整包记录填满。
            % 这不是ADC时长、激光周期或电机周期。
            timeout_ms = 5000;
            
            % Wait for the buffer at the head of the list of available
            % buffers to be filled by the board.
            % 【循环下标】completed=0,1,2,3,4... -> index=1,2,3,4,1...
            % MATLAB从1开始索引，因此余数之后要加1。
            bufferIndex = mod(buffersCompleted, bufferCount) + 1;
            pbuffer = buffers{1, bufferIndex};
            
            % 【阻塞等待】仅当这包数据采集完成后，才进入下面处理。
            % 无触发/触发数量不足都可能导致超时，而不是返回一条有效零波形。
            AlazarWaitAsyncBufferComplete(boardHandle, pbuffer, timeout_ms);

            % TODO: Process sample data in this buffer.
            %
            % NOTE:
            %
            % While you are processing this buffer, the board is already
            % filling the next available buffer(s).
            %
            % You MUST finish processing this buffer and post it back to the
            % board before the board fills all of its available DMA buffers
            % and on-board memory.
            %
            % Records are arranged in the buffer as follows: R0A, R1A, R2A ... RnA, R0B,
            % R1B, R2B ...
            % with RXY the record number X of channel Y
            %
            %
            % Sample codes are unsigned by default. As a result:
            % - a sample code of 0x0000 represents a negative full scale input signal.
            % - a sample code of 0x8000 represents a ~0V signal.
            % - a sample code of 0xFFFF represents a positive full scale input signal.

            if bytesPerSample == 1
                setdatatype(pbuffer, 'uint8Ptr', 1, samplesPerBuffer);
            else
                % 【解释内存】让MATLAB按uint16数组读取指针中的数据。
                % 这一步不是电压换算。当前数组包含10条连续存储的A通道记录。
                setdatatype(pbuffer, 'uint16Ptr', 1, samplesPerBuffer);
            end

            % Save the buffer to file
            if fid ~= -1
                if bytesPerSample == 1
                    samplesWritten = fwrite(fid, pbuffer.Value, 'uint8');
                else
                    samplesWritten = fwrite(fid, pbuffer.Value, 'uint16');
                end
                if samplesWritten ~= samplesPerBuffer
                    fprintf('Error: Write buffer %u failed\n', buffersCompleted);
                end
            end

            % 【以后添加A-line绘图的位置】此时必须在重新Post该buffer之前复制数据。
            % 下列全为注释，不会执行；只适用于当前单通道A、2字节无符号码配置。
            % fs_Hz = 180e6;        % 必须与上面的真实时钟配置一致
            % range_V = 0.4;       % 必须与A通道的真实正负量程一致
            % rawCopy = pbuffer.Value;
            % records = reshape(rawCopy, samplesPerRecord, recordsPerBuffer);
            % rawAline = records(:,1);  % 第1列就是这一包的第1条记录
            % voltage_V = double(rawAline)/65535*(2*range_V)-range_V;
            % time_s = (0:samplesPerRecord-1)'/fs_Hz;
            % plot(time_s*1e6, voltage_V*1e3);
            % xlabel('Time from record start (us)'); ylabel('Voltage (mV)');
            % grid on; drawnow;
            % 时间零点为记录起点；真实触发延迟/光声飞行时间还需独立确认。
            % 这里的换算复现已提供的LabVIEW公式；必须确认位格式和量程一致。
            % 在本例程的每包处理处画图只显示每包第1条，不等于只采了1条。
            % 若要保存第一条，需连同fs_Hz、range、trigger等元信息传出函数。

            % Display the buffer on screen
            if drawData
                plot(pbuffer.Value);
            end

            % Make the buffer available to be filled again by the board
            % 【归还内存】再次交给驱动复用；之后不能假定指针内旧数据仍保持不变。
            AlazarPostAsyncBuffer(boardHandle, pbuffer, bytesPerBuffer);

            % Update progress
            buffersCompleted = buffersCompleted + 1;
            if buffersCompleted >= buffersPerAcquisition
                captureDone = true;
            elseif toc(updateTickCount) > updateInterval_sec
                updateTickCount = tic;

                % Update waitbar progress
                waitbar(double(buffersCompleted) / double(buffersPerAcquisition), ...
                        waitbarHandle, ...
                        sprintf('Completed %u buffers', buffersCompleted));

                % Check if waitbar cancel button was pressed
                if getappdata(waitbarHandle,'canceling')
                    break
                end
            end
        % 【异常处理范围】原例程只在循环内catch；前面的分配/启动错误不在此范围。
        % 后续正式版本应通过onCleanup等方式覆盖所有退出路径。
        catch ME
            fprintf("%s:%s\n", ME.identifier, ME.message);
            captureDone = true;
        end
    end % while ~captureDone

    % Save the transfer time
    transferTime_sec = toc(startTickCount);

    % Close progress window
    delete(waitbarHandle);

    % Abort the acquisition
    % 【停止DMA】应先停止异步读，再释放仍可能被硬件使用的缓冲区。
    AlazarAbortAsyncRead(boardHandle);

    % Close the data file
    if fid ~= -1
        fclose(fid);
    end

    % Release the buffers
    % 【释放内存】释放已分配的4块DMA缓冲。此处不是清空原始实验文件。
    for bufferIndex = 1:bufferCount
        pbuffer = buffers{1, bufferIndex};
        AlazarFreeBuffer(boardHandle, pbuffer);
        clear pbuffer;
    end

    % Display results
    if buffersCompleted > 0
        % 【统计】字节数=完成包数×每包字节数；记录数=每包记录数×完成包数。
        % recordsPerSec是整段程序测得的平均记录吞吐率，包括等待/处理开销，
        % 不能直接当作独立测量的激光频率、触发频率或ADC采样率。
        bytesTransferred = double(buffersCompleted) * double(bytesPerBuffer);
        recordsTransferred = recordsPerBuffer * buffersCompleted;

        if transferTime_sec > 0
            buffersPerSec = buffersCompleted / transferTime_sec;
            bytesPerSec = bytesTransferred / transferTime_sec;
            recordsPerSec = recordsTransferred / transferTime_sec;
        else
            buffersPerSec = 0;
            bytesPerSec = 0;
            recordsPerSec = 0.;
        end

        fprintf('Captured %u buffers in %g sec (%g buffers per sec)\n', buffersCompleted, transferTime_sec, buffersPerSec);
        fprintf('Captured %u records (%.4g records per sec)\n', recordsTransferred, recordsPerSec);
        fprintf('Transferred %u bytes (%.4g bytes per sec)\n', bytesTransferred, bytesPerSec);
    end
end