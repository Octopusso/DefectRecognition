close all;
clc;

%% Load and preprocess data
data = readtable('IncData.csv');

% Combine inc_deg and inc_loc into a single joint target label
combined_label = strcat(string(data.inc_deg), '_', string(data.inc_loc));
y_combined = categorical(combined_label);

% Use best selected features
features_selected = {'peak_vel', 'rms_pos'};
X = normalize(data{:, features_selected}, 'range');

% Convert to table for model training
tbl = array2table(X, 'VariableNames', features_selected);
tbl.Y = y_combined;

%% Train 10-fold cross-validated ensemble model
model = fitcensemble(tbl, 'Y', ...
    'Method', 'Bag', ...
    'NumLearningCycles', 100, ...
    'KFold', 10);

% Compute cross-validated accuracy
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

%% Confusion Matrix Plot
figure;
confChart = confusionchart(y_true_all, y_pred_all);
confChart.Title = 'Confusion Matrix – Combined inc\_deg + inc\_loc';
confChart.FontName = 'Calibri';
confChart.FontSize = 14;

%% Save the full cross-validated model
save('Combined_Inc_Model.mat', 'model');

%% Function to calculate Macro F1-score
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

    f1 = f1_total / numel(classes);
end
