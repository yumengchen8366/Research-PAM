function timestampSamples = AlazarGetTriggerTimestamp(boardHandle, record)
    pTimestampSamples = libpointer('uint64Ptr', 0);
    retCode = calllib('ATSApi',
                      'AlazarGetTriggerTimestamp',
                      boardHandle,
                      record,
                      pTimestampSamples);
    if retCode ~= 512
        throw(MException('AlazarGetTriggerTimestamp:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
    timestampSampels = pTimestampSamples.Value;
end
