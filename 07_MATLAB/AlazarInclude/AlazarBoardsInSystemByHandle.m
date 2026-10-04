function AlazarBoardsInSystemByHandle(boardHandle)
    retCode = calllib('ATSApi', 'AlazarBoardsInSystemByHandle', boardHandle);
    if retCode ~= 512
        throw(MException('AlazarBoardsInSystemByHandle:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
end
