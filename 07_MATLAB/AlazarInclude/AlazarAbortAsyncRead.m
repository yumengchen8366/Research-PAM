function AlazarAbortAsyncRead(boardHandle)
    retCode = calllib('ATSApi', 'AlazarAbortAsyncRead', boardHandle);
    if retCode ~= 512
        throw(MException('AlazarAbortAsyncRead:error', '%s', errorToText(retCode)));
    end
end
