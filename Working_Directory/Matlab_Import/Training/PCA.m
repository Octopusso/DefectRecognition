clc; clear;

% === Step 1: Load Data ===
filename = 'General_Data.csv';
data = readtable(filename);

% === Step 2: Select Features ===
% You can adjust this list based on your dataset
features = {'segment','rms_acc','rms_vel','damping_ratio','amplitude', ...
            'zcr','rms','dominant_freq','peak_vel','rms_pos', ...
            'skewness','kurtosis'};

T = readtable('General_Data.csv');  % Or your consolidated dataset
X = T{:, features};                 % Feature matrix
X = normalize(X);                   % Optional: normalize before PCA

[coeff, score, latent, ~, explained] = pca(X);

% Scree plot
figure;
bar(explained);
xlabel('Principal Component');
ylabel('Explained Variance (%)');
title('PCA - Explained Variance');

% Cumulative variance
figure;
plot(cumsum(explained), 'o-');
xlabel('Number of Principal Components');
ylabel('Cumulative Explained Variance (%)');
grid on;
title('Cumulative Variance Explained by PCA');

% Biplot
figure;
biplot(coeff(:,1:2), 'Scores', score(:,1:2), 'VarLabels', features);
title('PCA Biplot (PC1 vs PC2)');

R = corr(X, 'Rows', 'complete');  % Use 'complete' in case of NaNs

figure;
heatmap(features, features, R, ...
    'Colormap', parula, ...
    'ColorbarVisible', 'on', ...
    'Title', 'Feature Correlation Heatmap');
caxis([-1, 1]);

