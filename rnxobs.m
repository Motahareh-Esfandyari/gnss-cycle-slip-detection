%% ========================================================================
%  GNSS-CycleSlip : Cycle Slip Detection in GNSS Carrier Phase Observations
%  ------------------------------------------------------------------------
%  Function: rnxobs.m
%  Purpose : Reads a single epoch of a RINEX v2.10 GPS observation file
%            and returns the PRNs and requested observations.
%  ------------------------------------------------------------------------
%  Used by                 : Motahareh Esfandyari-Kaloukan
%  Original implementation : LaQ, MGP - TU Delft, 2002 (see credit below)
%  ========================================================================

function [s,ierr] = rnxobs (fid, rnxh)
% RNXOBS.M: read a single epoch of RINEX observation file
% 
% SYNTAX:   
%       [s,ierr] = rnxobs (fid, rnxh);
%
% DESCRIPTION:
%       fid     :   input       File identifier of RINEX file
%       rnxh    :   input       Structure with the information from the RINEX header
%       s       :   output      Structure to hold the observations
%       ierr    :   output      Return status
%                                    0: OK
%                                   -1: EOF found
%                                   -2: Last observation read is incomplete
%
% NOTES: 
%       1. For RINEX version 2.10 and GPS observation files only
%       2. RINEX file must not contain more than 10 observation types
%       3. Observations are returned in their original units, no
%          conversion to meters is made for phase observations
%       4. This routine only returns observations in the types requested
%          [specified by rnxheader.m routine]
%       5. The size of observation field equals number of satellites times
%          number of observation types
%
% EXAMPLE:
%       fid = fopen ('yp011254.94o', 'rt');
%       [rnxh] = rnxheader (fid, 'C1L1L2P1P2');
%       [s,ierr] = rnxobs (fid, rnxh);
%
% CREATED:
%                      -------------------
%                       21-10-2002 by LaQ
%                        MGP - TU Delft
%                      -------------------

% START:
% -------------------------------------------------------------------------

% Create structure to hold observations
s = struct( 'NumChannels', 0,       ...
	        'PRN', NaN,             ...
	        'Observations', NaN,    ...
	        'time', NaN*ones(1,6),  ...
	        'gpsweek', NaN,         ...
	        'secsinweek', NaN,      ...
            'ASFlag', NaN);

% Initialize
ierr = 0;

% Process the first line (epoch/sat or event flag?)
line = fgetl (fid);
if feof(fid);
    ierr = -2; 
    return; 
end;
EpochFlag = str2num(line(29)); % Epoch flag or Event flag?

% If Event flag, skip number of lines stored in number of satellites
while EpochFlag > 1
    s.NumChannels = str2num (line(30:32));
    for i=0:1:s.NumChannels
        line = fgetl(fid);
    end;
    EpochFlag = str2num(line(29));
end;

if rnxh.ClkOffsAppl == 1
    s.ClkOffset = str2num (line(69:end));
end;

% If Epoch flag, read current epoch
s.time(1) = str2num (line( 2: 3)) + 1900 + rnxh.Y2KCorrection; % Convert the 2-digit-year into 4-digit-year with Y2K correctionn
s.time(2) = str2num (line( 5: 6));
s.time(3) = str2num (line( 8: 9));
s.time(4) = str2num (line(11:12));
s.time(5) = str2num (line(14:15));
s.time(6) = str2num (line(17:26));

% Convert current epoch into GPS week and seconds in the week
date = datenum(s.time(1),s.time(2),s.time(3)); % The serial date numbers from 1-Jan-0000 to the day of observation
s.gpsweek = fix((date - datenum(1980,1,6))/7); 
s.secsinweek = (date - datenum(1980,1,6) - s.gpsweek*7)*24*3600 + s.time(4)*3600 + s.time(5)*60 + s.time(6);

% List of PRNs in current epoch
s.PRN = NaN*ones(size(s.PRN));
s.NumChannels = str2num (line(31:32));
if s.NumChannels > 12
    line2 = fgetl(fid);
    line = [line line2(33:end)];
end;

for i=1:1:s.NumChannels
    s.PRN(i) = str2num (line(31+i*3:32+i*3));
end;

% Remaining lines (observations)
s.Observations = NaN*ones(size(getfield(s, 'Observations')));

for (i=1:1:s.NumChannels);
    line = fgetl (fid);
    if length(line) < 80 % Check if the line is a full line (80 characters)
        line(length(line) + 1:80) = '0'; % Pad with '0' to get a full line for easier reading purpose
    end;
    
    % Read another line if more than 5 observation types
    line2 = '';    
    if rnxh.NumberOfObsTypes > 5;
        line2 = fgetl(fid);
        line = char(line,line2);
    end;
    
    % Read observations
    for j = 1:1:length(rnxh.ObsTypeIndex)
        tmp = rnxh.ObsTypeIndex(j);
        % Take out observation of satellite i and type with index j
        s.Observations(i,j) = str2double(line(fix((tmp-1)/5) + 1,mod(tmp-1,5)*16 + 1:mod(tmp-1,5)*16 + 14));
        LLI = 0; %str2num(line(fix((tmp-1)/5) + 1,mod(tmp-1,5)*16 + 15));
        % Check if Anti-Spoofing is on
        if LLI >= 4;
            s.ASFlag(i,j) = 1;
        else
            s.ASFlag(i,j) = 0;
        end;
    end;
end;

% -------------------------------------------------------------------------
% END
