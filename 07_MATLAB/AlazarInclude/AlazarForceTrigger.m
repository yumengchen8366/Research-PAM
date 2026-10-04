function AlazarForceTrigger(boardHandle)
    retCode = calllib('ATSApi', 'AlazarForceTrigger', boardHandle);
    if retCode ~= 512
        throw(MException('AlazarForceTrigger:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
end
