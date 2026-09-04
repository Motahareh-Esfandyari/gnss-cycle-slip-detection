%% ========================================================================
%  GNSS-CycleSlip : Cycle Slip Detection in GNSS Carrier Phase Observations
%  ------------------------------------------------------------------------
%  Script  : CycleSlipDetection.m
%  Purpose : Detects cycle slips in dual-frequency GPS carrier phase data.
%            Reads a RINEX v2.10 observation file (rnxheader.m/rnxobs.m),
%            converts L1/L2 phases to meters, forms the geometry-free
%            combination GF = L1 - L2 (zero-mean per satellite), and flags
%            a cycle slip wherever the epoch-to-epoch difference of GF
%            exceeds 0.05 m. Satellite rise ("dawn" = 9) and set
%            ("sunset" = -9) events are also flagged. Plots the status and
%            the differenced GF series with the +/-0.05 m thresholds for
%            all 32 PRNs.
%  Inputs  : ade20030.10o (RINEX v2.10 observation file, 30 s interval)
%  ------------------------------------------------------------------------
%  Author  : Motahareh Esfandyari-Kaloukan
%  ========================================================================

clear
close all
clc
format long g

spl = 299792458 ;

f1 = 1575.42e6 ; w1 = spl/f1 ;
f2 = 1227.60e6 ; w2 = spl/f2 ;

fid  = fopen ('ade20030.10o','rt') ;
rnxh = rnxheader(fid,'L1L2') ;

i = 1 ;
while feof(fid)~=1
    [s(i,1),ierr(i,1)] = rnxobs (fid,rnxh) ;
    i = i+1 ;
end

PHI1 = NaN(size(s, 1), 32) ; PHI2 = PHI1 ;

for i = 1:size(s, 1)
    
    l1 = s(i).Observations (:, 1) ;
    l2 = s(i).Observations (:, 2) ;
    
    PHI1 (i, s(i).PRN) = l1' ;
    PHI2 (i, s(i).PRN) = l2' ;
    
end

L1 = w1 .* PHI1 ; 
L2 = w2 .* PHI2 ;

for i = 1:32
    
    l1m = [] ; l2m = [] ;
    
    for j = 1:size (L1, 1)
        if isnan(L1 (j, i)) ~= 1
            l1m = [l1m; L1(j, i)] ;
        end
    end
    
    for j = 1:size (L2, 1)
        if isnan(L2 (j, i)) ~= 1
            l2m = [l2m; L2(j, i)] ;
        end
    end
    
    L1m (:, i) = sum (l1m) ./ size (l1m, 1) ;
    L2m (:, i) = sum (l2m) ./ size (l2m, 1) ;
    
end

for i = 1:32
    
    L1_zm (:, i) = L1 (:, i) - L1m (:, i) ; 
    L2_zm (:, i) = L2 (:, i) - L2m (:, i) ; 
    
end

GF = L1_zm - L2_zm ; % Geometry Free

Diff = diff (GF) ;

cs = zeros (size(Diff, 1), 34) ;

for i = 2:size(s, 1)
    cs (i - 1, 1) = i - 1 ;
    cs (i - 1, 2) = i     ;
end

%  1 = cycle slip
%  0 = no cycle slip
%  9 = dawn
% -9 = sunset
%  NaN = no action

h = waitbar (0, 'cycle slip detection ...') ;

