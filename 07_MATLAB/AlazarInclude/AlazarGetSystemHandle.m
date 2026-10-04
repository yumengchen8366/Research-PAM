function handle = AlazarGetSystemHandle(systemId)
    handle = calllib('ATSApi', 'AlazarGetSystemHandle', systemId);
    if isNull(handle)
        throw(MException('AlazarGetSystemHandle:error', ...
                         'NULL board'));
    end
end
