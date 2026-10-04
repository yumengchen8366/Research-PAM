function AlazarFreeBuffer(boardHandle, buffer)
    setdatatype(buffer, 'uint8Ptr', 1);
    retCode = calllib('ATSApi', 'AlazarFreeBufferU8', boardHandle, buffer);
    if retCode ~= 512
        throw(MException('AlazarFreeBuffer:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
end
