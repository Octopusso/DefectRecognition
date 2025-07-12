clc; clear;

%% === Paths and Configuration ===
dataFolder  = fullfile(pwd, 'Matlab_Import', 'Training');
outputFile  = 'Final_Predictions.xlsx';

features_selected = {'rms_acc', 'rms_vel', 'damping_ratio', ...
                     'peak_vel', 'rms_pos', 'amplitude', 'zcr', 'rms'};

% Model file | Test file | Output label key | Actual variable name inside .mat
filePairs = {
    'Combined_Damp_Model.mat',      'General_Damper.csv',       'damp', 'myDampModel';
    'Combined_Freq_Model.mat',      'General_Frequency.csv',    'freq', 'myFreqModel';
    'Combined_Inc_Model.mat',       'General_Inclination.csv',  'inc',  'myIncModel';
};

allResults = table;

%% === Loop Through Each Pair ===
for i = 1:size(filePairs, 1)
    modelFile = filePairs{i,1};
    dataFile  = filePairs{i,2};
    labelKey  = filePairs{i,3};
    modelVarName = filePairs{i,4};

    %% Load the model dynamically
    modelStruct = load(modelFile);
    if ~isfield(modelStruct, modelVarName)
        error('Variable "%s" not found in %s.', modelVarName, modelFile);
    end
    model = modelStruct.(modelVarName);

    %% Load test data
    testData = readtable(fullfile(dataFolder, dataFile));

    % Get file identifier or fallback
    colIdx = find(strcmpi('file', testData.Properties.VariableNames), 1);
    if ~isempty(colIdx)
        file_col = testData{:, colIdx};
    else
        file_col = strcat("sample_", string((1:height(testData))'));
    end

    %% Preprocess features
    usable_features = features_selected(ismember(features_selected, testData.Properties.VariableNames));
    if isempty(usable_features)
        error('No usable features found in %s', dataFile);
    end
    X_test = normalize(testData{:, usable_features}, 'range');

    %% Predict
    y_pred = predict(model, X_test);

    %% Merge results
    partialResult = table(file_col, y_pred, ...
        'VariableNames', {'File', [labelKey '_pred']});

    if isempty(allResults)
        allResults = partialResult;
    else
        allResults = outerjoin(allResults, partialResult, ...
            'Keys', 'File', 'MergeKeys', true);
    end
end

%% === Export Predictions ===
writetable(allResults, outputFile);
fprintf('\n✅ All predictions written to "%s"\n', outputFile);
