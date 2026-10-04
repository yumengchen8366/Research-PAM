function AlazarSetLED(boardHandle, ledOn)
    retCode = calllib('ATSApi', 'AlazarSetLED', boardHandle, ledOn);
    if retCode ~= 512
        throw(MException('AlazarSetLED:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
end
