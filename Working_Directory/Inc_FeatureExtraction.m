%% Feature Extraction – Minimal Feature Set (Regular + Perfect P5 Only)
% -----------------------------------------------------------------------
% Supported filename patterns:
%   • Regular cases: g[1-9]_p5_case[1-9][23]
%   • Perfect case : g0_p5_case_perfect
%
% Each .mat file must include `T_normalized` with:
%   • Column 1 – time (s)
%   • Column 4 – z‑axis acceleration (m/s²)
% -----------------------------------------------------------------------

%% Configuration
dataFolder   = 'Matlab_Import';  % Folder with .mat files
fs           = 480;              % Sampling frequency (Hz)
windowLength = fs*2;               % 1-second windows
colAccel     = 4;                % Column for z-acceleration

%% Load labeling data
labelTableRaw = readtable('Labeling.xlsx');

% Normalize column names
labelTable = labelTableRaw;
labelTable.Properties.VariableNames = lower(strrep(labelTable.Properties.VariableNames, ' ', ''));
if ~ismember('casename', labelTable.Properties.VariableNames)
    error('Column "case name" not found in Labeling.xlsx.');
end

%% Find matching files
folderPath = fullfile(pwd, dataFolder);
allFiles   = dir(fullfile(folderPath, '*.mat'));

% Match only regular + perfect P5 file
pattern_regular = '^g[1-9]_p5_case\d*2\.mat$';
pattern_perfect = 'g0_p5_case_perfect';

isMatch = cellfun(@(n) ...
    ~isempty(regexp(lower(n), pattern_regular, 'once')) || ...
    strcmpi(lower(n), 'g0_p5_case_perfect.mat'), ...
    {allFiles.name});

fileList = allFiles(isMatch);

fprintf('\n=== File discovery summary ===\n');
if isempty(fileList)
    fprintf('No matching files in %s\n', folderPath);
    return;
end
fprintf('Found %d matching file(s):\n', numel(fileList));
for i = 1:numel(fileList)
    fprintf('  %s\n', fileList(i).name);
end
fprintf('==============================\n\n');

%% Process each file
for iFile = 1:numel(fileList)
    fname = fileList(iFile).name;
    fpath = fullfile(folderPath, fname);
    fprintf('\n--- Processing %s ---\n', fname);

    % Load .mat file with T_normalized
    S = load(fpath, 'T_normalized');
    if ~isfield(S, 'T_normalized')
        fprintf('  → T_normalized not found – skipped.\n');
        continue;
    end
    T = S.T_normalized;

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
    'rms_acc', {}, 'peak_acc', {}, ...
    'rms_vel', {}, 'peak_vel', {}, ...
    'rms_pos', {}, 'peak_pos', {}, ...
    'zcr', {}, 'energy_decay_rate', {}, ...
    'damping_ratio', {}, 'dominant_freq', {});

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
    labelIdx = strcmpi(labelTable.casename, fname);
    if any(labelIdx)
        labelRow = labelTable(labelIdx, :);
        featuresTable.inc_deg   = repmat(labelRow.inc_deg, height(featuresTable), 1);
        featuresTable.inc_loc   = repmat(labelRow.inc_loc, height(featuresTable), 1);
        featuresTable.damp      = repmat(labelRow.damp, height(featuresTable), 1);
        featuresTable.damp_loc  = repmat(labelRow.damp_loc, height(featuresTable), 1);
        fprintf('  → Label columns added.\n');
    else
        fprintf('  → Label not found in Labeling.xlsx – skipped labeling.\n');
    end

  %% Save updated .mat with renamed variable
IncFeaturesTable = featuresTable;
save(fpath, 'IncFeaturesTable', '-append');
fprintf('  → Saved IncFeaturesTable (%d rows) to %s\n', height(IncFeaturesTable), fname);
end

fprintf('\n=== All processing complete. ===\n');

%% Feature extraction function
function feats = extractFeatures(acc, fs)
    % RMS and peak acceleration
    rms_acc  = rms(acc);
    peak_acc = max(abs(acc));

    % Velocity
    vel      = cumtrapz(acc) / fs;
    rms_vel  = rms(vel);
    peak_vel = max(abs(vel));

    % Position
    pos      = cumtrapz(vel) / fs;
    rms_pos  = rms(pos);
    peak_pos = max(abs(pos));

    % Zero Crossing Rate
    zcr = sum(diff(sign(acc)) ~= 0) / length(acc);

    % Energy decay rate
    energy = acc.^2;
    decay = energy(1:end-1) - energy(2:end);
    energy_decay_rate = mean(decay(decay > 0), 'omitnan');

    % Damping ratio (via log decrement)
    [pks, ~] = findpeaks(abs(acc));
    if length(pks) >= 2
        delta = log(pks(1) / pks(2));
        damping_ratio = delta / sqrt(4*pi^2 + delta^2);
    else
        damping_ratio = NaN;
    end

    % Dominant frequency
    L = length(acc);
    Y = fft(acc);
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = fs*(0:(L/2))/L;
    [~, idxMax] = max(P1);
    dominant_freq = f(idxMax);

    feats = struct('rms_acc',  rms_acc, ...
                   'peak_acc', peak_acc, ...
                   'rms_vel',  rms_vel, ...
                   'peak_vel', peak_vel, ...
                   'rms_pos',  rms_pos, ...
                   'peak_pos', peak_pos, ...
                   'zcr',      zcr, ...
                   'energy_decay_rate', energy_decay_rate, ...
                   'damping_ratio', damping_ratio, ...
                   'dominant_freq', dominant_freq);
end

