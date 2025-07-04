% Define paths
srcFolder = fullfile(pwd, 'Matlab_Import');
dstFolder = fullfile(srcFolder, 'Training_1');

% Create the destination folder if it doesn't exist
if ~exist(dstFolder, 'dir')
    mkdir(dstFolder);
end

% Get list of all .mat files
allFiles = dir(fullfile(srcFolder, '*.mat'));

% Define regex pattern for P5 files with casex2 or casex3, and add the perfect file
pattern = '^G[1-9]_P5_case[1-9][23]\.mat$';
perfectFile = 'G0_P5_case_perfect.mat';

% Step 1: Filter and copy matching files
for i = 1:length(allFiles)
    fname = allFiles(i).name;
    if ~isempty(regexp(fname, pattern, 'once')) || strcmp(fname, perfectFile)
        copyfile(fullfile(srcFolder, fname), fullfile(dstFolder, fname));
    end
end

% Step 2: Read and stack feature tables
trainingFiles = dir(fullfile(dstFolder, '*.mat'));
allTables = {};

for i = 1:length(trainingFiles)
    fpath = fullfile(dstFolder, trainingFiles(i).name);
    data = load(fpath);
    if isfield(data, 'featuresTable')
        allTables{end+1} = data.featuresTable;
    else
        warning('No featuresTable in file: %s', trainingFiles(i).name);
    end
end

% Step 3: Combine and save as CSV
if ~isempty(allTables)
    fullTable = vertcat(allTables{:});
    outPath = fullfile(dstFolder, 'training_features.csv');
    writetable(fullTable, outPath);
    fprintf('✅ Combined featuresTable saved to %s\n', outPath);
else
    warning('⚠️ No feature tables found to combine.');
end
