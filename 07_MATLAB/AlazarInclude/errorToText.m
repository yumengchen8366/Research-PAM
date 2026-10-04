function text = errorToText(errorCode)
% Convert an error number to a string
    errorText = calllib('ATSApi', 'AlazarErrorToText', errorCode);
    text = sprintf('%s (%d)', errorText, errorCode);
end
