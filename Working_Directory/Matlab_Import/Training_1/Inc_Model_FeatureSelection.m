close all;
clc;

%% Load and preprocess data
data = readtable('IncData.csv');
featureNames = {'peak_acc','segment','peak_vel','rms_vel','peak_pos','rms_pos'};
n = numel(featureNames);

% Combine inc_deg and inc_loc into one joint target label
combined_label = strcat(string(data.inc_deg), '_', string(data.inc_loc));
y_combined = categorical(combined_label);

bestF1 = 0;
bestAcc = 0;
bestFeatures = {};
bestTrue = [];
bestPred = [];

fprintf('\n--- 10-Fold Feature Selection for Combined inc_deg + inc_loc ---\n');

%% Loop through all feature combinations (from 2 to n features)
for k = 2:n
    combs = combnk(1:n, k);  % combinations of k features
    for i = 1:size(combs, 1)
        selectedIdx = combs(i,:);
        selectedNames = featureNames(selectedIdx);

        % Extract and normalize selected features
        X = normalize(data{:, selectedNames}, 'range');

        % Create table
        tbl = array2table(X, 'VariableNames', selectedNames);
        tbl.Y = y_combined;

        % Train model with 10-fold CV
        model = fitcensemble(tbl, 'Y', ...
            'Method', 'Bag', ...
            'NumLearningCycles', 100, ...
            'KFold', 10);

        % Compute accuracy
        acc = 1 - kfoldLoss(model, 'LossFun', 'ClassifError');

        % Predict all folds
        y_true_all = [];
        y_pred_all = [];
        for fold = 1:model.KFold
            trainedModel = model.Trained{fold};
            testIdx = model.Partition.test(fold);
            X_test = X(testIdx, :);
            y_test = y_combined(testIdx);
            y_pred = predict(trainedModel, X_test);

            y_true_all = [y_true_all; y_test];
            y_pred_all = [y_pred_all; y_pred];
        end

        % Compute macro F1-score
        f1 = f1score(y_true_all, y_pred_all);

        % Update best
        if f1 > bestF1 || (f1 == bestF1 && acc > bestAcc)
            bestF1 = f1;
            bestAcc = acc;
            bestFeatures = selectedNames;
            bestTrue = y_true_all;
            bestPred = y_pred_all;
        end
    end
end

%% Report best result
fprintf('Best 10-Fold F1-score: %.2f\n', bestF1);
fprintf('Corresponding 10-Fold Accuracy: %.2f%%\n', bestAcc * 100);
fprintf('Best feature combination:\n');
disp(bestFeatures);

%% Confusion Matrix
figure;
confChart = confusionchart(bestTrue, bestPred);
confChart.Title = 'Confusion Matrix – Combined inc\_deg + inc\_loc';
confChart.FontName = 'Calibri';
confChart.FontSize = 14;

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
