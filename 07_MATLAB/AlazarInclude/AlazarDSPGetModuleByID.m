function handle = AlazarDSPGetModuleByID(boardHandle, dspModuleID)
    handle = calllib('ATSApi', 'AlazarDSPGetModuleByID', boardHandle, ...
                     dspModuleID);
    if isNull(handle)
        throw(MException('AlazarDSPGetModuleByID:error', ...
                         'NULL module'));
    end
end

