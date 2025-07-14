%% Feature Extraction – From All Files
% -----------------------------------------------------------------------

%% Configuration
dataFolder   = 'Matlab_Import';  % Folder with .mat files
fs           = 480;              % Sampling frequency (Hz)
windowLength = fs * 2;           % 2-second windows
colAccel     = 4;                % Column for z-acceleration

%% Load labeling data
labelTableRaw = readtable('GeneralLable.xlsx');
labelTable = labelTableRaw;
labelTable.Properties.VariableNames = lower(strrep(labelTable.Properties.VariableNames, ' ', ''));
if ~ismember('file', labelTable.Properties.VariableNames)
    error('Column "case name" not found in GeneralLable.xlsx.');
ends

%% Find all .mat files
folderPath = fullfile(pwd, dataFolder);
fileList   = dir(fullfile(folderPath, '*.mat'));

fprintf('\n=== File discovery summary ===\n');
if isempty(fileList)
    fprintf('No .mat files found in %s\n', folderPath);
    return;
end

fprintf('Found %d file(s):\n', numel(fileList));
for i = 1:numel(fileList)
    fprintf('  %s\n', fileList(i).name);
end
fprintf('==============================\n\n');

%% Process each file
for iFile = 1:numel(fileList)
    fname = fileList(iFile).name;
    fpath = fullfile(folderPath, fname);
    fprintf('\n--- Processing %s ---\n', fname);

    % Load .mat file with T_cut_damper
    S = load(fpath, 'T_cut_damper');
    if ~isfield(S, 'T_cut_damper')
        fprintf('  → T_cut_damper not found – skipped.\n');
        continue;
    end
    T = S.T_cut_damper;

    if width(T) < colAccel
        fprintf('  → < %d columns – skipped.\n', colAccel);
        continue;
    end

    accZ = T{:, colAccel};
    if numel(accZ) < windowLength
        fprintf('  → < 1 s of data – skipped.\n');
        continue;
    end

    %% Segment-wise feature extraction
    featureRecords = struct('file', {}, 'segment', {}, ...
        'peak_acc', {}, 'rms_acc', {}, 'crest_factor', {}, 'rms_vel', {}, ...
        'damping_ratio', {}, 'peak_vel', {}, 'rms_pos', {}, ...
        'amplitude', {}, 'zcr', {}, 'rms', {}, ...
        'dominant_freq', {}, 'skewness', {}, 'kurtosis', {}, ...
        'peak_diff', {});

    numSegments = floor(numel(accZ) / windowLength);
    for seg = 1:numSegments
        idxStart = (seg-1)*windowLength + 1;
        idxEnd   = seg*windowLength;
        segAcc   = accZ(idxStart:idxEnd);

        feats            = extractFeatures(segAcc, fs);
        feats.file       = string(fname);
        feats.segment    = seg;
        featureRecords(end+1) = feats; %#ok<AGROW>
    end

    if isempty(featureRecords)
        fprintf('  → No valid segments – skipped.\n');
        continue;
    end

    %% Build table
    featuresTable = struct2table(featureRecords);
    featuresTable = movevars(featuresTable, 'file', 'Before', 'segment');
    featuresTable = movevars(featuresTable, 'segment', 'After', 'file');

    %% Label lookup
    labelIdx = strcmpi(labelTable.file, fname);
    if any(labelIdx)
        labelRow = labelTable(labelIdx, :);
        featuresTable.inc_deg   = repmat(labelRow.inc_deg, height(featuresTable), 1);
        featuresTable.inc_loc   = repmat(labelRow.inc_loc, height(featuresTable), 1);
        featuresTable.damp      = repmat(labelRow.damp, height(featuresTable), 1);
        featuresTable.damp_loc  = repmat(labelRow.damp_loc, height(featuresTable), 1);
        featuresTable.freq      = repmat(labelRow.freq, height(featuresTable), 1);
        featuresTable.freq_loc  = repmat(labelRow.freq_loc, height(featuresTable), 1);
        fprintf('  → Label columns added.\n');
    else
        fprintf('  → Label not found in GeneralLable.xlsx – skipped labeling.\n');
    end

    %% Save updated .mat with renamed variable
    General_Features = featuresTable;
    save(fpath, 'General_Features', '-append');
    fprintf('  → Saved General_Features (%d rows) to %s\n', height(General_Features), fname);
end

fprintf('\n=== All processing complete. ===\n');

%% Feature extraction function
function feats = extractFeatures(acc, fs)
    % === Unfiltered Features ===
    rms_acc = rms(acc);
    peak_acc = max(abs(acc));

    % Crest Factor (Peak-to-RMS ratio)
    if rms_acc > 0
        crest_factor = peak_acc / rms_acc;
    else
        crest_factor = NaN;
    end

    % Velocity
    vel = cumtrapz(acc) / fs;
    rms_vel = rms(vel);
    peak_vel = max(abs(vel));

    % Position
    pos = cumtrapz(vel) / fs;
    rms_pos = rms(pos);

    % Peak difference feature (difference between two highest peaks)
    [pks, ~] = findpeaks(abs(acc), 'SortStr', 'descend');
    if length(pks) >= 2
        peak_diff = abs(pks(1) - pks(2));
    else
        peak_diff = 0;
    end

    % Zero Crossing Rate
    zcr = sum(diff(sign(acc)) ~= 0) / length(acc);

    % Damping ratio (log decrement)
    [pks, ~] = findpeaks(abs(acc));
    if length(pks) >= 2
        delta = log(pks(1)/pks(2));
        damping_ratio = delta / sqrt(4*pi^2 + delta^2);
    else
        damping_ratio = NaN;
    end

    % === FFT Features (on filtered signal) ===
    bp_low  = 29;
    bp_high = 51;
    [b, a] = butter(4, [bp_low, bp_high] / (fs/2), 'bandpass');
    acc_filt = filtfilt(b, a, acc);

    L = length(acc_filt);
    Y = fft(acc_filt);
    P2 = abs(Y / L);

    amplitude = max(P2(1:floor(L/2)));
    f = fs * (0:(L/2)-1) / L;
    [~, maxIdx] = max(P2(1:floor(L/2)));
    dominant_freq = f(maxIdx);

    % General RMS (energy-like)
    signal_rms = sqrt(mean(acc.^2));

    % New statistical features
    skewness_val = skewness(acc);
    kurtosis_val = kurtosis(acc);

    % Return feature struct
    feats = struct(...
        'rms_vel', rms_vel, ...
        'rms_acc', rms_acc, ...
        'peak_acc', peak_acc, ...
        'crest_factor', crest_factor, ...
        'damping_ratio', damping_ratio, ...
        'peak_vel', peak_vel, ...
        'rms_pos', rms_pos, ...
        'amplitude', amplitude, ...
        'zcr', zcr, ...
        'rms', signal_rms, ...
        'dominant_freq', dominant_freq, ...
        'skewness', skewness_val, ...
        'kurtosis', kurtosis_val, ...
        'peak_diff', peak_diff ...
    );
end
