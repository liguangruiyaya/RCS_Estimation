%% Simulation SFCW Radar RCS estimation
% Bachelor thesis by Sebastian M�ller

clear all % clear all variables
clc; % clear console

disp('**** SIMULATION SFCW RADAR ****')
disp(' ')
addpath Toolbox/

%% Parameters
% natural constants

c = 299792458; % speed of light [m/s]

% object constants

R = 15;     % distance radar - target [m]
v = 0;      % speed of target [m/s] (v>0 -> moves towards receiver)
sigma = 5;  % radar cross section [m^2] >0
swerling = 1; % used swerling model (1 or 3)

% radar constants

f_a = 125e3; % sampling frequency [Hz]
f_0 = 24.125e9;   % center frequency [Hz]
B = 500e6;     % sweep frequency [Hz]
T_f = 10e-3;  % sweep time per flank [s]
n = 128;      % frequency steps per flank [1]

P_s = 100e-3;  % transmission power [W]
P_n = 1e-9; % noise power [W]
G_T = 20;  % transmitting antenna gain [dBi]
G_R = 20;  % receiving antenna gain [dBi]

N_fft = 4096; % FFT Size (big is good)
k = 10; % Number of measurements

%% Calculate remaining data

G_T = db2pow(G_T);  % calculate magnitude of gain
G_R = db2pow(G_R);  % calculate magnitude of gain

T = 2*T_f; % calculate measure time
t = 0:1/f_a:T-1/f_a; % create time vector

lambda = c / f_0; % wavelength

tau = 2*R/c;    % time radar delay
f_D = 2*v*f_0/c;    % doppler frequency

f_min = f_0 - B/(2*n); % calculate minimum frequency
fig = figure(1); % create figure

df = B/n;   % frequency step
dt = T_f/n; % time step
R_max = c/(4*df)    % maximum unambiguous distance
dR = c/(2*B)    % minimum resolvable distance

t_jump = dt:dt:T; % create time vector of sampling points

%% check values

if R > c/4 * n/B
    disp(['WARNING: R too big for unambiguous calculation. R has to be smaller than ' , num2str(c/2*n/B) , ' m']);
    disp(' ');
end
if R < c/2 * 1/B
    disp('WARNING: R too small for radial resolution. Use bigger sweep frequency or increase R.');
    disp(' ');
end
if f_a/2 < f_D
    disp('WARNING: Sampling freq too small for doppler freq!');
    disp(' ');
end
if v < c/(2*f_0*T_f)
    disp('WARNING: v too small for speed resolution! Use longer sweep time.');
    disp(' ');
end

%% simulation data

c_r = (sqrt(G_T)*sqrt(G_R)*lambda*sqrt(sigma))/((4*pi)^(3/2)*R^2); ...
% attenuation because of radar equation

% Check possibility
if c_r > 1
    c_r = 1;
end

% baseband signal (analytical)

% q is the signal at the output of the IQ-Receiver with q = s .* conj(r).
% This is done analytically, because the sampling
% rate of the system is too small to calculate exactly enough.
%A_q = c_r * P_s; % Amplitude of baseband signal

R_est = [];
sigma_est = [];

[phi_bb] = baseband_phase(f_min, tau, dt, df, T); % get phase of baseband signal
%% Estimation

