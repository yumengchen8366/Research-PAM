function kind = AlazarGetBoardKind(boardHandle)
    kind = calllib('ATSApi', 'AlazarGetBoardKind', boardHandle);
end
