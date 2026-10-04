function AlazarAbortCapture(boardHandle)
    retCode = calllib('ATSApi', 'AlazarAbortCapture', boardHandle);
    if retCode ~= 512
        throw(MException('AlazarAbortCapture:error', '%s', errorToText(retCode)));
    end
end
