%% === Prediction with Binary + Detail Classifiers ===

% Load binary models
load('Binary_Inc_Exist_Model.mat');
load('Binary_Damp_Exist_Model.mat');
load('Binary_Freq_Exist_Model.mat');

% Load detailed models
load('Combined_Inc_Model.mat');   % features: 'peak_vel', 'rms_pos'
load('Combined_Damp_Model.mat');  % features: 'rms_vel', 'rms_acc', 'damping_ratio'
load('Combined_Freq_Model.mat');  % features: 'segment', 'amplitude', 'zcr', 'rms', 'dominant_freq'

% Load test data
data_test = readtable('General_Data.csv');

% Define feature sets
features_binary     = {'segment','rms_acc','rms_vel','damping_ratio','amplitude','zcr','rms','dominant_freq','peak_vel','rms_pos'};
features_inc_detail = {'peak_vel', 'rms_pos'};
features_damp_detail= {'rms_vel', 'rms_acc', 'damping_ratio'};
features_freq_detail= {'segment', 'amplitude', 'zcr', 'rms', 'dominant_freq'};

% Normalize for each model
X_binary     = normalize(data_test{:, features_binary}, 'range');
X_inc_detail = normalize(data_test{:, features_inc_detail}, 'range');
X_damp_detail= normalize(data_test{:, features_damp_detail}, 'range');
X_freq_detail= normalize(data_test{:, features_freq_detail}, 'range');

% Step 1: Binary predictions
pred_inc_exist  = predict(model_inc_exist, X_binary);
pred_damp_exist = predict(model_damp_exist, X_binary);
pred_freq_exist = predict(model_freq_exist, X_binary);

% Step 2: Detailed predictions
n = height(data_test);
detailed_inc  = repmat("None", n, 1);
detailed_damp = repmat("None", n, 1);
detailed_freq = repmat("None", n, 1);

for i = 1:n
    if pred_inc_exist(i) == "true"
        detailed_inc(i) = predict(model_inc, X_inc_detail(i,:));
    end
    if pred_damp_exist(i) == "true"
        detailed_damp(i) = predict(model_damp, X_damp_detail(i,:));
    end
    if pred_freq_exist(i) == "true"
        detailed_freq(i) = predict(model_freq, X_freq_detail(i,:));
    end
end

% Step 3: Combine predictions
output = table(data_test.file, detailed_inc, detailed_damp, detailed_freq, ...
    'VariableNames', {'file', 'inclination', 'damper', 'frequency'});

writetable(output, 'Final_Predictions.csv');
disp(output(1:10, :));  % preview

%% === Step 4: Consistency Analysis ===

% Extract case names
cases = regexp(output.file, 'case\d+', 'match');
cases = cellfun(@(x) x{1}, cases, 'UniformOutput', false);
output.case = cases;

% Extract sensor IDs (P1–P5)
sensors = regexp(output.file, '_P\d_', 'match');
sensors = strrep(strrep([sensors{:}], '_', ''), 'P', '');
output.sensor = sensors';

%% --- Inclination Prediction Consistency (P5) ---
fprintf('\n--- Inclination Prediction Consistency by Case (P5) ---\n');
P5_inc = output(strcmp(output.sensor, '5'), :);
caseList = unique(P5_inc.case);

for i = 1:numel(caseList)
    thisCase = caseList{i};
    preds = P5_inc.inclination(strcmp(P5_inc.case, thisCase));
    if all(preds == "None")
    mostCommon = "None";
    else
        % Count each label
        counts = tabulate(cellstr(preds));
        [~, idx] = max(cell2mat(counts(:,2)));  % get index of most frequent
        mostCommon = string(counts{idx,1});     % most frequent prediction
    end
    fprintf('Case %-6s | Most Consistent Prediction: %s\n', thisCase, mostCommon);
end

%% --- Damping Prediction Consistency (P5) ---
fprintf('\n--- Damping Prediction Consistency by Case (P5) ---\n');
P5_damp = output(strcmp(output.sensor, '5'), :);
for i = 1:numel(caseList)
    thisCase = caseList{i};
    preds = P5_damp.damper(strcmp(P5_damp.case, thisCase));
    if all(preds == "None")
    mostCommon = "None";
    else
        % Count each label
        counts = tabulate(cellstr(preds));
        [~, idx] = max(cell2mat(counts(:,2)));  % get index of most frequent
        mostCommon = string(counts{idx,1});     % most frequent prediction
    end
    fprintf('Case %-6s | Most Consistent Prediction: %s\n', thisCase, mostCommon);
end

%% --- Frequency Prediction Consistency (P1–P4) ---
fprintf('\n--- Frequency Prediction Consistency by Case (P1–P4) ---\n');
P1toP4_freq = output(ismember(output.sensor, {'1','2','3','4'}), :);
caseList_freq = unique(P1toP4_freq.case);

for i = 1:numel(caseList_freq)
    thisCase = caseList_freq{i};
    mask = strcmp(P1toP4_freq.case, thisCase);
    preds = P1toP4_freq.frequency(mask);
    sensors_case = P1toP4_freq.sensor(mask);
    
    % Combine sensor and prediction for grouping
    sensor_pred = strcat(sensors_case, "|", string(preds));
    [uniqueComb, ~, ic] = unique(sensor_pred);
    count = accumarray(ic, 1);
    
    % Find most frequent combination
    [~, maxIdx] = max(count);
    [sensorID, freqLabel] = strtok(uniqueComb{maxIdx}, '|');
    freqLabel = extractAfter(freqLabel, 1);  % remove '|'
    
    fprintf('Case %-6s | Most Consistent Sensor: %-2s | Prediction: %s\n', ...
            thisCase, sensorID, freqLabel);
end

