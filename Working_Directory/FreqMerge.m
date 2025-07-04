clc;
clear;

% Define folder path
folderPath = fullfile('Matlab_Import', 'Training_freq');

% Get all .mat files in the folder
matFiles = dir(fullfile(folderPath, '*.mat'));

% Initialize empty table
allFeatures = table();

% Loop over files
for k = 1:numel(matFiles)
    filePath = fullfile(folderPath, matFiles(k).name);
    fprintf('Loading %s\n', matFiles(k).name);
    
    % Load the .mat file
    S = load(filePath);
    
    % Check for existence of featureTable_freq
    if isfield(S, 'featureTable_freq')
        allFeatures = [allFeatures; S.featureTable_freq];
    else
        warning('featureTable_freq not found in %s', matFiles(k).name);
    end
end

% Write final table to CSV
outputFile = fullfile(folderPath, 'feature_freq.csv');
writetable(allFeatures, outputFile);

fprintf('Saved combined feature table to %s\n', outputFile);
