function [majorNumber, minorNumber, revisionNumber] = ...
         AlazarGetDriverVersion()
    pMajorNumber = libpointer('uint8Ptr', 0);
    pMinorNumber = libpointer('uint8Ptr', 0);
    pRevisionNumber = libpointer('uint8Ptr', 0);
    retCode = calllib('ATSApi',
                      'AlazarGetDriverVersion',
                      pMajorNumber,
                      pMinorNumber,
                      pRevisionNumber);
    if retCode ~= 512
        throw(MException('AlazarGetDriverVersion:error', ...
                         '%s', ...
                         errorToText(retCode)));
    end
    majorNumber = pMajorNumber.Value;
    minorNumber = pMinorNumber.Value;
    revisionNumber = pRevisionNumber.Value;
end
