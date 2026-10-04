function AlazarForceTriggerEnable(boardHandle)
    retCode = calllib('ATSApi', 'AlazarForceTriggerEnable', boardHandle);
    if retCode ~= 512
        throw(MException('AlazarForceTriggerEnable:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
end
