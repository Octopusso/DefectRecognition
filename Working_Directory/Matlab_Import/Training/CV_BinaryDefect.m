clc; close all;

% === Define features and defect tags ===
features = {'rms_acc', 'amplitude', 'dominant_freq', 'zcr', 'damping_ratio', 'skewness', 'kurtosis'};
defects = {'inc', 'damp', 'freq'};  % Corresponding to inc_deg, damp, freq

% === Load data and derive binary labels ===
data = readtable('General_Data.csv');
data.inc_exist  = data.inc_deg > 0;
data.damp_exist = data.damp    > 0;
data.freq_exist = data.freq    > 0;

for i = 1:numel(defects)
    tag = defects{i};
    labelName = [tag '_exist'];
    modelVar = 'model';  % Models are saved with variable name 'model'

    % === Normalize features using stored min/max ===
    load(sprintf('Scaler_%s.mat', upper(tag)), 'min_val', 'max_val');
    X = (data{:, features} - min_val) ./ (max_val - min_val);
    y = categorical(data.(labelName));

    % === Load trained model ===
    s = load(sprintf('Binary_%s_Exist_Model.mat', upper(tag)));
    model = s.(modelVar);

    % === Perform 10-fold CV ===
    cvmodel = crossval(model, 'KFold', 10);
    k = cvmodel.KFold;

    y_true = [];
    y_pred = [];
    accPerFold = zeros(k, 1);

    for fold = 1:k
        trained = cvmodel.Trained{fold};
        testIdx = cvmodel.Partition.test(fold);
        pred = predict(trained, X(testIdx, :));
        y_true = [y_true; y(testIdx)];
        y_pred = [y_pred; pred];
        accPerFold(fold) = mean(pred == y(testIdx));
    end

    % === Compute F1 and average accuracy ===
    f1 = computeF1Score(y_true, y_pred);
    avgAcc = mean(accPerFold);

    % === Plot confusion matrix ===
    figure;
    confusionchart(y_true, y_pred);
    title(sprintf('Confusion – %s Existence | Acc: %.2f%% | F1: %.2f', upper(tag), avgAcc * 100, f1));

    % === Plot per-fold accuracy ===
    figure;
    bar(accPerFold * 100);
    ylim([0 100]);
    ylabel('Accuracy (%)');
    xlabel('Fold Number');
    title(sprintf('%s – 10-Fold Accuracy per Fold', upper(tag)));
    grid on;
end

%% === Macro F1 Score Function ===
function f1 = computeF1Score(yTrue, yPred)
    classes = categories(yTrue);
    if numel(classes) ~= 2
        error('F1 only implemented for binary classification.');
    end
    posClass = classes{2};  % Assumes second class is the positive one
    tp = sum(yTrue == posClass & yPred == posClass);
    fp = sum(yTrue ~= posClass & yPred == posClass);
    fn = sum(yTrue == posClass & yPred ~= posClass);
    if tp + fp == 0 || tp + fn == 0
        f1 = 0;
    else
        prec = tp / (tp + fp);
        rec  = tp / (tp + fn);
        f1 = 2 * (prec * rec) / (prec + rec);
    end
end
