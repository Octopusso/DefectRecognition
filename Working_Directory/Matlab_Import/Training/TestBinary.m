%% === Binary Defect Existence Prediction Only ===

% Load binary models
load('Binary_Inc_Exist_Model.mat');
load('Binary_Damp_Exist_Model.mat');
load('Binary_Freq_Exist_Model.mat');

% Load general test data
data_test = readtable('General_Data.csv');

% Features used for all binary classifiers
features_inc  = {'segment','rms_acc','rms_vel','damping_ratio','amplitude','zcr','rms','dominant_freq','peak_vel', 'rms_pos'};
features_damp = features_inc;
features_freq = features_inc;

% Load scalers and normalize test data
load('Scaler_Inc.mat');
X_test_inc = (data_test{:, features_inc} - min_inc) ./ (max_inc - min_inc);

load('Scaler_Damp.mat');
X_test_damp = (data_test{:, features_damp} - min_damp) ./ (max_damp - min_damp);

load('Scaler_Freq.mat');
X_test_freq = (data_test{:, features_freq} - min_freq) ./ (max_freq - min_freq);

% Predict existence
pred_inc_exist  = predict(model_inc_exist, X_test_inc);
pred_damp_exist = predict(model_damp_exist, X_test_damp);
pred_freq_exist = predict(model_freq_exist, X_test_freq);

% Output results
output = table(data_test.file, pred_inc_exist, pred_damp_exist, pred_freq_exist, ...
    'VariableNames', {'file', 'inclination_exist', 'damper_exist', 'frequency_exist'});

% Display and save
disp(output(1:10, :)); % show first 10 rows
writetable(output, 'Binary_Existence_Predictions.csv');
