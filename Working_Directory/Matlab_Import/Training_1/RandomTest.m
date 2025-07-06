close all;
clc;

%% Load and preprocess data
data = readtable('training_features.csv');
features = data{:, {'peak_acc','segment','rms_vel','rms_acc','damping_ratio','dominant_freq','rms_pos','zcr'}};
features = normalize(features, 'range');

damp = categorical(data.damp);
damp_loc = categorical(data.damp_loc);

%% Use seed 42
seed = 42;
rng(seed);

% Split data
cv = cvpartition(height(data), 'HoldOut', 0.2);
idx_train = cv.training;
idx_test = cv.test;

X_train = features(idx_train, :);
X_test = features(idx_test, :);
y_damp_train = damp(idx_train);
y_damp_test = damp(idx_test);
y_damp_loc_train = damp_loc(idx_train);
y_damp_loc_test = damp_loc(idx_test);

%% Train models
model_damp = fitcensemble(X_train, y_damp_train, 'Method', 'Bag', 'NumLearningCycles', 100);
model_damp_loc = fitcensemble(X_train, y_damp_loc_train, 'Method', 'Bag', 'NumLearningCycles', 100);

%% Evaluate models
y_damp_pred = predict(model_damp, X_test);
y_damp_loc_pred = predict(model_damp_loc, X_test);

acc_damp = mean(y_damp_pred == y_damp_test) * 100;
acc_damp_loc = mean(y_damp_loc_pred == y_damp_loc_test) * 100;

fprintf('Seed %d → Accuracy (damp): %.2f%% | Accuracy (damp_loc): %.2f%%\n', ...
        seed, acc_damp, acc_damp_loc);

%% Compute feature importance
importance_damp = predictorImportance(model_damp);
importance_damp_loc = predictorImportance(model_damp_loc);

% Feature names (match order)
featureNames = {'peak\_acc','segment','rms\_vel','rms\_acc','damping\_ratio','dominant\_freq','rms\_pos','zcr'};

% Plot for damp
figure;
bar(importance_damp);
title('Predictor Importance for damp (Seed 42)');
xticklabels(featureNames);
xtickangle(45);
ylabel('Importance');

% Plot for damp_loc
figure;
bar(importance_damp_loc);
title('Predictor Importance for damp\_loc (Seed 42)');
xticklabels(featureNames);
xtickangle(45);
ylabel('Importance');
