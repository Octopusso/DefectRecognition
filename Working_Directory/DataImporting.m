% Get path to the folder where this script is located
scriptFolder = fileparts(mfilename('fullpath'));

% Input and output folders
measurementFolder = fullfile(scriptFolder, 'Measurement Data');
outputFolder = fullfile(scriptFolder, 'Matlab_Import');

% Create output folder if it doesn't exist
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Define ranges
groupFolders = 1:9; 
phones = 1:5;
caseStarts = 1:9;    % → case11, case21, ..., case91
caseOffsets = 0:5;   % → +0 to +5 → case11 to case16, etc.

% Optional: structure to store all data in memory
allData = struct;

for g = groupFolders
    groupFolderName = sprintf('G%d', g);
    groupFolderPath = fullfile(measurementFolder, groupFolderName);

    for p = phones
        for offset = 0:5
            caseNum = g * 10 + 1 + offset;

            % Skip caseX4 (e.g., case14, case24, ..., case94)
            if mod(caseNum, 10) == 4
                continue;
            end

            filename = sprintf('G%d_P%d_case%d.xls', g, p, caseNum);
            filePath = fullfile(groupFolderPath, filename);

            if isfile(filePath)
                try
                    T = readtable(filePath, 'VariableNamingRule', 'preserve');

                    % Shift first column (assumed time)
                    T{:,1} = T{:,1} - T{1,1};

                    % Save .mat file
                    matFileName = strrep(filename, '.xls', '.mat');
                    savePath = fullfile(outputFolder, matFileName);
                    save(savePath, 'T');

                    % Optional: store in memory
                    key = sprintf('G%d_P%d_case%d', g, p, caseNum);
                    allData.(key) = T;

                catch ME
                    warning('Error reading %s: %s', filename, ME.message);
                end
            else
                fprintf('File not found: %s\n', filePath);
            end
        end
    end
end

fprintf('All the data except data from casex4 loaded succesfully!')
clear all; % just for having cleared workspace from importing files variables that we needed