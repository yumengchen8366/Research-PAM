function triggered = AlazarTriggered(boardHandle)
    triggered = calllib('ATSApi', 'AlazarTriggered', boardHandle);
end
