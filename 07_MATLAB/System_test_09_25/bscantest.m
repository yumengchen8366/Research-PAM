%% ========================================================================
%  LabVIEW B-scan Digital Output Timing Analyzer
%
%  用途：
%  ------------------------------------------------------------------------
%  分析从 LabVIEW Probe 导出的 Forward DO Pulse [U8] 数据
%
%  本代码针对目前实验：
%
%       Motor Pulse Rate = 16 kHz
%       Motor Pulse Rate =  8 kHz
%       Motor Pulse Rate =  4 kHz
%
%       dX = 8
%       Xn = 200
%       Trigger Rate = 100 kHz
%       DO Sample Rate = 500 kS/s
%
%
%  主要回答教授的问题：
%
%  1. GUI 中设置的 Motor Pulse Rate 是否真的进入 B-scan？
%
%  2. 改变 16 kHz -> 8 kHz -> 4 kHz 后，
%     实际生成的 Bit0 X STEP frequency 是否跟着改变？
%
%  3. Laser Trigger 是否真的是 100 kHz？
%
%  4. DAQ Trigger 与 Laser Trigger 是否同步？
%
%  5. 两个相邻 X STEP 之间到底有几个 laser pulse？
%     不再简单用 100 kHz / 16 kHz = 6.25 去猜。
%
%  6. dX * Xn / Motor Pulse Rate 这一段程序 timing calculation
%     是否和 Probe 看到的数据一致？
%
%
%  LabVIEW DO Bit Mapping:
%
%       Bit0 = X STEP
%       Bit1 = X DIR
%       Bit2 = Y STEP
%       Bit3 = Y DIR
%       Bit4 = Z STEP
%       Bit5 = Z DIR
%       Bit6 = DAQ Trigger
%       Bit7 = Laser Trigger
%
%
%  MATLAB bitget 注意：
%
%       LabVIEW Bit0 -> MATLAB bitget(...,1)
%       LabVIEW Bit7 -> MATLAB bitget(...,8)
%
% ========================================================================

clear;
clc;
close all;


%% ========================================================================
%  PART 1
%  基本实验设置
% ========================================================================

% Digital Output Sample Rate
% 你的 I/O 设置中是 500000 S/s
DO_sample_rate = 500000;          % samples/s

% 每一个 DO sample 对应的时间
DO_dt = 1 / DO_sample_rate;

fprintf('\n============================================================\n');
fprintf('GLOBAL SETTINGS\n');
fprintf('============================================================\n');

fprintf('DO Sample Rate = %.0f S/s\n', DO_sample_rate);
fprintf('One DO sample  = %.3f us\n', DO_dt * 1e6);


%% ========================================================================
%  PART 2
%  三组测试设置
%
%  !!! 注意 !!!
%
%  请确认 Excel 文件和本 .m 文件放在同一个 folder。
%
%  如果实际扩展名不是 .xlsx，
%  请把下面 filename 改成你的真实文件名。
% ========================================================================

% -------------------------------------------------------------------------
% Test 1 : 16 kHz
% -------------------------------------------------------------------------

tests(1).label = 'Motor 16 kHz';

tests(1).filename = ...
    'ForwardDO_16000_xn200.xlsx';

tests(1).motor_rate_setting = 16000;    % Hz
tests(1).trigger_rate_setting = 100000; % Hz

tests(1).dX = 8;
tests(1).Xn = 200;

tests(1).kx = 0.25;


% -------------------------------------------------------------------------
% Test 2 : 8 kHz
% -------------------------------------------------------------------------

tests(2).label = 'Motor 8 kHz';

tests(2).filename = ...
    'ForwardDO_8000_xn200.xlsx';

tests(2).motor_rate_setting = 8000;

tests(2).trigger_rate_setting = 100000;

tests(2).dX = 8;
tests(2).Xn = 200;

tests(2).kx = 0.25;


% -------------------------------------------------------------------------
% Test 3 : 4 kHz
% -------------------------------------------------------------------------

tests(3).label = 'Motor 4 kHz';

tests(3).filename = ...
    'ForwardDO_4000_xn200.xlsx';

tests(3).motor_rate_setting = 4000;

tests(3).trigger_rate_setting = 100000;

tests(3).dX = 8;
tests(3).Xn = 200;

tests(3).kx = 0.25;


