function handle = AlazarGetBoardBySystemID(systemId, boardId)
    handle = calllib('ATSApi', 'AlazarGetBoardBySystemID', systemId, boardId);
    if isNull(handle)
        throw(MException('AlazarGetBoardBySystemID:error', ...
                         'NULL board'));
    end
end
