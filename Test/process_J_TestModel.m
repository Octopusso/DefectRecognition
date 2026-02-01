function process_J_TestModel(modelsPath, dataForPredictionPath, finalOutputPath)
%PROCESS_J_TESTMODEL Loads trained models and predicts on new data.
%   Inputs:
%       modelsPath            - Path to the directory containing the trained .mat models.
%       dataForPredictionPath - Path to the directory containing the feature CSVs.
%       finalOutputPath       - Path to save the final 'Final_Predictions.xlsx'.

outputFile  = fullfile(finalOutputPath, 'Final_Predictions.xlsx');

features_inc = {'rms_acc', 'peak_vel', 'rms_pos'}; 
features_freq = {'dominant_freq', 'amplitude', 'zcr', 'rms_acc'};
features_damp = {'rms_vel', 'damping_ratio', 'peak_vel'};

filePairs = {
    fullfile(modelsPath, 'Combined_Damp_Model.mat'),      fullfile(dataForPredictionPath, 'General_Damper.csv'),       'damp', 'model_damp', features_damp;
    fullfile(modelsPath, 'Combined_Freq_Model.mat'),      fullfile(dataForPredictionPath, 'General_Frequency.csv'),    'freq', 'model_freq', features_freq;
    fullfile(modelsPath, 'Combined_Inc_Model.mat'),       fullfile(dataForPredictionPath, 'General_Inclination.csv'),  'inc',  'model_inc', features_inc;
};

allResults = table;

%% === Loop Through Each Pair ===
for i = 1:size(filePairs, 1)
    modelFile = filePairs{i,1};
    dataFile  = filePairs{i,2};
    labelKey  = filePairs{i,3};
    modelVarName = filePairs{i,4};
    currentFeatures = filePairs{i,5};
    
    if ~exist(modelFile, 'file')
        warning('Model file not found, skipping: %s', modelFile);
        continue;
    end
    if ~exist(dataFile, 'file')
        warning('Data file not found, skipping: %s', dataFile);
        continue;
    end

    %% Load the model dynamically
    modelStruct = load(modelFile);
    if ~isfield(modelStruct, modelVarName)
        error('Variable "%s" not found in %s.', modelVarName, modelFile);
    end
    model = modelStruct.(modelVarName);

    %% Load test data
    testData = readtable(dataFile);
    
    if isempty(testData)
        warning('Data file is empty, skipping: %s', dataFile);
        continue;
    end

    colIdx = find(strcmpi('file', testData.Properties.VariableNames), 1);
    if ~isempty(colIdx)
        file_col = testData{:, colIdx};
    else
        file_col = strcat("sample_", string((1:height(testData))'));
    end

    %% Preprocess features
    usable_features = currentFeatures(ismember(currentFeatures, testData.Properties.VariableNames));
    if isempty(usable_features)
        warning('No usable features found in %s, skipping.', dataFile);
        continue;
    end
    X_test = normalize(testData{:, usable_features}, 'range');

    %% Predict
    y_pred = predict(model, X_test);

    %% Merge results
    partialResult = table(file_col, y_pred, 'VariableNames', {'File', [labelKey '_pred']});

            % Consolidate predictions by taking the mode for each file
            predColName = [labelKey '_pred'];
            uniqueFiles = unique(partialResult.File);
            consolidatedTable = table();
            for f = 1:length(uniqueFiles)
                currentFile = uniqueFiles(f);
                % Correctly access the column using its dynamic name
                predsForFile = partialResult.(predColName)(strcmp(partialResult.File, currentFile));
                finalPred = mode(predsForFile);
                
                newRow = table(currentFile, finalPred, 'VariableNames', {'File', predColName});
                consolidatedTable = [consolidatedTable; newRow];
            end
    
                if isempty(allResults)
    
                    allResults = consolidatedTable;
    
                else
    
                    allResults = outerjoin(allResults, consolidatedTable, 'Keys', 'File', 'MergeKeys', true);
    
                end
    
end

%% === Export Predictions ===
if ~isempty(allResults)
    writetable(allResults, outputFile);
    fprintf('Step J (Test Model) completed. All predictions written to "%s\n', outputFile);
else
    warning('No predictions were made. Final output file was not created.');
end

end