function process_G_FeatureExtraction(dataDir, labelFilePath)
%PROCESS_G_FEATUREEXTRACTION Extracts features from the normalized signals.
%   Inputs:
%       dataDir        - Directory containing the .mat files with T_normalized.
%       labelFilePath  - Full path to the 'GeneralLable.xlsx' file.

%% Configuration
fs           = 480;              % Sampling frequency (Hz)
windowLength = fs*2;               % 2-second windows
colAccel     = 4;                % Column for z-acceleration

%% Load labeling data
% For prediction, labels might not exist, so handle this gracefully.
try
    labelTableRaw = readtable(labelFilePath);
    labelTable = labelTableRaw;
    labelTable.Properties.VariableNames = lower(strrep(labelTable.Properties.VariableNames, ' ', ''));
    useLabels = true;
    if ~ismember('file', labelTable.Properties.VariableNames)
        warning('Column "file" not found in %s. Cannot apply labels.', labelFilePath);
        useLabels = false;
    end
catch ME
    warning('Could not read label file: %s. Proceeding without labels.', ME.message);
    useLabels = false;
end

%% Find all .mat files
fileList   = dir(fullfile(dataDir, '*.mat'));

%% Process each file
for iFile = 1:numel(fileList)
    fname = fileList(iFile).name;
    fpath = fullfile(dataDir, fname);
    
    S = load(fpath, 'T_normalized');
    if ~isfield(S, 'T_normalized')
        continue;
    end
    T = S.T_normalized;

    if width(T) < colAccel
        continue;
    end

    accZ = T{:, colAccel};
    if numel(accZ) < windowLength
        continue;
    end

    %% Segment-wise feature extraction
    featureRecords = struct('file', {}, 'segment', {}, ...
    'rms_acc', {}, 'rms_vel', {}, 'damping_ratio', {}, ...
    'peak_vel', {}, 'rms_pos', {}, ...
    'amplitude', {}, 'zcr', {}, 'rms', {}, ...
    'dominant_freq', {});

    numSegments = floor(numel(accZ) / windowLength);
    for seg = 1:numSegments
        idxStart = (seg-1)*windowLength + 1;
        idxEnd   = seg*windowLength;
        segAcc   = accZ(idxStart:idxEnd);

        feats            = extractLocalFeatures(segAcc, fs);
        feats.file       = string(fname);
        feats.segment    = seg;
        featureRecords(end+1) = feats; %#ok<AGROW>
    end

    if isempty(featureRecords)
        continue;
    end

    %% Build table and add labels if available
    featuresTable = struct2table(featureRecords);
    featuresTable = movevars(featuresTable, 'file', 'Before', 'segment');
    featuresTable = movevars(featuresTable, 'segment', 'After', 'file');

    if useLabels
        labelIdx = strcmpi(labelTable.file, fname);
        if any(labelIdx)
            labelRow = labelTable(labelIdx, :);
            featuresTable.inc_deg   = repmat(labelRow.inc_deg, height(featuresTable), 1);
            featuresTable.inc_loc   = repmat(labelRow.inc_loc, height(featuresTable), 1);
            featuresTable.damp      = repmat(labelRow.damp, height(featuresTable), 1);
            featuresTable.damp_loc  = repmat(labelRow.damp_loc, height(featuresTable), 1);
            featuresTable.freq      = repmat(labelRow.freq, height(featuresTable), 1);
            featuresTable.freq_loc  = repmat(labelRow.freq_loc, height(featuresTable), 1);
        end
    end

    %% Save updated .mat with renamed variable
    General_Features = featuresTable;
    save(fpath, 'General_Features', '-append');
end

fprintf('Step G (Feature Extraction) completed for directory: %s\n', dataDir);

end


%% Local feature extraction function
function feats = extractLocalFeatures(acc, fs)
    % === Unfiltered Features ===
    rms_acc = rms(acc);

    % Velocity
    vel = cumtrapz(acc) / fs;
    rms_vel = rms(vel);
    peak_vel = max(abs(vel));

    % Position
    pos = cumtrapz(vel) / fs;
    rms_pos = rms(pos);

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
    [b, a] = butter(4, [bp_low, bp_high] / (fs/2), "bandpass");
    acc_filt = filtfilt(b, a, acc);

    L = length(acc_filt);
    Y = fft(acc_filt);
    P2 = abs(Y / L);

    amplitude = max(P2(1:floor(L/2)));
    f = fs * (0:(L/2)-1) / L;
    [~, maxIdx] = max(P2(1:floor(L/2)));
    dominant_freq = f(maxIdx);

    % General RMS (energy-like) – still from unfiltered signal
    signal_rms = sqrt(mean(acc.^2));

    % Return feature struct
    feats = struct(... 
        'rms_vel', rms_vel, ...
        'rms_acc', rms_acc, ...
        'damping_ratio', damping_ratio, ...
        'peak_vel', peak_vel, ...
        'rms_pos', rms_pos, ...
        'amplitude', amplitude, ...
        'zcr', zcr, ...
        'rms', signal_rms, ...
        'dominant_freq', dominant_freq ...
    );
end
