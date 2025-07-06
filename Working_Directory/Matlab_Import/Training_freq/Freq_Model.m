close all;
clc;

%% Load and preprocess data
data = readtable('feature_freq.csv');

% Combine freq and freq_loc into one joint categorical label
combined_label = strcat(string(data.freq), '_', string(data.freq_loc));
y_combined = categorical(combined_label);

% Feature selection
features_selected = {'segment', 'amplitude', 'max_freq', 'zcr', 'rms'};
X = normalize(data{:, features_selected}, 'range');

% Convert to table for training
tbl = array2table(X, 'VariableNames', features_selected);
tbl.Y = y_combined;

%% Train ensemble model with 10-fold cross-validation
model = fitcensemble(tbl, 'Y', ...
    'Method', 'Bag', ...
    'NumLearningCycles', 100, ...
    'KFold', 10);

% Compute 10-fold cross-validated accuracy
cvAcc = 1 - kfoldLoss(model, 'LossFun', 'ClassifError');
fprintf('10-Fold Cross-Validated Accuracy: %.2f%%\n', cvAcc * 100);

%% Predict across all folds and compute macro F1-score
y_true_all = [];
y_pred_all = [];

for i = 1:model.KFold
    trainedModel = model.Trained{i};
    testIdx = model.Partition.test(i);
    X_test = X(testIdx, :);
    y_test = y_combined(testIdx);
    y_pred = predict(trainedModel, X_test);

    y_true_all = [y_true_all; y_test];
    y_pred_all = [y_pred_all; y_pred];
end

f1_macro = f1score(y_true_all, y_pred_all);
fprintf('10-Fold Macro F1-Score: %.2f\n', f1_macro);

%% Plot confusion matrix
figure;
confChart = confusionchart(y_true_all, y_pred_all);
confChart.Title = 'Confusion Matrix – Combined freq + freq\_loc';
confChart.FontName = 'Calibri';
confChart.FontSize = 14;

%% Save the cross-validated model
save('Combined_Freq_Model.mat', 'model');

%% Macro F1-score Function
function f1 = f1score(yTrue, yPred)
    classes = categories(yTrue);
    f1_total = 0;

    for i = 1:numel(classes)
        class = classes{i};
        tp = sum(yPred == class & yTrue == class);
        fp = sum(yPred == class & yTrue ~= class);
        fn = sum(yPred ~= class & yTrue == class);

        if tp + fp == 0 || tp + fn == 0
            f1_class = 0;
        else
            precision = tp / (tp + fp);
            recall = tp / (tp + fn);
            f1_class = 2 * (precision * recall) / (precision + recall);
        end

        f1_total = f1_total + f1_class;
    end

    f1 = f1_total / numel(classes);  % macro average
end
