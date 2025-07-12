clc; close all;

% === Load data and define label logic ===
data = readtable('General_Data.csv');
data.inc_exist  = data.inc_deg > 0;
data.damp_exist = data.damp    > 0;
data.freq_exist = data.freq    > 0;

% === Model configurations ===
configs = {
    'Inclination', 'Combined_Inc_Model.mat',  'inc_exist',  {'rms_acc', 'peak_vel', 'rms_pos', 'skewness'},   {'inc_deg', 'inc_loc'},  'model_inc';
    'Frequency',   'Combined_Freq_Model.mat', 'freq_exist', {'dominant_freq', 'amplitude', 'zcr', 'rms_acc'}, {'freq', 'freq_loc'},    'model_freq';
    'Damping',     'Combined_Damp_Model.mat', 'damp_exist', {'rms_vel', 'damping_ratio', 'peak_vel', 'kurtosis'}, {'damp', 'damp_loc'}, 'model_damp';
};

% === Evaluate each model ===
for i = 1:size(configs,1)
    name         = configs{i,1};
    model_file   = configs{i,2};
    exist_col    = configs{i,3};
    feature_cols = configs{i,4};
    label_cols   = configs{i,5};
    model_var    = configs{i,6};

    fprintf('\n=== CV Evaluation for %s Model ===\n', name);

    % === Filter relevant data ===
    data_filtered = data(data.(exist_col), :);
    X = normalize(data_filtered{:, feature_cols}, 'range');
    label_str = strcat(string(data_filtered{:, label_cols{1}}), '_', string(data_filtered{:, label_cols{2}}));
    y = categorical(label_str);

    % === Load trained model ===
    s = load(model_file);
    model = s.(model_var);

    % === Cross-validation ===
    cvmodel = crossval(model, 'KFold', 10);
    y_true = [];
    y_pred = [];
    accPerFold = zeros(cvmodel.KFold, 1);

    for k = 1:cvmodel.KFold
        trained = cvmodel.Trained{k};
        testIdx = cvmodel.Partition.test(k);
        pred = predict(trained, X(testIdx, :));
        y_true = [y_true; y(testIdx)];
        y_pred = [y_pred; pred];
        accPerFold(k) = mean(pred == y(testIdx));
    end

    % === Macro F1 ===
    f1 = macroF1(y_true, y_pred);
    avgAcc = mean(accPerFold);
    fprintf('%s - Avg Accuracy: %.2f%% | Macro F1: %.2f\n', name, avgAcc*100, f1);

    % === Confusion chart ===
    figure;
    confusionchart(y_true, y_pred);
    title(sprintf('Confusion Matrix – %s', name));

    % === Per-fold accuracy ===
    figure;
    bar(accPerFold * 100);
    ylim([0 100]);
    ylabel('Accuracy (%)');
    xlabel('Fold');
    title(sprintf('%s – Accuracy per Fold', name));
    grid on;
end

%% === Macro F1 Function ===
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
