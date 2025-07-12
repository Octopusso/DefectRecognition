close all;
clc;

%% === Inclination Model ===
fprintf('\n=== Training Inclination Model ===\n');
data_inc = readtable('General_Inclination.csv');
data_inc = data_inc(data_inc.inc_deg > 0, :); % Filter defect-present cases only
features_inc = {'rms_acc', 'peak_vel', 'rms_pos', 'skewness'};
X_inc = normalize(data_inc{:, features_inc}, 'range');
label_inc = strcat(string(data_inc.inc_deg), '_', string(data_inc.inc_loc));
y_inc = categorical(label_inc);
model_inc = trainModel(X_inc, y_inc, features_inc, 'Inclination');
save('Combined_Inc_Model.mat', 'model_inc');

%% === Frequency Model ===
fprintf('\n=== Training Frequency Model ===\n');
data_freq = readtable('General_Frequency.csv');
data_freq = data_freq(data_freq.freq > 0, :); % Filter only active cases
features_freq = {'dominant_freq', 'amplitude', 'zcr', 'rms_acc'};
X_freq = normalize(data_freq{:, features_freq}, 'range');
label_freq = strcat(string(data_freq.freq), '_', string(data_freq.freq_loc));
y_freq = categorical(label_freq);
model_freq = trainModel(X_freq, y_freq, features_freq, 'Frequency');
save('Combined_Freq_Model.mat', 'model_freq');

%% === Damper Model ===
fprintf('\n=== Training Damper Model ===\n');
data_damp = readtable('General_Damper.csv');
data_damp = data_damp(data_damp.damp > 0, :); % Filter only active cases
features_damp = {'rms_vel', 'damping_ratio', 'peak_vel', 'kurtosis'};
X_damp = normalize(data_damp{:, features_damp}, 'range');
label_damp = strcat(string(data_damp.damp), '_', string(data_damp.damp_loc));
y_damp = categorical(label_damp);
model_damp = trainModel(X_damp, y_damp, features_damp, 'Damper');
save('Combined_Damp_Model.mat', 'model_damp');

%% === Training Function with Tuning, CV, F1 ===
function model = trainModel(X, y, featureNames, modelName)
    fprintf('%s - Starting hyperparameter tuning...\n', modelName);
    
    tbl = array2table(X, 'VariableNames', featureNames);
    tbl.Y = y;

    model = fitcensemble(tbl, 'Y', ...
        'Method', 'Bag', ...
        'Learners', 'Tree', ...
        'OptimizeHyperparameters', {'NumLearningCycles','MinLeafSize','MaxNumSplits'}, ...
        'HyperparameterOptimizationOptions', struct( ...
            'AcquisitionFunctionName', 'expected-improvement-plus', ...
            'MaxObjectiveEvaluations', 30, ...
            'Verbose', 1, ...
            'ShowPlots', false ...
        ));

    % Cross-validation
    cvmodel = crossval(model, 'KFold', 10);
    acc = 1 - kfoldLoss(cvmodel, 'LossFun', 'ClassifError');
    fprintf('%s - 10-Fold Accuracy: %.2f%%\n', modelName, acc * 100);

    % Collect predictions
    y_all_true = [];
    y_all_pred = [];
    for i = 1:cvmodel.KFold
        trained = cvmodel.Trained{i};
        testIdx = cvmodel.Partition.test(i);
        y_val = y(testIdx);
        y_pred = predict(trained, X(testIdx,:));
        y_all_true = [y_all_true; y_val];
        y_all_pred = [y_all_pred; y_pred];
    end

    % F1-score
    f1 = macroF1(y_all_true, y_all_pred);
    fprintf('%s - Macro F1 Score: %.2f\n', modelName, f1);

    % Confusion matrix
    figure;
    confusionchart(y_all_true, y_all_pred);
    title(['Confusion Matrix - ' modelName]);
end

%% === Macro F1 Score Function ===
function f1 = macroF1(yTrue, yPred)
    classes = categories(yTrue);
    f1_sum = 0;
    for i = 1:numel(classes)
        c = classes{i};
        tp = sum(yTrue == c & yPred == c);
        fp = sum(yTrue ~= c & yPred == c);
        fn = sum(yTrue == c & yPred ~= c);
        if tp + fp == 0 || tp + fn == 0
            f1_c = 0;
        else
            prec = tp / (tp + fp);
            rec  = tp / (tp + fn);
            f1_c = 2 * (prec * rec) / (prec + rec);
        end
        f1_sum = f1_sum + f1_c;
    end
    f1 = f1_sum / numel(classes);
end
