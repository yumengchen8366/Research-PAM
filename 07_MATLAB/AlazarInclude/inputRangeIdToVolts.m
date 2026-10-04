function inputRangeVolts = inputRangeIdToVolts(inputRangeId)
    % Convert input range identifier to volts

    % Call mfile with library definitions
    AlazarDefs

    switch inputRangeId
        case INPUT_RANGE_PM_20_MV
            inputRangeVolts = 0.02;
        case INPUT_RANGE_PM_40_MV
            inputRangeVolts = 0.04;
        case INPUT_RANGE_PM_50_MV
            inputRangeVolts = 0.05;
        case INPUT_RANGE_PM_80_MV
            inputRangeVolts = 0.08;
        case INPUT_RANGE_PM_100_MV
            inputRangeVolts = 0.1;
        case INPUT_RANGE_PM_200_MV
            inputRangeVolts = 0.2;
        case INPUT_RANGE_PM_400_MV
            inputRangeVolts = 0.4;
        case INPUT_RANGE_PM_500_MV
            inputRangeVolts = 0.5;
        case INPUT_RANGE_PM_800_MV
            inputRangeVolts = 0.8;
        case INPUT_RANGE_PM_1_V
            inputRangeVolts = 1;
        case INPUT_RANGE_PM_2_V
            inputRangeVolts = 2;
        case INPUT_RANGE_PM_4_V
            inputRangeVolts = 4;
        case INPUT_RANGE_PM_5_V
            inputRangeVolts = 5;
        case INPUT_RANGE_PM_8_V
            inputRangeVolts = 8;
        case INPUT_RANGE_PM_10_V
            inputRangeVolts = 10;
        case INPUT_RANGE_PM_20_V
            inputRangeVolts = 20;
        case INPUT_RANGE_PM_40_V
            inputRangeVolts = 40;
        case INPUT_RANGE_PM_16_V
            inputRangeVolts = 16;
        case INPUT_RANGE_PM_1_V_25
            inputRangeVolts = 1.25;
        case INPUT_RANGE_PM_2_V_5
            inputRangeVolts = 2.5;
        case INPUT_RANGE_PM_125_MV
            inputRangeVolts = 0.125;
        case INPUT_RANGE_PM_250_MV
            inputRangeVolts = 0.250;
        otherwise
            inputRangeVolts = 0;
    end

end
