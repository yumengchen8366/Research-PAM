function status = AlazarGetStatus(boardHandle)
    status = calllib('ATSApi', 'AlazarGetStatus', boardHandle);
end
