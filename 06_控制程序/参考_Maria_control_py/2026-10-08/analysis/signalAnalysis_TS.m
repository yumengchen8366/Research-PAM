%% Plot the voltage waveform for a selected range of samples from one row.
% Edit rowNumber, startSample, and numSamplesToPlot below.

clear;
clc;

% DATA_ts is alongside this script's parent project folder.
projectFolder = fileparts(fileparts(mfilename('fullpath')));
dataFolder = fullfile(projectFolder, 'data\kk');
rowNumber = 16;

% Plot this many samples, starting at startSample (1 = first sample after the row trigger).
startSample =  53900000;                   % first sample to plot (1-based)
numSamplesToPlot = 54000000;          % number of samples to plot

% Acquisition settings from TS_aq2.py.
sampleRate = 180e6;                % samples/second
inputFullScaleVolts = 0.2;         % channel input range is +/- 200 mV

if startSample < 1 || numSamplesToPlot < 1 || ...
        startSample ~= floor(startSample) || numSamplesToPlot ~= floor(numSamplesToPlot)
    error('Set startSample and numSamplesToPlot to positive integers.');
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

if startSample > sampleCount
    error('startSample %d is past the end of this row (%d samples).', startSample, sampleCount);
end

% Map the file and read only the requested samples into memory.
mappedFile = memmapfile(fileName, ...
    'Format', {'uint16', [sampleCount, 1], 'samples'}, ...
    'Writable', false);
samples = mappedFile.Data(1).samples;
firstSample = startSample;
lastSample = min(sampleCount, startSample + numSamplesToPlot - 1);
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
fprintf('Row length: %d samples (%.6g s).\n', sampleCount, recordDurationSec);
