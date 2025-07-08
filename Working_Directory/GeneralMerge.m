% Get list of all .mat files in the Matlab_Import folder
folderPath = 'Matlab_Import';
matFiles = dir(fullfile(folderPath, '*.mat'));

% Initialize an empty table to store combined data
combinedData = table();

% Loop through each .mat file
for i = 1:length(matFiles)
    % Load the .mat file
    matFilePath = fullfile(folderPath, matFiles(i).name);
    data = load(matFilePath);
    
    % Check if General_Features table exists in the .mat file
    if isfield(data, 'General_Features')
        % Append the General_Features table to combined Data
        combinedData = [combinedData; data.General_Features];
    else
        warning('General_Features table not found in %s', matFiles(i).name);
    end
end

% Create output directory if it doesn't exist
outputDir = fullfile(folderPath, 'Training');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Save the combined table as a CSV file
outputFile = fullfile(outputDir, 'General_Data.csv');
writetable(combinedData, outputFile);

disp('Combined dataset saved as General_Data.csv');