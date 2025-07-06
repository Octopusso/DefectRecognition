% Define source and destination folders
srcFolder = fullfile(pwd, 'Matlab_Import');
dstFolder = fullfile(srcFolder, 'Training_1');

% Create the destination folder if it doesn't exist
if ~exist(dstFolder, 'dir')
    mkdir(dstFolder);
end

% Get list of all .mat files in source folder
allFiles = dir(fullfile(srcFolder, '*.mat'));

% Define regex pattern for G[1-9]_P5_case ending in 2 (e.g., case32)
pattern = '^G[1-9]_P5_case\d*2\.mat$';
perfectFile = 'G0_P5_case_perfect.mat';

% Step 1: Filter and copy matching files
for i = 1:length(allFiles)
    fname = allFiles(i).name;
    if ~isempty(regexp(fname, pattern, 'once')) || strcmpi(fname, perfectFile)
        copyfile(fullfile(srcFolder, fname), fullfile(dstFolder, fname));
    end
end

% Step 2: Read and stack IncFeaturesTable
trainingFiles = dir(fullfile(dstFolder, '*.mat'));
allTables = {};

for i = 1:length(trainingFiles)
    fpath = fullfile(dstFolder, trainingFiles(i).name);
    data = load(fpath);
    if isfield(data, 'IncFeaturesTable')
        allTables{end+1} = data.IncFeaturesTable;
    else
        warning('No IncFeaturesTable in file: %s', trainingFiles(i).name);
    end
end

% Step 3: Combine and save as IncData.csv
if ~isempty(allTables)
    fullTable = vertcat(allTables{:});
    outPath = fullfile(dstFolder, 'IncData.csv');
    writetable(fullTable, outPath);
    fprintf('✅ IncData saved to %s\n', outPath);
else
    warning('⚠️ No IncFeaturesTable variables found to combine.');
end