%% ========================================================================
%  PART 3
%  记录 LabVIEW 中间 Probe 的值
%
%  你现在的 Probe 定义：
%
%      Probe 9  = Motor Pulse Rate
%
%      Probe 10 = dX * Xn
%
%      Probe 11 = Probe10 / Motor Pulse Rate
%                 看起来单位是 second
%
%      Probe 12 = Probe11 * DO Sample Rate
%                 看起来是对应的 DO sample 数
%
%
%  已经确认：
%
%      dX = 8
%      Xn = 200
%
%      8 * 200 = 1600
%
%
%  对 8 kHz：
%
%      1600 / 8000 = 0.2 s
%
%      0.2 * 500000 = 100000 samples
%
%
%  对 4 kHz：
%
%      1600 / 4000 = 0.4 s
%
%      0.4 * 500000 = 200000 samples
%
%
%  16 kHz 理论上应该是：
%
%      1600 / 16000 = 0.1 s
%
%      0.1 * 500000 = 50000 samples
%
% ========================================================================


% =======================
% 16 kHz
% =======================

tests(1).probe_motor_rate = 16000;

tests(1).probe_dx_xn = 1600;

% 如果你 Probe 实际看到不是 0.100，
% 请改成实际 Probe 数字
tests(1).probe_motor_time_s = 0.100;

% 如果实际 Probe12 不是 50000，
% 请改成实际 Probe 数字
tests(1).probe_gen_samples = 50000;


% =======================
% 8 kHz
% =======================

tests(2).probe_motor_rate = 8000;

tests(2).probe_dx_xn = 1600;

tests(2).probe_motor_time_s = 0.200;

tests(2).probe_gen_samples = 100000;


% =======================
% 4 kHz
% =======================

tests(3).probe_motor_rate = 4000;

tests(3).probe_dx_xn = 1600;

tests(3).probe_motor_time_s = 0.400;

tests(3).probe_gen_samples = 200000;


%% ========================================================================
%  PART 4
%  一些固定画图颜色
%
%  为了让以后每张图容易看：
%
%      X STEP        = 蓝色
%      DAQ Trigger   = 绿色
%      Laser Trigger = 红色
%      Program math  = 紫色
%      Reference     = 灰色
% ========================================================================

color_motor = [0.0000 0.4470 0.7410];

color_daq = [0.4660 0.6740 0.1880];

color_laser = [0.8500 0.3250 0.0980];

color_math = [0.4940 0.1840 0.5560];

color_ref = [0.45 0.45 0.45];


%% ========================================================================
%  PART 5
%  建立结果储存结构
% ========================================================================

num_tests = length(tests);

results = struct;


%% ========================================================================
%  PART 6
%  开始逐组分析
% ========================================================================

