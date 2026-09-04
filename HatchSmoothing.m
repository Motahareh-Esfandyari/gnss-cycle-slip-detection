%% ========================================================================
%  GNSS-CycleSlip : Cycle Slip Detection in GNSS Carrier Phase Observations
%  ------------------------------------------------------------------------
%  Script  : HatchSmoothing.m  (completed version of smoothing.m)
%  Purpose : Carrier-phase smoothing of GPS code pseudoranges with the
%            (window-limited) Hatch filter:
%
%              Psm(k) = C1(k)/k + ((k-1)/k) * ( Psm(k-1) + L1(k) - L1(k-1) )
%
%            The smoothing window k grows up to a maximum of M epochs to
%            limit code-carrier ionospheric divergence. The filter is
%            reset at the start of every new tracking arc: satellite
%            rise, data gap, or a cycle slip detected on the
%            geometry-free combination GF = L1 - L2 (threshold 0.05 m),
%            consistent with CycleSlipDetection.m.
%  Inputs  : ade20030.10o (RINEX v2.10 observation file, 30 s interval)
%  Outputs : Psm  - smoothed pseudoranges [m], epochs x 32 PRNs
%            Figures comparing raw and smoothed code-minus-carrier noise
%  ------------------------------------------------------------------------
%  Author  : Motahareh Esfandyari-Kaloukan
%  ========================================================================

clear
close all
clc
format long g

%% Constants and settings

spl = 299792458 ;

f1 = 1575.42e6 ; w1 = spl/f1 ;      % L1 wavelength [m]
f2 = 1227.60e6 ; w2 = spl/f2 ;      % L2 wavelength [m]

M       = 100 ;                     % maximum Hatch window length [epochs]
slipThr = 0.05 ;                    % cycle slip threshold on d(GF) [m]

%% Read RINEX observation file (code C1 + phases L1, L2)

fid  = fopen ('ade20030.10o', 'rt') ;
rnxh = rnxheader (fid, 'C1L1L2') ;

i = 1 ;
while feof(fid) ~= 1
    [s(i,1), ierr(i,1)] = rnxobs (fid, rnxh) ;
    i = i + 1 ;
end
fclose (fid) ;

nEp = size (s, 1) ;

C1 = NaN (nEp, 32) ; PHI1 = C1 ; PHI2 = C1 ;

for i = 1:nEp
    C1   (i, s(i).PRN) = s(i).Observations (:, 1)' ;   % code [m]
    PHI1 (i, s(i).PRN) = s(i).Observations (:, 2)' ;   % phase [cycles]
    PHI2 (i, s(i).PRN) = s(i).Observations (:, 3)' ;
end

L1 = w1 .* PHI1 ;                   % phases in meters
L2 = w2 .* PHI2 ;

%% Cycle slip flags from the geometry-free combination

GF   = L1 - L2 ;
dGF  = [NaN(1, 32) ; diff(GF)] ;
slip = abs (dGF) >= slipThr ;       % true where a slip is detected
                                    % (NaN compares false -> no flag)

%% Hatch filter, per satellite

Psm = NaN (nEp, 32) ;

h = waitbar (0, 'Hatch smoothing ...') ;

for sat = 1:32
    
    k = 0 ;                         % current window length (0 = no arc)
    
    for i = 1:nEp
        
        % No valid observation -> close the current arc
        if isnan (C1(i, sat)) || isnan (L1(i, sat))
            k = 0 ;
            continue
        end
        
        % New arc: first epoch, satellite rise after a gap, or cycle slip
        if k == 0 || isnan (L1(i - 1, sat)) || slip (i, sat)
            k = 1 ;
            Psm (i, sat) = C1 (i, sat) ;
        else
            k = min (k + 1, M) ;    % window-limited Hatch
            Psm (i, sat) = C1 (i, sat) / k + ...
                ((k - 1) / k) * (Psm (i - 1, sat) + L1 (i, sat) - L1 (i - 1, sat)) ;
        end
        
    end
    
    waitbar (sat / 32)
    
end

close (h)

%% Plots: raw vs smoothed code-minus-carrier
%  C1 - L1 contains code noise + multipath + 2x ionosphere (the phase
%  ambiguity is a constant per arc), so it is the standard way to make
%  the noise reduction of the Hatch filter visible.

CmC_raw = C1  - L1 ;
CmC_smt = Psm - L1 ;

time = (0:nEp - 1)' .* rnxh.Interval ./ 3600 ;      % [hours]

% Pick the first four PRNs that actually have data
prns = find (any (~isnan (C1), 1)) ;
prns = prns (1:min(4, end)) ;

figure (1)
for p = 1:length (prns)
    
    sat = prns (p) ;
    
    subplot (2, 2, p)
    plot (time, CmC_raw (:, sat) - mean (CmC_raw (:, sat), 'omitnan'), '.', ...
          'MarkerSize', 4), hold on
    plot (time, CmC_smt (:, sat) - mean (CmC_smt (:, sat), 'omitnan'), '.', ...
          'MarkerSize', 4)
    xlabel ('Time [hour]'), ylabel ('Code - carrier [m]')
    title (['PRN ', num2str(sat)])
    legend ('Raw C1', 'Hatch smoothed'), grid on
    
end

% Summary: noise (std of detrended code-minus-carrier) per satellite
sigRaw = NaN (32, 1) ; sigSmt = NaN (32, 1) ;
for sat = 1:32
    if any (~isnan (CmC_raw (:, sat)))
        sigRaw (sat) = std (diff (CmC_raw (:, sat)), 'omitnan') / sqrt(2) ;
        sigSmt (sat) = std (diff (CmC_smt (:, sat)), 'omitnan') / sqrt(2) ;
    end
end

figure (2)
bar ([sigRaw, sigSmt])
xlabel ('PRN'), ylabel ('Epoch-difference noise [m]')
legend ('Raw C1', 'Hatch smoothed')
title (['Code noise before/after Hatch smoothing (M = ', num2str(M), ' epochs)'])
grid on

fprintf ('Mean code noise  raw      : %6.3f m\n', mean (sigRaw, 'omitnan')) ;
fprintf ('Mean code noise  smoothed : %6.3f m\n', mean (sigSmt, 'omitnan')) ;
