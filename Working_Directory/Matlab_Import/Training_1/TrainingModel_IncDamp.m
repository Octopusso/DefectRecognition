% Load and preprocess data
data = readtable('training_features.csv');
features = data{:, {'peak_acc','segment','peak_vel',}};

features = normalize(features, 'range');
inc_deg = categorical(data.inc_deg);
damp = categorical(data.damp);
inc_loc = categorical(data.inc_loc);
damp_loc = categorical(data.damp_loc);

% Split data
rng(42);
cv = cvpartition(height(data), 'HoldOut', 0.2);
idx_train = cv.training;
idx_test = cv.test;
X_train = features(idx_train, :);
X_test = features(idx_test, :);
y_inc_deg_train = inc_deg(idx_train);
y_inc_deg_test = inc_deg(idx_test);
y_damp_train = damp(idx_train);
y_damp_test = damp(idx_test);
y_inc_loc_train = inc_loc(idx_train);
y_inc_loc_test = inc_loc(idx_test);
y_damp_loc_train = damp_loc(idx_train);
y_damp_loc_test = damp_loc(idx_test);

% Train models
model_inc_deg = fitcensemble(X_train, y_inc_deg_train, 'Method', 'Bag', 'NumLearningCycles', 100);
model_damp = fitcensemble(X_train, y_damp_train, 'Method', 'Bag', 'NumLearningCycles', 100);
model_inc_loc = fitcensemble(X_train, y_inc_loc_train, 'Method', 'Bag', 'NumLearningCycles', 100);
model_damp_loc = fitcensemble(X_train, y_damp_loc_train, 'Method', 'Bag', 'NumLearningCycles', 100);

% Evaluate models
y_inc_deg_pred = predict(model_inc_deg, X_test);
y_damp_pred = predict(model_damp, X_test);
y_inc_loc_pred = predict(model_inc_loc, X_test);
y_damp_loc_pred = predict(model_damp_loc, X_test);

acc_inc_deg = mean(y_inc_deg_pred == y_inc_deg_test);
acc_damp = mean(y_damp_pred == y_damp_test);
acc_inc_loc = mean(y_inc_loc_pred == y_inc_loc_test);
acc_damp_loc = mean(y_damp_loc_pred == y_damp_loc_test);

fprintf('Accuracy for inc_deg: %.2f%%\n', acc_inc_deg * 100);
fprintf('Accuracy for damp: %.2f%%\n', acc_damp * 100);
fprintf('Accuracy for inc_loc: %.2f%%\n', acc_inc_loc * 100);
fprintf('Accuracy for damp_loc: %.2f%%\n', acc_damp_loc * 100);

% Visualize confusion matrices
figure;
subplot(2, 2, 1); confusionchart(y_inc_deg_test, y_inc_deg_pred); title('inc_deg');
subplot(2, 2, 2); confusionchart(y_damp_test, y_damp_pred); title('damp');
subplot(2, 2, 3); confusionchart(y_inc_loc_test, y_inc_loc_pred); title('inc_loc');
subplot(2, 2, 4); confusionchart(y_damp_loc_test, y_damp_loc_pred); title('damp_loc');

% Save models
save('model_inc_deg.mat', 'model_inc_deg');
save('model_damp.mat', 'model_damp');
save('model_inc_loc.mat', 'model_inc_loc');
save('model_damp_loc.mat', 'model_damp_loc');