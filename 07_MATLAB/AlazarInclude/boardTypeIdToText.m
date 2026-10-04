function text = boardTypeIdToText(boardType)
    % Convert board type id to text

    % Call mfile with library definitions
    AlazarDefs

    switch boardType
        case ATS850
            text = 'ATS850';
        case ATS310
            text = 'ATS310';
        case ATS330
            text = 'ATS330';
        case ATS855
            text = 'ATS855';
        case ATS315
            text = 'ATS315';
        case ATS335
            text = 'ATS335';
        case ATS460
            text = 'ATS460';
        case ATS860
            text = 'ATS860';
        case ATS660
            text = 'ATS660';
        case ATS665
            text = 'ATS665';
        case ATS9462
            text = 'ATS9462';
        case ATS9870
            text = 'ATS9870';
        case ATS9350
            text = 'ATS9350';
        case ATS9325
            text = 'ATS9325';
        case ATS9440
            text = 'ATS9440';
        case ATS9351
            text = 'ATS9351';
        case ATS9850
            text = 'ATS9850';
        case ATS9625
            text = 'ATS9625';
        case ATS9626
            text = 'ATS9626';
        case ATS9360
            text = 'ATS9360';
        case AXI9870
            text = 'AXI9870';
        case ATS9370
            text = 'ATS9370';
        case ATS9373
            text = 'ATS9373';
        case ATS9416
            text = 'ATS9416';
        case ATS9637
            text = 'ATS9637';
        case ATS9120
            text = 'ATS9120';
        case ATS9371
            text = 'ATS9371';
        case ATS9130
            text = 'ATS9130';
        case ATS9352
            text = 'ATS9352';
        case ATS9453
            text = 'ATS9453';
        case ATS9146
            text = 'ATS9146';
        case ATS9437
            text = 'ATS9437';
        case ATS9618
            text = 'ATS9618';
        case ATS9358
            text = 'ATS9358';
        case ATS9353
            text = 'ATS9353';
        case ATS9872
            text = 'ATS9872';
        case ATS9874
            text = 'ATS9874';
        case ATS9628
            text = 'ATS9628';
        case ATS9428
            text = 'ATS9428';
        case ATS9364
            text = 'ATS9364';
        case ATS9442
            text = 'ATS9442';
        case ATS9182
            text = 'ATS9182';
        otherwise
            text = '?';
    end

end
