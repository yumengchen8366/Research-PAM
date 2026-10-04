function AlazarSetTriggerDelay(boardHandle, value)
    retCode = calllib('ATSApi', 'AlazarSetTriggerDelay', boardHandle, value);
    if retCode ~= 512
        throw(MException('AlazarSetTriggerDelay:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
end
