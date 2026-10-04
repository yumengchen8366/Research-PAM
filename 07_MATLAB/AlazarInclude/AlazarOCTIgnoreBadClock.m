function [triggerCycleTime, triggerPulseWidth] = ...
         AlazarOCTIgnoreBadClock(boardHandle, ...
                                 enable, ...
                                 goodClockDuration, ...
                                 badClockDuration)
    pTriggerCycleTime = libpointer('doublePtr', 0);
    pTriggerPulseWidth = libpointer('doublePtr', 0);
    retCode = calllib('ATSApi',
                      'AlazarOCTIgnoreBadClock',
                      boardHandle,
                      enable,
                      goodClockDuration,
                      badClockDuration,
                      pTriggerCycleTime,
                      pTriggerPulseWidth);
    if retCode ~= 512
        throw(MException('AlazarOCTIgnoreBadClock:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
    triggerCycleTime = pTriggerCycleTime.Value;
    triggerPulseWidth = pTriggerPulseWidth.Value;
end
