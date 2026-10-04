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
addpath('..\..\..\Include')


%%%%%%%%%%
%% MAIN %%
%%%%%%%%%%

% Call mfile with library definitions
AlazarDefs

% Load driver library
alazarLoadLibrary()

% TODO: Select a board.
% This sample program is designed for single board use. If there are more
% than one board installed, user should use Multi_system sample programs.
systemId = int32(1);
boardId = int32(1);

% Get a handle to the board
boardHandle = AlazarGetBoardBySystemID(systemId, boardId);

% Configure the board's sample rate, input, and trigger settings
configureBoard(boardHandle)

% Acquire data, optionally saving it to a file
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

    AlazarSetCaptureClock(boardHandle, ...
                          INTERNAL_CLOCK, ...
                          SAMPLE_RATE_180MSPS, ...
                          CLOCK_EDGE_RISING, ...
                          0);
    % TODO: Select channel A input parameters as required.
    AlazarInputControlEx(boardHandle, ...
                         CHANNEL_A, ...
                         DC_COUPLING, ...
                         INPUT_RANGE_PM_400_MV, ...
                         IMPEDANCE_50_OHM);
    % TODO: Select channel A bandwidth limit as required
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

    AlazarSetExternalTrigger(boardHandle, ... % HANDLE -- board handle
            DC_COUPLING, ... % U32 -- external trigger coupling id
            ETR_5V);

    % TODO: Set trigger delay as required. Set the time, in sample clocks, to 
    % wait after receiving a trigger event before capturing a record for the trigger.
    %
    % NOTE: The trigger delay has a board-specific alignment requirement. 
    % Please review the Board-Specific information section of the ATS-SDK guide
    % (https://docs.alazartech.com/ats-sdk-user-guide/latest/board-specific-info.html).

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

    AlazarSetTriggerTimeOut(boardHandle, ...
                            0);

    % TODO: Configure AUX I/O connector as required. This sample program configures the 
    % AUX I/O to be a trigger output. AUX I/O can also be configured as a frame trigger
    % (AUX_IN_TRIGGER_ENABLE) for imaging applications. Refer to ATS-SDK manual
    % (https://docs.alazartech.com/ats-sdk-user-guide/latest/reference/AlazarConfigureAuxIO.html)

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
    preTriggerSamples = 0;

    % TODO: Select the number of post-trigger samples per record. The sum of 
    % pre and post must be a multiple of the record size resolution specified in:
    % https://docs.alazartech.com/ats-sdk-user-guide/latest/board-specific-info.html
    postTriggerSamples = 2048;

    % TODO: Specify the number of records per DMA buffer. recordsPerBuffer should be 
    % high enough so that the number of acquired DMA buffers per second 
    % (trigger rate / recordsPerBuffer) be less than 2kHz. Above this rate, operating 
    % system might loose the end of DMA interrupt. Buffer size should not be too high 
    % to avoid ApiInsufficient errors caused by the operating system. For very large 
    % buffers, refer to our *_VLB sample programs.
    recordsPerBuffer = 10;

    % TODO: Specify the total number of buffers to capture. The total number of 
    % acquired records will be equal to buffersPerAcquisition * recordsPerBuffer.
    buffersPerAcquisition = 10;
    

    % TODO: Select which channels to capture (A, B, or both). Channels to capture 
    % should be combined using a bitwise OR.
    channelMask = CHANNEL_A;

    % TODO: Select if you wish to save the sample data to a file. Saving data will 
    % increase the buffer consumption time based on the system writing to disk speed 
    % and might cause a buffer overflow.
    saveData = false;

    % TODO: Select if you wish to plot the data to a chart
    drawData = false;

    % Calculate the number of enabled channels from the channel mask
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
    [~, bitsPerSample] = AlazarGetChannelInfo(boardHandle);

    % Calculate the size of each buffer in bytes
    bytesPerSample = floor((double(bitsPerSample) + 7) / double(8));
    samplesPerRecord = preTriggerSamples + postTriggerSamples;
    samplesPerBuffer = samplesPerRecord * recordsPerBuffer * channelCount;
    bytesPerBuffer = bytesPerSample * samplesPerBuffer;

    % TODO: Select the number of DMA buffers to allocate.
    % The number of DMA buffers must be greater than 2 to allow a board to DMA into
    % one buffer while, at the same time, your application processes another buffer.
    bufferCount = uint32(4);

    % Create an array of DMA buffers using an Alazar API, which internally uses virtual alloc. It
    % is essential for DMA buffers to be page aligned.
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
    AlazarSetRecordSize(boardHandle, preTriggerSamples, postTriggerSamples);

    % TODO: Select AutoDMA flags as required
    admaFlags = ADMA_EXTERNAL_STARTCAPTURE + ADMA_NPT;

    % Configure the board to make an AutoDMA acquisition
    recordsPerAcquisition = recordsPerBuffer * buffersPerAcquisition;
    AlazarBeforeAsyncRead(boardHandle, channelMask, -int32(preTriggerSamples), samplesPerRecord, recordsPerBuffer, recordsPerAcquisition, admaFlags);

    % Post the buffers to the board
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
            timeout_ms = 5000;
            
            % Wait for the buffer at the head of the list of available
            % buffers to be filled by the board.
            bufferIndex = mod(buffersCompleted, bufferCount) + 1;
            pbuffer = buffers{1, bufferIndex};
            
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

            % Display the buffer on screen
            if drawData
                plot(pbuffer.Value);
            end

            % Make the buffer available to be filled again by the board
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
    AlazarAbortAsyncRead(boardHandle);

    % Close the data file
    if fid ~= -1
        fclose(fid);
    end

    % Release the buffers
    for bufferIndex = 1:bufferCount
        pbuffer = buffers{1, bufferIndex};
        AlazarFreeBuffer(boardHandle, pbuffer);
        clear pbuffer;
    end

    % Display results
    if buffersCompleted > 0
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