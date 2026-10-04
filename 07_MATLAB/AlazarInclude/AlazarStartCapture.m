function AlazarStartCapture(boardHandle)
    retCode = calllib('ATSApi', 'AlazarStartCapture', boardHandle);
    if retCode ~= 512
        throw(MException('AlazarStartCapture:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
end
