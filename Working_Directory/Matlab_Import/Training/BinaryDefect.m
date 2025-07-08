close all;
clc;

%% === Binary Existence Models with 80/20 Split Evaluation and Scaler Saving ===
data = readtable('General_Data.csv');

% Labels
data.inc_exist  = data.inc_deg  > 0;
data.damp_exist = data.damp     > 0;
data.freq_exist = data.freq     > 0;

% Features
features_inc  = {'segment','rms_acc','rms_vel','damping_ratio','amplitude','zcr','rms','dominant_freq','peak_vel', 'rms_pos'};
features_damp = features_inc;
features_freq = features_inc;

% Store scalers
X_raw_inc = data{:, features_inc};
min_inc = min(X_raw_inc);
max_inc = max(X_raw_inc);
X_inc = (X_raw_inc - min_inc) ./ (max_inc - min_inc);
save('Scaler_Inc.mat', 'min_inc', 'max_inc');

X_raw_damp = data{:, features_damp};
min_damp = min(X_raw_damp);
max_damp = max(X_raw_damp);
X_damp = (X_raw_damp - min_damp) ./ (max_damp - min_damp);
save('Scaler_Damp.mat', 'min_damp', 'max_damp');

X_raw_freq = data{:, features_freq};
min_freq = min(X_raw_freq);
max_freq = max(X_raw_freq);
X_freq = (X_raw_freq - min_freq) ./ (max_freq - min_freq);
save('Scaler_Freq.mat', 'min_freq', 'max_freq');

rng(1); % For reproducibility
train_ratio = 0.8;

%% Inclination model
Y_inc_bin = categorical(data.inc_exist);
cv_inc = cvpartition(Y_inc_bin, 'HoldOut', 1 - train_ratio);
Xtrain = X_inc(training(cv_inc), :);
Xtest = X_inc(test(cv_inc), :);
Ytrain = Y_inc_bin(training(cv_inc));
Ytest = Y_inc_bin(test(cv_inc));
model_inc_exist = fitcensemble(Xtrain, Ytrain, 'Method', 'Bag');
pred_test = predict(model_inc_exist, Xtest);
acc_test = mean(pred_test == Ytest);
fprintf('Inclination Existence Hold-Out Accuracy: %.2f%%\n', acc_test * 100);
save('Binary_Inc_Exist_Model.mat', 'model_inc_exist');
figure;
confusionchart(Ytest, pred_test);
title(sprintf('Confusion Matrix – Inclination Existence (Test Set)\nAccuracy: %.2f%%', acc_test * 100));

%% Damper model
Y_damp_bin = categorical(data.damp_exist);
cv_damp = cvpartition(Y_damp_bin, 'HoldOut', 1 - train_ratio);
Xtrain = X_damp(training(cv_damp), :);
Xtest = X_damp(test(cv_damp), :);
Ytrain = Y_damp_bin(training(cv_damp));
Ytest = Y_damp_bin(test(cv_damp));
model_damp_exist = fitcensemble(Xtrain, Ytrain, 'Method', 'Bag');
pred_test = predict(model_damp_exist, Xtest);
acc_test = mean(pred_test == Ytest);
fprintf('Damper Existence Hold-Out Accuracy: %.2f%%\n', acc_test * 100);
save('Binary_Damp_Exist_Model.mat', 'model_damp_exist');
figure;
confusionchart(Ytest, pred_test);
title(sprintf('Confusion Matrix – Damper Existence (Test Set)\nAccuracy: %.2f%%', acc_test * 100));

%% Frequency model
Y_freq_bin = categorical(data.freq_exist);
cv_freq = cvpartition(Y_freq_bin, 'HoldOut', 1 - train_ratio);
Xtrain = X_freq(training(cv_freq), :);
Xtest = X_freq(test(cv_freq), :);
Ytrain = Y_freq_bin(training(cv_freq));
Ytest = Y_freq_bin(test(cv_freq));
model_freq_exist = fitcensemble(Xtrain, Ytrain, 'Method', 'Bag');
pred_test = predict(model_freq_exist, Xtest);
acc_test = mean(pred_test == Ytest);
fprintf('Frequency Existence Hold-Out Accuracy: %.2f%%\n', acc_test * 100);
save('Binary_Freq_Exist_Model.mat', 'model_freq_exist');
figure;
confusionchart(Ytest, pred_test);
title(sprintf('Confusion Matrix – Frequency Existence (Test Set)\nAccuracy: %.2f%%', acc_test * 100));