for testID = 1:num_tests

    fprintf('\n\n');
    fprintf('============================================================\n');
    fprintf('TEST %d : %s\n', ...
        testID, tests(testID).label);
    fprintf('============================================================\n');


    %% --------------------------------------------------------------------
    %  6.1 读取 Excel 中的 Forward DO Pulse
    % ---------------------------------------------------------------------

    filename = tests(testID).filename;

    if ~isfile(filename)

        error( ...
            ['找不到文件：' filename newline ...
             '请确认 Excel 文件与 MATLAB script 在同一个 folder，' ...
             '或者修改 tests(...).filename。'] ...
        );

    end

    raw = readmatrix(filename);

    % Excel 里可能有空白格，因此只取所有 numeric data
    data = raw(~isnan(raw));

    % Forward DO Pulse 应该是 U8
    % 合法数值范围应该是 0~255
    if any(data < 0 | data > 255)

        warning( ...
            '%s 出现了不在 U8 0~255 范围内的数值。', ...
            filename ...
        );

    end

    % 转成 U8 column vector
    u8 = uint8(data(:));

    % 真正导出的 DO array 长度
    N = length(u8);

    % 时间轴
    t = (0:N-1)' / DO_sample_rate;

    t_us = t * 1e6;

    t_ms = t * 1e3;

    % 整个 Forward DO array 的时间
    buffer_time_s = N / DO_sample_rate;

    buffer_time_ms = buffer_time_s * 1000;


    fprintf('\n----- Forward DO Buffer -----\n');

    fprintf('File                  = %s\n', filename);

    fprintf('Number of DO samples  = %d\n', N);

    fprintf('Buffer duration       = %.6f s\n', ...
        buffer_time_s);

    fprintf('                      = %.3f ms\n', ...
        buffer_time_ms);


    %% --------------------------------------------------------------------
    %  6.2 Decode Bit0 ~ Bit7
    % ---------------------------------------------------------------------

    bit0 = bitget(u8,1);     % X STEP

    bit1 = bitget(u8,2);     % X DIR

    bit2 = bitget(u8,3);     % Y STEP

    bit3 = bitget(u8,4);     % Y DIR

    bit4 = bitget(u8,5);     % Z STEP

    bit5 = bitget(u8,6);     % Z DIR

    bit6 = bitget(u8,7);     % DAQ Trigger

    bit7 = bitget(u8,8);     % Laser Trigger


    bits = [ ...
        bit0 ...
        bit1 ...
        bit2 ...
        bit3 ...
        bit4 ...
        bit5 ...
        bit6 ...
        bit7 ...
    ];


    %% --------------------------------------------------------------------
    %  6.3 找 Rising Edge
    %
    %  很重要：
    %
    %      0 0 1 1 1 0
    %
    %          ↑
    %
    %  这只算一个 pulse
    %
    %  不能因为 HIGH 连续三个 sample 就算成三个 pulse。
    % ---------------------------------------------------------------------

    x_step_idx = ...
        find(diff([0; double(bit0)]) == 1);

    y_step_idx = ...
        find(diff([0; double(bit2)]) == 1);

    z_step_idx = ...
        find(diff([0; double(bit4)]) == 1);

    daq_idx = ...
        find(diff([0; double(bit6)]) == 1);

    laser_idx = ...
        find(diff([0; double(bit7)]) == 1);


    %% ====================================================================
    %  PART 7
    %  X Motor STEP timing
    % =====================================================================

    fprintf('\n----- X STEP / Bit0 -----\n');

    fprintf('X STEP rising edge count = %d\n', ...
        length(x_step_idx));


    if length(x_step_idx) >= 2

        % 相邻 STEP pulse 相差多少 DO samples
        step_spacing_samples = ...
            diff(x_step_idx);

        % 平均 spacing
        mean_step_spacing = ...
            mean(step_spacing_samples);

        % 中位数 spacing
        median_step_spacing = ...
            median(step_spacing_samples);

        % 根据平均 spacing 反推实际 STEP rate
        motor_freq_actual = ...
            DO_sample_rate / mean_step_spacing;

        % 根据 median spacing 再算一次
        motor_freq_median = ...
            DO_sample_rate / median_step_spacing;


        fprintf('Mean STEP spacing      = %.4f samples\n', ...
            mean_step_spacing);

        fprintf('Median STEP spacing    = %.4f samples\n', ...
            median_step_spacing);

        fprintf('Measured STEP freq     = %.4f kHz\n', ...
            motor_freq_actual / 1000);

        fprintf('Median-based STEP freq = %.4f kHz\n', ...
            motor_freq_median / 1000);

        fprintf('GUI Motor setting      = %.4f kHz\n', ...
            tests(testID).motor_rate_setting / 1000);


        % 和 GUI setting 比较误差
        motor_error_percent = ...
            100 * ...
            (motor_freq_actual - ...
             tests(testID).motor_rate_setting) / ...
             tests(testID).motor_rate_setting;


        fprintf('Difference from GUI    = %.3f %%\n', ...
            motor_error_percent);


        fprintf('\nFirst 30 STEP spacings (DO samples):\n');

        disp( ...
            step_spacing_samples( ...
                1:min(30,end) ...
            )' ...
        );


    else

        step_spacing_samples = [];

        mean_step_spacing = NaN;

        median_step_spacing = NaN;

        motor_freq_actual = NaN;

        motor_freq_median = NaN;

        motor_error_percent = NaN;

        fprintf( ...
            '没有足够的 X STEP edge 计算 frequency。\n' ...
        );

    end


    %% ====================================================================
    %  PART 8
    %  Laser Trigger timing
    % =====================================================================

    fprintf('\n----- Laser Trigger / Bit7 -----\n');

    fprintf('Laser rising edge count = %d\n', ...
        length(laser_idx));


    if length(laser_idx) >= 2

        laser_spacing_samples = ...
            diff(laser_idx);

        mean_laser_spacing = ...
            mean(laser_spacing_samples);

        median_laser_spacing = ...
            median(laser_spacing_samples);

        laser_freq_actual = ...
            DO_sample_rate / mean_laser_spacing;


        fprintf('Mean Laser spacing     = %.4f samples\n', ...
            mean_laser_spacing);

        fprintf('Median Laser spacing   = %.4f samples\n', ...
            median_laser_spacing);

        fprintf('Measured Laser freq    = %.4f kHz\n', ...
            laser_freq_actual / 1000);

        fprintf('GUI Trigger Rate       = %.4f kHz\n', ...
            tests(testID).trigger_rate_setting / 1000);


        fprintf('\nFirst 30 Laser spacings:\n');

        disp( ...
            laser_spacing_samples( ...
                1:min(30,end) ...
            )' ...
        );


    else

        laser_spacing_samples = [];

        mean_laser_spacing = NaN;

        median_laser_spacing = NaN;

        laser_freq_actual = NaN;

    end


    %% ====================================================================
    %  PART 9
    %  DAQ Trigger timing
    % =====================================================================

    fprintf('\n----- DAQ Trigger / Bit6 -----\n');

    fprintf('DAQ rising edge count = %d\n', ...
        length(daq_idx));


    if length(daq_idx) >= 2

        daq_spacing_samples = ...
            diff(daq_idx);

        mean_daq_spacing = ...
            mean(daq_spacing_samples);

        median_daq_spacing = ...
            median(daq_spacing_samples);

        daq_freq_actual = ...
            DO_sample_rate / mean_daq_spacing;


        fprintf('Mean DAQ spacing       = %.4f samples\n', ...
            mean_daq_spacing);

        fprintf('Measured DAQ freq      = %.4f kHz\n', ...
            daq_freq_actual / 1000);


    else

        daq_spacing_samples = [];

        mean_daq_spacing = NaN;

        median_daq_spacing = NaN;

        daq_freq_actual = NaN;

    end


    %% ====================================================================
    %  PART 10
    %  DAQ Trigger vs Laser Trigger synchronization
    % =====================================================================

    fprintf('\n----- DAQ vs Laser Synchronization -----\n');


    if ~isempty(daq_idx) && ~isempty(laser_idx)

        if length(daq_idx) == length(laser_idx)

            trigger_offset_samples = ...
                daq_idx - laser_idx;

            mean_trigger_offset = ...
                mean(trigger_offset_samples);


            fprintf('DAQ pulse count   = %d\n', ...
                length(daq_idx));

            fprintf('Laser pulse count = %d\n', ...
                length(laser_idx));

            fprintf('Mean offset       = %.4f samples\n', ...
                mean_trigger_offset);

            fprintf('Mean offset       = %.4f us\n', ...
                mean_trigger_offset / ...
                DO_sample_rate * 1e6);


            fprintf('Unique offsets =\n');

            disp(unique(trigger_offset_samples)');


            if all(trigger_offset_samples == 0)

                fprintf( ...
                    ['RESULT: DAQ 与 Laser rising edge ' ...
                     '在 DO sample grid 上完全同步。\n'] ...
                );

            end


        else

            fprintf( ...
                'WARNING: DAQ 与 Laser pulse 数量不同。\n' ...
            );

            fprintf('DAQ edges   = %d\n', ...
                length(daq_idx));

            fprintf('Laser edges = %d\n', ...
                length(laser_idx));

            mean_trigger_offset = NaN;

        end


    else

        trigger_offset_samples = [];

        mean_trigger_offset = NaN;

    end


    %% ====================================================================
    %  PART 11
    %
    %  最重要：
    %
    %  两个相邻 X STEP pulse 之间，
    %  实际到底有几个 Laser Trigger？
    %
    %
    %  这直接回答教授：
    %
    %      "How does 6.25 work?"
    %
    %
    %  我们不再做：
    %
    %      100 kHz / 16 kHz = 6.25
    %
    %  然后去猜。
    %
    %  我们直接从真实 Forward DO waveform 数 Bit7。
    % =====================================================================

    fprintf('\n----- Laser Pulses Between X STEP Edges -----\n');


    if length(x_step_idx) >= 2

        nMotorIntervals = ...
            length(x_step_idx) - 1;

        laser_per_motor_interval = ...
            zeros(nMotorIntervals,1);


        for k = 1:nMotorIntervals

            this_step = ...
                x_step_idx(k);

            next_step = ...
                x_step_idx(k+1);


            % 当前 motor STEP inclusive
            % 下一个 motor STEP exclusive
            laser_per_motor_interval(k) = ...
                sum( ...
                    laser_idx >= this_step & ...
                    laser_idx < next_step ...
                );

        end


        mean_laser_per_motor = ...
            mean(laser_per_motor_interval);


        fprintf('Mean Laser pulses / motor interval = %.4f\n', ...
            mean_laser_per_motor);


        fprintf('\nFirst 40 intervals:\n');

        disp( ...
            laser_per_motor_interval( ...
                1:min(40,end) ...
            )' ...
        );


        unique_counts = ...
            unique(laser_per_motor_interval);


        fprintf('Unique integer counts =\n');

        disp(unique_counts');


        fprintf('\nDistribution:\n');


        for q = 1:length(unique_counts)

            c = unique_counts(q);

            n_c = ...
                sum(laser_per_motor_interval == c);


            fprintf( ...
                '%d laser pulses : %d motor intervals\n', ...
                c, n_c ...
            );

        end


    else

        laser_per_motor_interval = [];

        mean_laser_per_motor = NaN;

    end


    %% ====================================================================
    %  PART 12
    %  Y/Z activity
    % =====================================================================

    fprintf('\n----- Other Axes -----\n');

    fprintf('Y STEP rising edges = %d\n', ...
        length(y_step_idx));

    fprintf('Z STEP rising edges = %d\n', ...
        length(z_step_idx));


    %% ====================================================================
    %  PART 13
    %  检查 Program timing calculation
    %
    %  根据 Probe，目前我们看到的关系像：
    %
    %       motion_time
    %       =
    %       (dX * Xn) / Motor Pulse Rate
    %
    %
    %       generated DO samples
    %       =
    %       motion_time * DO Sample Rate
    %
    %
    %  这里同时根据参数重新计算一遍，
    %  与 LabVIEW Probe 数值比较。
    % =====================================================================

    theoretical_dx_xn = ...
        tests(testID).dX * tests(testID).Xn;


    theoretical_motion_time_s = ...
        theoretical_dx_xn / ...
        tests(testID).motor_rate_setting;


    theoretical_gen_samples = ...
        theoretical_motion_time_s * ...
        DO_sample_rate;


    fprintf('\n----- Program Timing Math -----\n');

    fprintf('dX                   = %g\n', ...
        tests(testID).dX);

    fprintf('Xn                   = %g\n', ...
        tests(testID).Xn);

    fprintf('dX * Xn              = %.0f\n', ...
        theoretical_dx_xn);

    fprintf('Motor setting        = %.0f Hz\n', ...
        tests(testID).motor_rate_setting);

    fprintf('(dX*Xn)/MotorRate    = %.6f s\n', ...
        theoretical_motion_time_s);

    fprintf('x DO Sample Rate     = %.0f samples\n', ...
        theoretical_gen_samples);


    fprintf('\nLabVIEW Probe values:\n');

    fprintf('Probe 10 dX*Xn       = %.0f\n', ...
        tests(testID).probe_dx_xn);

    fprintf('Probe 11 time        = %.6f s\n', ...
        tests(testID).probe_motor_time_s);

    fprintf('Probe 12 samples     = %.0f\n', ...
        tests(testID).probe_gen_samples);


    %% ====================================================================
    %  PART 14
    %  保存结果
    % =====================================================================

    results(testID).label = ...
        tests(testID).label;

    results(testID).N = N;

    results(testID).buffer_time_ms = ...
        buffer_time_ms;

    results(testID).x_step_count = ...
        length(x_step_idx);

    results(testID).motor_freq_actual = ...
        motor_freq_actual;

    results(testID).motor_freq_median = ...
        motor_freq_median;

    results(testID).motor_error_percent = ...
        motor_error_percent;

    results(testID).laser_count = ...
        length(laser_idx);

    results(testID).laser_freq_actual = ...
        laser_freq_actual;

    results(testID).daq_count = ...
        length(daq_idx);

    results(testID).daq_freq_actual = ...
        daq_freq_actual;

    results(testID).mean_laser_per_motor = ...
        mean_laser_per_motor;

    results(testID).x_step_idx = ...
        x_step_idx;

    results(testID).laser_idx = ...
        laser_idx;

    results(testID).daq_idx = ...
        daq_idx;

    results(testID).laser_per_motor_interval = ...
        laser_per_motor_interval;

    results(testID).step_spacing_samples = ...
        step_spacing_samples;


    %% ====================================================================
    %  FIGURE 1
    %
    %  Raw Forward DO U8
    %
    %  这里只看很短的 200 us，
    %  因为 Raw U8 最主要用于看 192 等 repeating pattern。
    % =====================================================================

    figure( ...
        'Name', ...
        ['Raw U8 - ' tests(testID).label] ...
    );

    stairs( ...
        t_us, ...
        double(u8), ...
        'LineWidth',1.2, ...
        'Color',color_math ...
    );

    xlabel('Time (\mus)');

    ylabel('Raw U8 value');

    title( ...
        ['Raw Forward DO U8 - ' ...
         tests(testID).label] ...
    );

    grid on;

    xlim([0 min(200,max(t_us))]);

    ylim([-10 265]);


    %% ====================================================================
    %  FIGURE 2
    %
    %  Laser + DAQ
    %
    %  Laser 是 100 kHz，周期大约 10 us。
    %
    %  所以显示前 200 us，
    %  大概可以看到 20 个 trigger period。
    % =====================================================================

    figure( ...
        'Name', ...
        ['LaserDAQ - ' tests(testID).label] ...
    );

    hold on;


    stairs( ...
        t_us, ...
        double(bit6), ...
        'LineWidth',1.5, ...
        'Color',color_daq ...
    );


    stairs( ...
        t_us, ...
        double(bit7) + 1.5, ...
        'LineWidth',1.5, ...
        'Color',color_laser ...
    );


    yticks([0.5 2.0]);

    yticklabels({ ...
        'DAQ Trigger', ...
        'Laser Trigger' ...
    });


    xlabel('Time (\mus)');

    ylabel('Digital line');

    title( ...
        ['Laser / DAQ Timing - ' ...
         tests(testID).label] ...
    );

    grid on;

    xlim([0 min(200,max(t_us))]);

    ylim([-0.2 2.7]);

    hold off;


    %% ====================================================================
    %  FIGURE 3
    %
    %  X Motor STEP timing
    %
    %  每组显示约 20 个 nominal motor periods。
    %
    %  这样 4 / 8 / 16 kHz 的图 scale 会自动调整，
    %  不会因为统一 xlim 导致看不清。
    % =====================================================================

    nominal_motor_period_us = ...
        1e6 / tests(testID).motor_rate_setting;


    motor_plot_window_us = ...
        20 * nominal_motor_period_us;


    figure( ...
        'Name', ...
        ['X STEP - ' tests(testID).label] ...
    );


    stairs( ...
        t_us, ...
        double(bit0), ...
        'LineWidth',1.6, ...
        'Color',color_motor ...
    );


    xlabel('Time (\mus)');

    ylabel('Bit0 - X STEP');

    title( ...
        sprintf( ...
            '%s | X STEP waveform', ...
            tests(testID).label ...
        ) ...
    );

    grid on;

    xlim( ...
        [0 ...
         min(motor_plot_window_us,max(t_us))] ...
    );

    ylim([-0.15 1.25]);


    %% ====================================================================
    %  FIGURE 4
    %
    %  Laser / DAQ / X STEP 在同一个时间轴
    %
    %  这个图很适合直接给教授看。
    %
    %  用 event marker 而不是 waveform，
    %  更容易看 rising edge 的关系。
    % =====================================================================

    figure( ...
        'Name', ...
        ['Events - ' tests(testID).label] ...
    );

    hold on;


    if ~isempty(x_step_idx)

        plot( ...
            t_us(x_step_idx), ...
            ones(size(x_step_idx)), ...
            '|', ...
            'MarkerSize',12, ...
            'LineWidth',1.5, ...
            'Color',color_motor ...
        );

    end


    if ~isempty(daq_idx)

        plot( ...
            t_us(daq_idx), ...
            2*ones(size(daq_idx)), ...
            '|', ...
            'MarkerSize',12, ...
            'LineWidth',1.5, ...
            'Color',color_daq ...
        );

    end


    if ~isempty(laser_idx)

        plot( ...
            t_us(laser_idx), ...
            3*ones(size(laser_idx)), ...
            '|', ...
            'MarkerSize',12, ...
            'LineWidth',1.5, ...
            'Color',color_laser ...
        );

    end


    yticks([1 2 3]);

    yticklabels({ ...
        'X STEP', ...
        'DAQ Trigger', ...
        'Laser Trigger' ...
    });


    xlabel('Time (\mus)');

    title( ...
        ['Actual Generated Event Timing - ' ...
         tests(testID).label] ...
    );

    grid on;


    xlim( ...
        [0 ...
         min(motor_plot_window_us,max(t_us))] ...
    );

    ylim([0.5 3.5]);

    hold off;


    %% ====================================================================
    %  FIGURE 5
    %
    %  Local X STEP Frequency
    %
    %  如果 GEN PULSE 使用 acceleration / S-curve，
    %  这里可以直接看到 frequency 是否随时间变化。
    %
    %  同时画 GUI Motor Pulse Rate reference。
    % =====================================================================

    if length(x_step_idx) >= 2

        local_motor_freq = ...
            DO_sample_rate ./ ...
            step_spacing_samples;


        step_time_ms = ...
            t_ms(x_step_idx(1:end-1));


        figure( ...
            'Name', ...
            ['Local Motor Frequency - ' ...
             tests(testID).label] ...
        );


        plot( ...
            step_time_ms, ...
            local_motor_freq / 1000, ...
            '-o', ...
            'LineWidth',1.2, ...
            'MarkerSize',4, ...
            'Color',color_motor ...
        );


        hold on;


        yline( ...
            tests(testID).motor_rate_setting / 1000, ...
            '--', ...
            'GUI Motor Rate', ...
            'LineWidth',1.4, ...
            'Color',color_ref ...
        );


        xlabel('Time (ms)');

        ylabel('Local X STEP frequency (kHz)');


        title( ...
            sprintf( ...
                '%s | Mean measured = %.3f kHz | GUI = %.3f kHz', ...
                tests(testID).label, ...
                motor_freq_actual / 1000, ...
                tests(testID).motor_rate_setting / 1000 ...
            ) ...
        );


        maxY = ...
            max( ...
                [local_motor_freq(:)/1000; ...
                 tests(testID).motor_rate_setting/1000] ...
            );


        ylim([0 maxY*1.25]);

        grid on;

        hold off;

    end


    %% ====================================================================
    %  FIGURE 6
    %
    %  每一个 motor STEP interval 中实际有多少个 Laser pulse
    %
    %  这个图直接回答：
    %
    %      "Does 6.25 mean some intervals have 6 and some have 7?"
    %
    %  这里展示的是实际 generated waveform 中数出来的整数。
    % =====================================================================

    if ~isempty(laser_per_motor_interval)

        figure( ...
            'Name', ...
            ['Laser per Motor Interval - ' ...
             tests(testID).label] ...
        );


        stem( ...
            1:length(laser_per_motor_interval), ...
            laser_per_motor_interval, ...
            'filled', ...
            'LineWidth',1.1, ...
            'Color',color_laser ...
        );


        xlabel('Motor STEP interval number');

        ylabel('Laser rising edges per X STEP interval');


        title( ...
            sprintf( ...
                '%s | Mean = %.3f laser pulses / motor interval', ...
                tests(testID).label, ...
                mean_laser_per_motor ...
            ) ...
        );


        maxCount = ...
            max(laser_per_motor_interval);


        ylim([0 maxCount + 1]);

        grid on;

    end


end


%% ========================================================================
%  PART 15
%  建立 Summary Table
% ========================================================================

labels = strings(num_tests,1);

motor_setting_kHz = zeros(num_tests,1);

motor_measured_kHz = zeros(num_tests,1);

motor_error_percent = zeros(num_tests,1);

laser_setting_kHz = zeros(num_tests,1);

laser_measured_kHz = zeros(num_tests,1);

buffer_ms = zeros(num_tests,1);

x_step_count = zeros(num_tests,1);

laser_count = zeros(num_tests,1);

mean_laser_per_motor = zeros(num_tests,1);

probe_motion_time_ms = zeros(num_tests,1);

probe_gen_samples = zeros(num_tests,1);


for i = 1:num_tests

    labels(i) = ...
        tests(i).label;

    motor_setting_kHz(i) = ...
        tests(i).motor_rate_setting / 1000;

    motor_measured_kHz(i) = ...
        results(i).motor_freq_actual / 1000;

    motor_error_percent(i) = ...
        results(i).motor_error_percent;

    laser_setting_kHz(i) = ...
        tests(i).trigger_rate_setting / 1000;

    laser_measured_kHz(i) = ...
        results(i).laser_freq_actual / 1000;

    buffer_ms(i) = ...
        results(i).buffer_time_ms;

    x_step_count(i) = ...
        results(i).x_step_count;

    laser_count(i) = ...
        results(i).laser_count;

    mean_laser_per_motor(i) = ...
        results(i).mean_laser_per_motor;

    probe_motion_time_ms(i) = ...
        tests(i).probe_motor_time_s * 1000;

    probe_gen_samples(i) = ...
        tests(i).probe_gen_samples;

end


Summary = table( ...
    labels, ...
    motor_setting_kHz, ...
    motor_measured_kHz, ...
    motor_error_percent, ...
    laser_setting_kHz, ...
    laser_measured_kHz, ...
    buffer_ms, ...
    x_step_count, ...
    laser_count, ...
    mean_laser_per_motor, ...
    probe_motion_time_ms, ...
    probe_gen_samples ...
);


Summary.Properties.VariableNames = { ...
    'Test', ...
    'MotorSetting_kHz', ...
    'MeasuredMotor_kHz', ...
    'MotorError_percent', ...
    'TriggerSetting_kHz', ...
    'MeasuredLaser_kHz', ...
    'ForwardDO_Buffer_ms', ...
    'XStepCount', ...
    'LaserCount', ...
    'MeanLaserPerMotorInterval', ...
    'ProbeMotionTime_ms', ...
    'ProbeGeneratedSamples' ...
};


fprintf('\n\n');
fprintf('============================================================\n');
fprintf('FINAL SUMMARY\n');
fprintf('============================================================\n');

disp(Summary);


%% ========================================================================
%  PART 16
%
%  Comparison Figure 1
%
%  Motor GUI Setting vs 实际 Bit0 frequency
%
%  如果三个点接近：
%
%       4 -> 4
%       8 -> 8
%      16 ->16
%
%  就可以非常直接地证明：
%
%  Motor Pulse Rate setting 确实改变了
%  B-scan 中生成的 X STEP timing。
% ========================================================================

figure( ...
    'Name', ...
    'Motor Setting vs Measured STEP Frequency' ...
);


plot( ...
    motor_setting_kHz, ...
    motor_measured_kHz, ...
    'o-', ...
    'LineWidth',2, ...
    'MarkerSize',9, ...
    'Color',color_motor ...
);


hold on;


maxAxis = ...
    max( ...
        [motor_setting_kHz; ...
         motor_measured_kHz] ...
    );


if isnan(maxAxis) || maxAxis <= 0

    maxAxis = 20;

end


maxAxis = maxAxis * 1.15;


plot( ...
    [0 maxAxis], ...
    [0 maxAxis], ...
    '--', ...
    'LineWidth',1.5, ...
    'Color',color_ref ...
);


xlabel('GUI Motor Pulse Rate Setting (kHz)');

ylabel('Measured Bit0 STEP Frequency (kHz)');

title( ...
    'Motor Pulse Rate Setting vs Generated X STEP Frequency' ...
);


legend( ...
    'Measured Bit0 STEP', ...
    'Ideal: Measured = Setting', ...
    'Location','northwest' ...
);


xlim([0 maxAxis]);

ylim([0 maxAxis]);

axis square;

grid on;

hold off;


%% ========================================================================
%  PART 17
%
%  Comparison Figure 2
%
%  Motor Pulse Rate vs 程序计算出的 motion duration
%
%  根据目前 Probe：
%
%      16 kHz -> 100 ms
%       8 kHz -> 200 ms
%       4 kHz -> 400 ms
%
%  这可以证明 Motor Pulse Rate 已经进入 timing calculation。
% ========================================================================

figure( ...
    'Name', ...
    'Motor Rate vs Program Motion Time' ...
);


bar( ...
    motor_setting_kHz, ...
    probe_motion_time_ms, ...
    'FaceColor',color_math ...
);


xlabel('Motor Pulse Rate Setting (kHz)');

ylabel('Program-calculated motion time (ms)');

title( ...
    'Motor Pulse Rate vs LabVIEW Calculated Motion Duration' ...
);

grid on;


%% ========================================================================
%  PART 18
%
%  Comparison Figure 3
%
%  Motor Pulse Rate vs Probe12 Generated Samples
%
%  这个直接显示：
%
%      16 kHz -> ~ 50,000 samples
%       8 kHz -> 100,000 samples
%       4 kHz -> 200,000 samples
%
% ========================================================================

figure( ...
    'Name', ...
    'Motor Rate vs Generated DO Samples' ...
);


bar( ...
    motor_setting_kHz, ...
    probe_gen_samples, ...
    'FaceColor',color_math ...
);


xlabel('Motor Pulse Rate Setting (kHz)');

ylabel('Probe 12 generated DO samples');

title( ...
    'Motor Pulse Rate vs Number of DO Samples Used for GEN PULSE' ...
);

grid on;


%% ========================================================================
%  PART 19
%
%  Comparison Figure 4
%
%  三组实验 Laser Frequency
%
%  理论上：
%
%  改 Motor Pulse Rate 时，
%  如果 trigger generation path 没被改变，
%
%  Laser frequency 应该仍接近 100 kHz。
%
% ========================================================================

figure( ...
    'Name', ...
    'Laser Frequency Across Motor Settings' ...
);


plot( ...
    motor_setting_kHz, ...
    laser_measured_kHz, ...
    'o-', ...
    'LineWidth',2, ...
    'MarkerSize',9, ...
    'Color',color_laser ...
);


hold on;


yline( ...
    100, ...
    '--', ...
    'GUI Trigger Rate = 100 kHz', ...
    'LineWidth',1.5, ...
    'Color',color_ref ...
);


xlabel('Motor Pulse Rate Setting (kHz)');

ylabel('Measured Laser Trigger Frequency (kHz)');

title( ...
    'Does Laser Trigger Frequency Stay Constant When Motor Rate Changes?' ...
);


grid on;

hold off;


%% ========================================================================
%  PART 20
%
%  Comparison Figure 5
%
%  三组实验平均 Laser pulses / X STEP interval
%
%  注意：
%
%  这里的 mean 只是统计结果。
%
%  真正回答教授 "6.25" 问题时，
%  要同时看前面的 integer distribution 图。
% ========================================================================

figure( ...
    'Name', ...
    'Laser Pulses per Motor Interval Comparison' ...
);


bar( ...
    motor_setting_kHz, ...
    mean_laser_per_motor, ...
    'FaceColor',color_laser ...
);


xlabel('Motor Pulse Rate Setting (kHz)');

ylabel('Mean Laser pulses per X STEP interval');

title( ...
    'Measured Laser Pulses Between Consecutive X STEP Edges' ...
);

grid on;


%% ========================================================================
%  PART 21
%  保存全部结果
% ========================================================================

writetable( ...
    Summary, ...
    'DO_timing_summary_16k_8k_4k.xlsx' ...
);


save( ...
    'DO_timing_analysis_16k_8k_4k.mat', ...
    'tests', ...
    'results', ...
    'Summary' ...
);


fprintf('\n============================================================\n');
fprintf('Analysis complete.\n');
fprintf('============================================================\n');

fprintf( ...
    'Summary saved as: DO_timing_summary_16k_8k_4k.xlsx\n' ...
);

fprintf( ...
    'MAT file saved as: DO_timing_analysis_16k_8k_4k.mat\n' ...
);