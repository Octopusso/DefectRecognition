clc;
clear;

% Define file name pattern
filePattern = 'G9_P1_case9*.xls';

% Get list of matching files in current folder
files = dir(filePattern);

% Loop through each file
for i = 1:length(files)
    filename = files(i).name;
    fprintf('Processing file: %s\n', filename);
    
    % Read data from the first sheet
    data = readmatrix(filename, 'Sheet', 1);
    
    % Extract time column (assumed to be first column)
    time = data(:, 1);
    
    % Compute time differences
    dt = diff(time);
    
    % Estimate sampling rate as average of 1/dt
    avg_dt = mean(dt);
    fs = 1 / avg_dt;

    fprintf('Estimated sampling rate for %s: %.2f Hz\n\n', filename, fs);
end
