function [triggerAddress, timestampHighPart, timestampLowPart] = ...
         AlazarGetTriggerAddress(boardHandle, record)
    pTriggerAddress = libpointer('uint32Ptr', 0);
    pTimestampHighPart = libpointer('uint32Ptr', 0);
    pTimestampLowPart = libpointer('uint32Ptr', 0);
    retCode = calllib('ATSApi',
                      'AlazarGetTriggerAddress',
                      boardHandle,
                      record,
                      pTriggerAddress,
                      pTimestampHighPart,
                      pTimestampLowPart);
    if retCode ~= 512
        throw(MException('AlazarGetTriggerAddress:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
    triggerAddress = pTriggerAddress.Value;
    timestampHighPart = pTimestampHighPart.Value;
    timestampLowPart = pTimestampLowPart.Value;
end
