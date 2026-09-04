%% ========================================================================
%  GNSS-CycleSlip : Cycle Slip Detection in GNSS Carrier Phase Observations
%  ------------------------------------------------------------------------
%  Function: rnxheader.m
%  Purpose : Reads the header of a RINEX v2.10 GPS observation file and
%            returns the indices of the requested observation types.
%  ------------------------------------------------------------------------
%  Used by                 : Motahareh Esfandyari-Kaloukan
%  Original implementation : LaQ, MGP - TU Delft, 2002 (see credit below)
%  ========================================================================

function [rnxh] = rnxheader (fid, obstypes)
% RNXHEADER.M: read header of RINEX observation file
% 
% SYNTAX:   
%       rnxheader = rnxheader (fid, obstypes);
%
% DESCRIPTION:
%       fid     :   input       File identifier of RINEX file
%       obstypes:   input       String of requested observation types (without space between types)
%       rnxh    :   output      Structure with the information from the RINEX header
%
% NOTE: 
%       1. For RINEX version 2.10 and GPS observation files only
%       2. RINEX file must not contain more than 18 observation types
%
% EXAMPLE:
%       fid = fopen ('yp011254.94o', 'rt');
%       [rnxh] = rnxheader (fid, 'C1L1L2P1P2');
%
% CREATED:
%                      -------------------
%                       21-10-2002 by LaQ
%                        MGP - TU Delft
%                      -------------------

% START:
% -------------------------------------------------------------------------

% Create structure for RINEX header
rnxh = struct ( 'MainVersion', NaN,             ...
		        'SubVersion', NaN,              ...
		        'SatSystemStr', '',             ...
		        'PGMStr', '',                   ...
        		'RunByStr', '',                 ...
		        'DateStr', '',                  ...
		        'MarkerNameStr', '',            ...
		        'MarkerNumberStr', '',          ...
		        'ObserverStr', '',              ...
		        'AgencyStr', '',                ...
		        'ReceiverNumberStr', '',        ...
		        'ReceiverTypeStr', '',          ...
		        'ReceiverVersionStr', '',       ...
		        'AntennaNumberStr', '',         ...
		        'AntennaTypeStr', '',           ...
		        'ApproxCRD', NaN*ones(3,1),     ...
		        'AntennaDelta', NaN*ones(3,1),  ...
		        'WaveLengthFac', NaN*ones(2,1), ...
		        'FirstObs', NaN*ones(6,1),      ...
                'LastObs', NaN*ones(6,1),       ...
                'Y2KCorrection', NaN,           ...
		        'NumberOfObsTypes', NaN,        ...
		        'NumberOfRequestedTypes', NaN,  ...
                'ObsTypeIndex', NaN,            ...
		        'Interval', NaN,                ...
                'ClkOffsAppl', 0);

% Set default value
rnxh.Interval = 30;

