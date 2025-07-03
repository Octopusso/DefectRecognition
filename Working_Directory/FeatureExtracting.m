%% Feature Extraction – Minimal Feature Set
% -----------------------------------------------------------------------
% This script scans *.mat files in the folder `Matlab_Import` (or another
% folder you specify) that contain a table `T_cut` with at least:
%   • Column 1 – time (s)
%   • Column 4 – z‑axis acceleration (m/s²)
%
% For every non‑overlapping 1‑second window it calculates only the features
% you requested:
%   segment   – window index (1, 2, …)
%   rms_acc   – root‑mean‑square acceleration
%   peak_acc  – maximum absolute acceleration
%   rms_vel   – root‑mean‑square velocity (integrated acc)
%   peak_vel  – maximum absolute velocity
%
% The output table `featuresTable` keeps the **file name as the first
% column**, followed by the five variables above, and is appended back to
% the source *.mat file.
% -----------------------------------------------------------------------

%% Configuration
% Adjust these if your setup differs.
dataFolder   = 'Matlab_Import';   % Folder containing the source *.mat files
fs           = 480;               % Sampling frequency (Hz)
windowLength = fs;                % Samples per 1‑second window
colAccel     = 4;                 % Column index for z‑axis acceleration

%% Locate files (example pattern: all *P5*.mat)
folderPath = fullfile(pwd, dataFolder);
fileList   = dir(fullfile(folderPath, '*P5*.mat'));

%% Main loop
for iFile = 1:numel(fileList)
    fname = fileList(iFile).name;
    fpath = fullfile(folderPath, fname);

    % Load the required table -------------------------------------------
    S = load(fpath, 'T_cut');
    if ~isfield(S, 'T_cut')
        warning('Table T_cut not found in %s – skipped.', fname);
        continue;
    end
    T = S.T_cut;

    % Basic validation ---------------------------------------------------
    if width(T) < colAccel
        warning('File %s has fewer than %d columns – skipped.', fname, colAccel);
        continue;
    end

    timeVec = T{:,1};            % Time stamps (s)
    accZ    = T{:,colAccel};     % Z‑axis acceleration (m/s²)

    if numel(accZ) < windowLength
        warning('File %s has < 1 second of data – skipped.', fname);
        continue;
    end

    %% Segment‑wise processing ------------------------------------------
    featureRecords = struct( ...   % pre‑allocate empty struct array
        'file'    , {}, ...
        'segment' , {}, ...
        'rms_acc' , {}, ...
        'peak_acc', {}, ...
        'rms_vel' , {}, ...
        'peak_vel', {}  );

    numSegments = floor(numel(accZ) / windowLength);

    for seg = 1:numSegments
        idxStart = (seg-1)*windowLength + 1;
        idxEnd   = seg*windowLength;
        segAcc   = accZ(idxStart:idxEnd);

        %% Compute features for this window
        featsStruct            = extractFeatures(segAcc, fs);
        featsStruct.file       = string(fname);   % file name first
        featsStruct.segment    = seg;             % window index

        featureRecords(end+1) = featsStruct;      %#ok<AGROW>
    end

    %% Convert to table and reorder columns -----------------------------
    if isempty(featureRecords)
        warning('No segments processed in %s – nothing saved.', fname);
        continue;
    end

    featuresTable = struct2table(featureRecords);

    % Order: file | segment | rms_acc | peak_acc | rms_vel | peak_vel
    featuresTable = movevars(featuresTable, 'file',    'Before', 1);
    featuresTable = movevars(featuresTable, 'segment', 'After',  'file');

    %% Append to the same *.mat file ------------------------------------
    save(fpath, 'featuresTable', '-append');
    fprintf('Processed %s – %d segment(s) extracted.\n', fname, height(featuresTable));
end

%% ----------------------------------------------------------------------
function feats = extractFeatures(acc, fs)
%EXTRACTFEATURES  Compute the minimal feature set for a 1‑s window.
%   acc : Nx1 acceleration samples (m/s²)
%   fs  : sampling frequency (Hz)
%
% Returns a structure with fields:
%   rms_acc, peak_acc, rms_vel, peak_vel

    %% Acceleration features
    rms_acc  = rms(acc);
    peak_acc = max(abs(acc));

    %% Velocity via numerical integration
    dt       = 1/fs;
    vel      = cumtrapz(acc) * dt;  % starts at 0; drift negligible over 1 s
    rms_vel  = rms(vel);
    peak_vel = max(abs(vel));

    %% Package output
    feats = struct( ...
        'rms_acc' , rms_acc , ...
        'peak_acc', peak_acc, ...
        'rms_vel' , rms_vel , ...
        'peak_vel', peak_vel );
end
