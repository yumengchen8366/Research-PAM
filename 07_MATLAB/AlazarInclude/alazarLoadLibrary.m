function alazarLoadLibrary
    if libisloaded('ATSApi')
        return;
    end

    if strcmpi(computer('arch'), 'win64')
        % Use protofile for 64-bit MATLAB
        loadlibrary('ATSApi.dll',@AlazarInclude_pcwin64)
    elseif sscanf(version('-release'), '%d') >= 2009
        % Use protofile for 32-bit MATLAB 2009 and later
        loadlibrary('ATSApi.dll',@AlazarInclude_pcwin32)
    else
        error('MATLAB prior to 2009 is not supported by ATS-SDK 7.0.0 and above')
    end

    if ~libisloaded('ATSApi')
        throw(MException('alazarLoadLibrary:error', 'Could not load library'));
    end
end
