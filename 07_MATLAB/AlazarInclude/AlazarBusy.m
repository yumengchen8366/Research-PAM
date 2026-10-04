function busy = AlazarBusy(boardHandle)
    busy = calllib('ATSApi', 'AlazarBusy', boardHandle);
end
