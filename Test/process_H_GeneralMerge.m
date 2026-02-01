function process_H_GeneralMerge(dataDir, outputDir)
%PROCESS_H_GENERALMERGE Merges all feature tables into a single CSV.
%   Inputs:
%       dataDir   - Directory containing the .mat files with General_Features.
%       outputDir - Directory where the final 'General_Data.csv' will be saved.

matFiles = dir(fullfile(dataDir, '*.mat'));

% Initialize an empty table to store combined data
combinedData = table();

% Loop through each .mat file
for i = 1:length(matFiles)
    matFilePath = fullfile(dataDir, matFiles(i).name);
    data = load(matFilePath);
    
    if isfield(data, 'General_Features')
        combinedData = [combinedData; data.General_Features];
    else
        warning('General_Features table not found in %s', matFiles(i).name);
    end
end

% Create output directory if it doesn't exist
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Save the combined table as a CSV file
outputFile = fullfile(outputDir, 'General_Data.csv');
writetable(combinedData, outputFile);

fprintf('Step H (General Merge) completed. Combined dataset saved to: %s\n', outputFile);

end
