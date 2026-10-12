%% Plot the voltage waveform in a selected time interval from one row.
% Edit rowNumber, intervalStartSec, and intervalEndSec below.

clear;
clc;

% DATA_ts is alongside this script's parent project folder.
projectFolder = fileparts(fileparts(mfilename('fullpath')));
dataFolder = fullfile(projectFolder, 'control_py\PA_data\scan_20261003_171607');
rowNumber = 1;

% Plot this interval, in seconds from the row trigger.
intervalStartSec = 0.26;          % start time (s)
intervalEndSec = 0.28;            % end time (s), e.g. 0.001 = 1 ms

% Acquisition settings from TS_aq2.py.
sampleRate = 180e6;                % samples/second
inputFullScaleVolts = 0.2;         % channel input range is +/- 200 mV

if intervalStartSec < 0 || intervalEndSec <= intervalStartSec
    error('Set intervalEndSec greater than intervalStartSec, both >= 0.');
end

fileName = fullfile(dataFolder, sprintf('row_%05d.bin', rowNumber));
if ~isfile(fileName)
    error('Row file not found: %s', fileName);
end

fileInfo = dir(fileName);
if mod(fileInfo.bytes, 2) ~= 0
    error('File size (%d bytes) is not even; expected uint16 sample data.', fileInfo.bytes);
end
sampleCount = fileInfo.bytes / 2;
recordDurationSec = sampleCount / sampleRate;

if intervalStartSec >= recordDurationSec
    error('Interval starts after this row ends (row duration %.6f s).', recordDurationSec);
end
intervalEndSec = min(intervalEndSec, recordDurationSec);

% Map the file and read only the requested interval into memory.
mappedFile = memmapfile(fileName, ...
    'Format', {'uint16', [sampleCount, 1], 'samples'}, ...
    'Writable', false);
samples = mappedFile.Data(1).samples;
firstSample = floor(intervalStartSec * sampleRate) + 1;
lastSample = min(sampleCount, ceil(intervalEndSec * sampleRate));
raw = single(samples(firstSample:lastSample));

% Convert unsigned 16-bit ADC codes to volts for a +/- 200 mV input range.
voltage = (raw - 32768) / 32768 * inputFullScaleVolts;
sampleNumber = (firstSample:lastSample)';

figure('Color', 'w');
plot(sampleNumber, voltage, '-');
grid on;
xlabel('Sample number from row trigger');
ylabel('Voltage (V)');
title(sprintf('Row %d voltage, samples %d to %d', ...
    rowNumber, firstSample, lastSample));

fprintf('Row %d: plotted samples %d to %d (%d samples).\n', ...
    rowNumber, firstSample, lastSample, numel(raw));
fprintf('Selected interval: %.6g to %.6g s.\n', intervalStartSec, intervalEndSec);