for sat = 1:32
    for i = 1:size (Diff, 1)
        if i == 1
            if isnan(Diff(i, sat)) == 1 && isnan(Diff(i + 1, sat)) ~= 1
                cs (i, 2 + sat) = 9 ;
            elseif isnan(Diff(i, sat)) == 1 && isnan(Diff(i + 1, sat)) == 1
                cs (i, 2 + sat) = NaN ;
            elseif isnan(Diff(i, sat)) ~= 1 && isnan(Diff(i + 1, sat)) == 1
                if abs(Diff(i, sat)) >= 0.05
                    cs (i, 2 + sat) = 1 ;
                else
                    cs (i, 2 + sat) = 0 ;
                end
                cs (i + 1, 2 + sat) = -9 ;
            elseif isnan(Diff(i, sat)) ~= 1 && isnan(Diff(i + 1, sat)) ~= 1
                if abs(Diff(i, sat)) >= 0.05
                    cs (i, 2 + sat) = 1 ;
                else
                    cs (i, 2 + sat) = 0 ;
                end
            end
        elseif i == size (Diff, 1)
            if isnan(Diff(i - 1, sat)) == 1 && isnan(Diff(i, sat)) ~= 1
                if abs(Diff(i, sat)) >= 0.05
                    cs (i, 2 + sat) = 1 ;
                else
                    cs (i, 2 + sat) = 0 ;
                end
                cs (i - 1, 2 + sat) = 9 ;
            elseif isnan(Diff(i - 1, sat)) == 1 && isnan(Diff(i, sat)) == 1
                cs (i, 2 + sat) = NaN ;
            elseif isnan(Diff(i - 1, sat)) ~= 1 && isnan(Diff(i, sat)) == 1
                cs (i, 2 + sat) = -9 ;
            elseif isnan(Diff(i - 1, sat)) ~= 1 && isnan(Diff(i, sat)) ~= 1
                if abs(Diff(i, sat)) >= 0.05
                    cs (i, 2 + sat) = 1 ;
                else
                    cs (i, 2 + sat) = 0 ;
                end
            end
        else
            if isnan(Diff(i - 1, sat)) == 1 && isnan(Diff(i, sat)) == 1 && isnan(Diff(i + 1, sat)) == 1
                cs (i, 2 + sat) = NaN ;
            elseif isnan(Diff(i - 1, sat)) == 1 && isnan(Diff(i, sat)) ~= 1
                if abs(Diff(i, sat)) >= 0.05
                    cs (i, 2 + sat) = 1 ;
                else
                    cs (i, 2 + sat) = 0 ;
                end
                cs (i - 1, 2 + sat) = 9 ;
            elseif isnan(Diff(i, sat)) ~= 1 && isnan(Diff(i + 1, sat)) == 1
                if abs(Diff(i, sat)) >= 0.05
                    cs (i, 2 + sat) = 1 ;
                else
                    cs (i, 2 + sat) = 0 ;
                end
                cs (i + 1, 2 + sat) = -9 ;
            elseif isnan(Diff(i - 1, sat)) == 1 && isnan(Diff(i, sat)) == 1 && isnan(Diff(i + 1, sat)) ~= 1
                cs (i, 2 + sat) = 9 ;
            elseif isnan(Diff(i - 1, sat)) ~= 1 && isnan(Diff(i, sat)) == 1 && isnan(Diff(i + 1, sat)) == 1
                cs (i, 2 + sat) = -9 ;
            end
        end
    end
    waitbar (sat / 32)
end

close (h)

for i = 1:size (Diff, 1)
    for j = 1:32
        
        if isnan (Diff (i, j)) ~= 1
            if abs(Diff (i, j)) > 10
                Diff (i, j) = NaN ;
            end
        end
        
    end
end

time = 0:30:24 * 3600 ; time = time ./ 3600 ; time = time' ;
time (end, :) = [] ; time (end, :) = [] ;

h = waitbar (0, 'ploting ...') ;

for i = 1:8
    
    figure (i)
    
    subplot (2, 2, 1)

    plot (time, cs(:, 2 + 4 * i - 3), 'r--o')
    xlabel ('Time [hour]'), ylabel ('Satellite status') ;
    title (['satellite : ', num2str(4 * i - 3)])
    
    subplot (2, 2, 2)

    plot (time, cs(:, 2 + 4 * i - 2), 'r--o')
    xlabel ('Time [hour]'), ylabel ('Satellite status') ;
    title (['satellite : ', num2str(4 * i - 2)])
    
    subplot (2, 2, 3)

    plot (time, cs(:, 2 + 4 * i - 1), 'r--o')
    xlabel ('Time [hour]'), ylabel ('Satellite status') ;
    title (['satellite : ', num2str(4 * i - 1)])
    
    subplot (2, 2, 4)
    
    plot (time, cs(:, 2 + 4 * i - 0), 'r--o')
    xlabel ('Time [hour]'), ylabel ('Satellite status') ;
    title (['satellite : ', num2str(4 * i - 0)])
    
    waitbar (i / 8)
    
end

close (h)

h = waitbar (0, 'ploting ...') ;

for i = 1:8
    
    figure (i + 8)
    
    subplot (2, 2, 1)

    plot (time, Diff(:, 4 * i - 3), 'b.')
    xlabel ('Time [hour]'), ylabel ('Differential Geometric Free'), hold on
    ezplot ('0.05', [min(time), max(time)]), ezplot ('-0.05', [min(time), max(time)]) 
    title (['satellite : ', num2str(4 * i - 3)])
    
    subplot (2, 2, 2)

    plot (time, Diff(:, 4 * i - 2), 'b.')
    xlabel ('Time [hour]'), ylabel ('Differential Geometric Free'), hold on
    ezplot ('0.05', [min(time), max(time)]), ezplot ('-0.05', [min(time), max(time)]) 
    title (['satellite : ', num2str(4 * i - 2)])
    
    subplot (2, 2, 3)

    plot (time, Diff(:, 4 * i - 1), 'b.')
    xlabel ('Time [hour]'), ylabel ('Differential Geometric Free'), hold on
    ezplot ('0.05', [min(time), max(time)]), ezplot ('-0.05', [min(time), max(time)]) 
    title (['satellite : ', num2str(4 * i - 1)])
    
    subplot (2, 2, 4)
    
    plot (time, Diff(:, 4 * i - 0), 'b.')
    xlabel ('Time [hour]'), ylabel ('Differential Geometric Free'), hold on
    ezplot ('0.05', [min(time), max(time)]), ezplot ('-0.05', [min(time), max(time)])  
    title (['satellite : ', num2str(4 * i - 0)])
    
    waitbar (i / 8)
    
end

close (h)
