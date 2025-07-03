close all;
clear;
clc;
%%
% Define folder
folderPath = 'Matlab_Import';

% Match all target files
files = dir(fullfile(folderPath, 'G7_P*_case71.mat'));
if isempty(files)
    error('No matching files found in %s', folderPath);
end

% Fixed sampling rate
Fs = 480;       

% Bandpass filter design: 29–51 Hz, 4th-order Butterworth
% bp_low  = 10;
% bp_high = 100;
% [b, a] = butter(4, [bp_low, bp_high] / (Fs/2), 'bandpass');

% Column to analyze
target_column = 4;

for k = 1:numel(files)
    S = load(fullfile(folderPath, files(k).name));
    if ~isfield(S, 'T_upsampled')
        warning('Skipping %s: T_upsampled not found', files(k).name);
        continue;
    end

    sig = S.T_upsampled{:, target_column};
    if isempty(sig) || all(sig==0)
        warning('Skipping %s: Empty or constant signal', files(k).name);
        continue;
    end

    % ———— New: Time-domain bandpass filtering ————
    sig_bp = filtfilt(b, a, sig);

    % FFT computation
    L  = numel(sig_bp);
    Y  = fft(sig_bp);
    P2 = abs(Y / L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2 * P1(2:end-1);
    f  = (0:floor(L/2)) * (Fs / L);

    % Plot (no longer removing frequency range)
    figure('Name', files(k).name, 'NumberTitle', 'off');
    plot(f, P1, 'LineWidth', 1.2);
    title(['FFT of Bandpass(29–51Hz): ', files(k).name], 'Interpreter', 'none');
    xlabel('Frequency (Hz)');
    ylabel('|P1(f)|');
    xlim([0, Fs/2]);
    grid on;
end
