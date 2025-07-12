clc; close all;

% === Load Data ===
data = readtable('General_Data.csv');

% === Labels ===
data.inc_exist  = data.inc_deg  > 0;
data.damp_exist = data.damp     > 0;
data.freq_exist = data.freq     > 0;

% === Features ===
features = {'rms_acc', 'amplitude', 'dominant_freq', 'zcr', 'damping_ratio', 'skewness', 'kurtosis'};

% === Normalize and save scalers ===
defects = {'inc', 'damp', 'freq'};
for i = 1:numel(defects)
    tag = defects{i};
    X_raw = data{:, features};
    min_val = min(X_raw);
    max_val = max(X_raw);
    X_norm = (X_raw - min_val) ./ (max_val - min_val);
    y = categorical(data.([tag '_exist']));

    % Store scalers
    save(sprintf('Scaler_%s.mat', upper(tag)), 'min_val', 'max_val');

    % Create table
    tbl = array2table(X_norm, 'VariableNames', features);
    tbl.Y = y;

    % === Hyperparameter Tuning ===
    fprintf('--- Tuning %s model ---\n', tag);
    rng(1);  % Reproducibility
    model = fitcensemble(tbl, 'Y', ...
        'Method', 'Bag', ...
        'OptimizeHyperparameters', {'NumLearningCycles', 'MinLeafSize', 'MaxNumSplits'}, ...
        'HyperparameterOptimizationOptions', struct( ...
            'MaxObjectiveEvaluations', 30, ...
            'Verbose', 1 ...
        ));

    save(sprintf('Binary_%s_Exist_Model.mat', upper(tag)), 'model');
end
