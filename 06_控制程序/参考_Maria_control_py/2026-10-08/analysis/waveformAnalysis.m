% Replace these with your six waveform variables
%waves = {x_dir(16000:20000), x_step(16000:20000), y_dir(16000:20000), y_step(16000:20000), laser(16000:20000), daq(16000:20000)};

waves = {x_dir(1:3), x_step(1:3), y_dir(1:3), y_step(1:3), laser(1:3), daq(1:3)};
figure;
hold on;

for k = 1:6
    y = double(waves{k}(:));       % make it a column of 0s and 1s
    samples = 1:numel(y);
    stairs(samples, y + 2*(6-k), 'LineWidth', 1.5);
end

hold off;
xlabel('Sample number');
ylabel('Waveform');
title("B line")
% yticks(0.5 + 2*(0:20));
yticklabels({'DAQ','laser','Y step','Y dir','X step','X dir'});
ylim([-0.5, 11.5]);
grid on;