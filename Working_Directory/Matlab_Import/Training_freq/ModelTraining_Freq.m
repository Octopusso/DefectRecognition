% Load and preprocess data
data = readtable('feature_freq.csv');
features = data{:, {'segment','amplitude','max_freq','zcr','rms'}};

features = normalize(features, 'range');
freq_loc = categorical(data.freq_loc);

% Split data
rng(42);
cv = cvpartition(height(data), 'HoldOut', 0.2);
idx_train = cv.training;
idx_test = cv.test;
X_train = features(idx_train, :);
X_test = features(idx_test, :);
y_freq_loc_train = freq_loc(idx_train);
y_freq_loc_test = freq_loc(idx_test);


% Train models
model_freq_loc = fitcensemble(X_train, y_freq_loc_train, 'Method', 'Bag', 'NumLearningCycles', 100);

% Evaluate models
y_freq_loc_pred = predict(model_freq_loc, X_test);

acc_freq_loc = mean(y_freq_loc_pred == y_freq_loc_test);

fprintf('Accuracy for freq_loc: %.2f%%\n', acc_freq_loc * 100);

% Visualize confusion matrices
figure;
subplot(2, 2, 1); confusionchart(y_freq_loc_test, y_freq_loc_pred); title('freq_loc');
%subplot(2, 2, 2); confusionchart(y_damp_test, y_damp_pred); title('damp');
%subplot(2, 2, 3); confusionchart(y_inc_loc_test, y_inc_loc_pred); title('inc_loc');
%subplot(2, 2, 4); confusionchart(y_damp_loc_test, y_damp_loc_pred); title('damp_loc');

% Save models
save('model_freq_loc.mat', 'model_freq_loc');