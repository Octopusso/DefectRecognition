clc; clear;

% Define the path
baseFolder = fullfile(pwd, 'Matlab_Import', 'Training');
inputFile = fullfile(baseFolder, 'General_Data.csv');

% Read the data
data = readtable(inputFile);

%% === General_Frequency.csv ===
freqPatterns = {};

% G1 to G9, P1 to P4, caseX1, X5, X6
for g = 1:9
    for p = 1:4
        for c = [1, 5, 6]
            freqPatterns{end+1} = sprintf('G%d_P%d_case%d%d', g, p, g, c);
        end
    end
end

% G0_P1 to P4, case_perfect
for p = 1:4
    freqPatterns{end+1} = sprintf('G0_P%d_case_perfect', p);
end

% Filter frequency
freqMask = false(height(data), 1);
for i = 1:length(freqPatterns)
    freqMask = freqMask | contains(data.file, freqPatterns{i});
end
frequencyData = data(freqMask, :);
writetable(frequencyData, fullfile(baseFolder, 'General_Frequency.csv'));

%% === General_Inclination.csv ===
inclPatterns = {};

% G1 to G9, P5 only, caseX2, X5
for g = 1:9
    for c = [2, 5]
        inclPatterns{end+1} = sprintf('G%d_P5_case%d%d', g, g, c);
    end
end

% G0_P5, case_perfect
inclPatterns{end+1} = 'G0_P5_case_perfect';

% Filter inclination
inclMask = false(height(data), 1);
for i = 1:length(inclPatterns)
    inclMask = inclMask | contains(data.file, inclPatterns{i});
end
inclinationData = data(inclMask, :);
writetable(inclinationData, fullfile(baseFolder, 'General_Inclination.csv'));

%% === General_Damper.csv ===
dampPatterns = {};

% G1 to G9, P5 only, caseX3
for g = 1:9
    dampPatterns{end+1} = sprintf('G%d_P5_case%d3', g, g);
end

% G1 to G9, P5 only, case86 and case96
for g = 1:9
    dampPatterns{end+1} = sprintf('G%d_P5_case86', g);
    dampPatterns{end+1} = sprintf('G%d_P5_case96', g);
end

% G0_P5, case_perfect
dampPatterns{end+1} = 'G0_P5_case_perfect';

% Filter damper
dampMask = false(height(data), 1);
for i = 1:length(dampPatterns)
    dampMask = dampMask | contains(data.file, dampPatterns{i});
end
damperData = data(dampMask, :);
writetable(damperData, fullfile(baseFolder, 'General_Damper.csv'));

fprintf('Exported:\n- General_Frequency.csv\n- General_Inclination.csv\n- General_Damper.csv\n');
