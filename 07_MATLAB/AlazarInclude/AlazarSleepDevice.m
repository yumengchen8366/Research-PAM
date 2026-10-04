function AlazarSleepDevice(boardHandle, sleepState)
    retCode = calllib('ATSApi', 'AlazarSleepDevice', boardHandle, sleepState);
    if retCode ~= 512
        throw(MException('AlazarSleepDevice:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
end