% Read the header
while feof(fid)~=1;
  buffer = fgetl (fid);  
  if (~ischar (buffer))
      error ('Empty line in RINEX observation file header');
  end;
  
  switch deblank(buffer(61:end))
      case 'RINEX VERSION / TYPE'
          if (strcmp (buffer(21:21), 'O') == 0); % Check if it is a GPS observation file
              error ('This is not a RINEX observation file');
          end;
          rnxh.MainVersion  = str2num (buffer(1:6));
          rnxh.SubVersion   = str2num (buffer(8:9));
          rnxh.SatSystemStr = buffer (41:41);
        
      case 'PGM / RUN BY / DATE'
          rnxh.PGMStr   = buffer ( 1:20);
          rnxh.RunByStr = buffer (21:40);
          rnxh.DateStr  = buffer (41:60);

      case 'COMMENT'
          % Do nothing, ignore comments
          
      case 'MARKER NAME'
          rnxh.MarkerNameStr = deblank(buffer(1:60));
          
      case 'MARKER NUMBER'
          rnxh.MarkerNumberStr = deblank(buffer (1:21));
          
      case 'OBSERVER / AGENCY'
          rnxh.ObserverStr = deblank(buffer ( 1:20));
          rnxh.AgencyStr   = deblank(buffer (21:60));
          
      case 'REC # / TYPE / VERS'
          rnxh.ReceiverNumberStr  = deblank(buffer ( 1:20));
          rnxh.ReceiverTypeStr    = deblank(buffer (21:40));
          rnxh.ReceiverVersionStr = deblank(buffer (41:60));

      case 'ANT # / TYPE'
          rnxh.AntennaNumberStr   = deblank(buffer ( 1:20));
          rnxh.AntennaTypeStr     = deblank(buffer (21:40));
          
      case 'APPROX POSITION XYZ'
          rnxh.ApproxCRD(1) = str2num (buffer( 1:14));
          rnxh.ApproxCRD(2) = str2num (buffer(15:28));
          rnxh.ApproxCRD(3) = str2num (buffer(29:42));
          
      case 'ANTENNA: DELTA H/E/N'
          rnxh.AntennaDelta(1) = str2num (buffer( 1:14));
          rnxh.AntennaDelta(2) = str2num (buffer(15:28));
          rnxh.AntennaDelta(3) = str2num (buffer(29:42));
          
      case 'WAVELENGTH FACT L1/2'
          rnxh.WaveLengthFac(1) = str2num (buffer( 1: 6));
          rnxh.WaveLengthFac(2) = str2num (buffer( 7:12));
          
      case '# / TYPES OF OBSERV'
          rnxh.NumberOfObsTypes = str2num (buffer(1:6));
          if rnxh.NumberOfObsTypes > 9 % Read another line if more than 9 types of observation
              tmpbuffer = fgetl(fid);
              buffer = [buffer tmpbuffer(7:60)];
          end;
          rnxh.NumberOfRequestedTypes = size(obstypes,2)/2;
        
          % Get the index of each requested observation type in the
          % observation file 
          % Example:
          %   obstypes = 'C1L1S1'
          %   Types in the file: C1    L1    L2    P2    P1    S1    S2
          %   rnxheader(fid, obstypes) will return the indices of C1,L1 and S1 in the file:
          %       Index of C1 in data  :     1
          %       Index of L1 in data  :     2
          %       Index of S1 in data  :     6
          rnxh.ObsTypeIndex = [];
          for i=1:2:size(obstypes,2)
              pos = findstr(buffer, obstypes(i:i+1));
              if ~isempty(pos)                  
                  rnxh.ObsTypeIndex = [rnxh.ObsTypeIndex (pos - 5)/6];
              else
                  fprintf ('%s is not included in data\n',obstypes(i:i+1));
              end;
          end;
          
      case 'INTERVAL'
          rnxh.Interval = str2num (buffer(1:10));
          
      case 'TIME OF FIRST OBS'
          rnxh.FirstObs(1) = str2num (buffer( 1: 6));
          rnxh.FirstObs(2) = str2num (buffer( 7:12));
          rnxh.FirstObs(3) = str2num (buffer(13:18));
          rnxh.FirstObs(4) = str2num (buffer(19:24));
          rnxh.FirstObs(5) = str2num (buffer(25:30));
          rnxh.FirstObs(6) = str2num (buffer(31:43));
          
          % Y2K correction
          if rem(rnxh.FirstObs(1),100) < 80
              rnxh.Y2KCorrection = 100;
          else
              rnxh.Y2KCorrection = 0;
          end;
          
      case 'TIME OF LAST OBS'
          rnxh.LastObs(1) = str2num (buffer( 1: 6));
          rnxh.LastObs(2) = str2num (buffer( 7:12));
          rnxh.LastObs(3) = str2num (buffer(13:18));
          rnxh.LastObs(4) = str2num (buffer(19:24));
          rnxh.LastObs(5) = str2num (buffer(25:30));
          rnxh.LastObs(6) = str2num (buffer(31:43));
          
      case 'PRN / # OF OBS'
          % Ignored!
          
      case '# OF SATELLITES'
          % Ignored!
          
      case 'LEAP SECONDS'
          % Ignored!
          
      case 'RCV CLOCK OFFS APPL'
          rnxh.ClkOffsAppl = 1;
          
      case 'END OF HEADER'
          break;
      
      case ''
          break;
          
      otherwise
          fprintf (2,'ERROR: Unrecognized line in RINEX header!!\n');
          fprintf (2,'BUFFER: %s\n',buffer(61:end));
          choice = input ('What would you like to do? Continue, Skip reading header or Interrupt? C/S/I [C]:','s');
          switch upper (choice)
              case 'S'
                  break;
                  
              case 'I'
                  error ('Interrupted by user');
                  
              otherwise
                  % Ignore the line
          end;
  end;
  
end;
for i=1:1:length(rnxh.ObsTypeIndex);
fprintf ('Index of %s in data  : %5d\n',obstypes(2*i-1:2*i),rnxh.ObsTypeIndex(i));
end;

% -------------------------------------------------------------------------
% END