% loop measurements
for i=1:1:k
    
    % Create swerling models for received power

    if swerling == 1
        P_r = exprnd(c_r^2 * P_s, 1, length(t_jump)); % random exponential values
    elseif swerling == 3
        P_r = chi2rnd(3, 1, length(t_jump)) * (c_r^2 * P_s)/3; % random chi square values
    else
        P_r = c_r^2 * P_s; % case no swerling (0)
    end

    A_q = sqrt(P_r .* P_s); % calculate baseband amplitude
    
    q_orig = A_q .* exp(1i*(phi_bb - 2*pi*f_D * t_jump)); % baseband signal ...
        % consisting of attenuation, analytical phase and doppler phase
    
    q = q_orig + wgn(1, length(q_orig), pow2db(P_n), 'complex'); % add random noise for every measurement

    [q_fft, f_fft] = spektrum(q, N_fft, 1/dt); % Calculate fft and frequency shift
    % find peaks
    [peak_y, peak_x] = findpeaks(q_fft, 'NPEAKS', 1, 'SORTSTR', 'descend'); ...
        % finds highest peak in spectrum

    fR = abs(f_fft(:,round(peak_x))); % Get Highest peak freqency

    % Calculate estimated v

    v_est = v; % (not implemented yet)

    % Calculate estimated R
    % (we ware still assuming v = 0)

    kappa = fR * dt*n; % calculate spatial frequency
    R_est = [R_est c/(2*B)* kappa]; % estimate current R

    % RCS Estimation

    sigma_est = [sigma_est estimate_sigma(q, P_s, (4*pi)^3/(G_R*G_T*lambda^2), R_est(i))];

end

%RCS Debug plot
subplot(1,2,1);
plot(R_est,'o')
hold on
plot(repmat(R, length(R_est)));
hold off
title('Estimated R Values');
ylabel('R [m]');
xlabel('Measurement number');

%RCS Debug plot
subplot(1,2,2);
plot(sigma_est,'o')
hold on
plot(repmat(sigma, length(sigma_est)));
hold off
title('Estimated RCS Values');
ylabel('\sigma [m^2]');
xlabel('Measurement number');

% Calculate average MLE

R_est = mean(R_est);
sigma_est = mean(sigma_est);

% Error calculation
if R == 0
    error_R = '---';
else
    error_R = num2str((R_est-R)/R*100);
end

if v == 0
    error_v = '---';
else
    error_v = num2str((v_est-v)/v*100);
end
    
error_sigma = num2str((sigma_est-sigma)/sigma*100);
%% Plot

%figure(fig+1);
% 
% %plot abs
% subplot(2,1,1);
% plot(t_jump, abs(q));
% title('baseband signal abs');
% xlabel('t/s');
% ylabel('Ampl.');
% %
% %plot phase
% subplot(2,1,2);
% stem(t_jump, unwrap(angle(q)), '-x');
% title('baseband signal phase');
% xlabel('t/s');
% ylabel('Phase/rad');
% % 
% PSD Plot
% subplot(2,1,2);
% x_fa = 0:1/dt/N_fft:1/dt-1/dt/N_fft;
% plot(f_fft, q_fft.^2, '.-')
% %axis([-fn fn 0 (max(y)-min(y))/4*1.1])
% title('power spectral density')
% ylabel('Amplitude')
% xlabel(['Aufl�sung: ',num2str(1/dt/N_fft),' Hz Frequenz in Hz'])
% grid

% SFCW frequency plot
% figure(fig+1);
% plot(t, f_sfcw);
% title('SFCW Frequency');
% xlabel('t/s');
% ylabel('f/Hz');

% RV Plot
% figure(fig+1);
% R_vec = linspace(R-100, R+100, 1000); % generate R vector for RV plot
% v_vec = R_vec .* B/(f_0 * T_f) - c*kappa/(2*f_0*T_f); % generate v vector for RV plot
% plot(R_vec, v_vec, R_est, v_est, 'rx', R, v, 'gx');
% title('RV-Plot');
% xlabel('R / m');
% ylabel('v / m/s');
% legend('RV-Plot', 'Estimated', 'Actual');

%% print results

fprintf('Symbol \tValue (real) \tValue (est) \tError (rel)\n');
fprintf('-----------------------------------------------------\n')
fprintf(['v\t', num2str(v), '\t\t', num2str(v_est), '\t\t', error_v, ' %% \n']);
fprintf(['R\t', num2str(R), '\t\t', num2str(R_est), '\t\t', error_R, ' %% \n']);
fprintf(['RCS\t', num2str(sigma), '\t\t', num2str(sigma_est), '\t\t', error_sigma, ' %% \n']);
