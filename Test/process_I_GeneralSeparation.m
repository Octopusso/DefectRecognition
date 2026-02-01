function process_I_GeneralSeparation(csvInputDir)
%PROCESS_I_GENERALSEPARATION Splits the main CSV into specialized datasets.
%   Inputs:
%       csvInputDir - Directory containing 'General_Data.csv'.

inputFile = fullfile(csvInputDir, 'General_Data.csv');

% Read the data
data = readtable(inputFile);

%% === General_Frequency.csv ===
freqPatterns = {};
for g = 1:9, for p = 1:4, for c = [1, 5, 6], freqPatterns{end+1} = sprintf('G%d_P%d_case%d%d', g, p, g, c); end, end, end
for p = 1:4, freqPatterns{end+1} = sprintf('G0_P%d_case_perfect', p); end
freqMask = false(height(data), 1);
for i = 1:length(freqPatterns), freqMask = freqMask | contains(data.file, freqPatterns{i}); end
frequencyData = data(freqMask, :);
writetable(frequencyData, fullfile(csvInputDir, 'General_Frequency.csv'));

%% === General_Inclination.csv ===
inclPatterns = {};
for g = 1:9, for c = [2, 5], inclPatterns{end+1} = sprintf('G%d_P5_case%d%d', g, g, c); end, end
inclPatterns{end+1} = 'G0_P5_case_perfect';
inclMask = false(height(data), 1);
for i = 1:length(inclPatterns), inclMask = inclMask | contains(data.file, inclPatterns{i}); end
inclinationData = data(inclMask, :);
writetable(inclinationData, fullfile(csvInputDir, 'General_Inclination.csv'));

%% === General_Damper.csv ===
dampPatterns = {};
for g = 1:9, dampPatterns{end+1} = sprintf('G%d_P5_case%d3', g, g); end
for g = 1:9, dampPatterns{end+1} = sprintf('G%d_P5_case86', g); dampPatterns{end+1} = sprintf('G%d_P5_case96', g); end
dampPatterns{end+1} = 'G0_P5_case_perfect';
dampMask = false(height(data), 1);
for i = 1:length(dampPatterns), dampMask = dampMask | contains(data.file, dampPatterns{i}); end
damperData = data(dampMask, :);
writetable(damperData, fullfile(csvInputDir, 'General_Damper.csv'));

fprintf('Step I (General Separation) completed. Specialized CSVs created in: %s\n', csvInputDir);

end
