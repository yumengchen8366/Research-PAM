function AlazarDSPAbortCapture(boardHandle)
    retCode = calllib('ATSApi', 'AlazarDSPAbortCapture', boardHandle);
    if retCode ~= 512
        throw(MException('AlazarDSPAbortCapture:error', '%s', errorToText(retCode)));
    end
end
