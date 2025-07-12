% Sampling frequency
Fs = 480;  % Hz

% Directory containing .mat files
folderPath = fullfile(pwd, 'Matlab_Import');
files = dir(fullfile(folderPath, '*P5*.mat'));

for k = 1:length(files)
    fileNameP5 = files(k).name;
    filePathP5 = fullfile(folderPath, fileNameP5);

    % Load P5 file
    loadedData = load(filePathP5);
    if ~isfield(loadedData, 'T_upsampled')
        fprintf('Skipping %s (T_upsampled not found)\n', fileNameP5);
        continue;
    end
    T = loadedData.T_upsampled;
    time = T{:,1};
    accZ = T{:,4};

    % ---- peak search for P5 ------------------------------------------------
    idxWindow1      = time >=  3 & time <=  9;
    [peakVal1,loc1] = max(accZ(idxWindow1));
    peakTime1       = time(idxWindow1);
    peakTime1       = peakTime1(loc1);

    idxWindow2      = time >= 40 & time <= 47;
    [peakVal2,loc2] = max(accZ(idxWindow2));
    peakTime2       = time(idxWindow2);
    peakTime2       = peakTime2(loc2);

    % Cut limits (0.5 s before each peak)
    startTime = max(peakTime1 - 0.5, time(1));
    endTime   = min(peakTime2 - 0.55, time(end));

    cutStartIdx = find(time >= startTime, 1, 'first');
    cutEndIdx   = find(time <= endTime,   1, 'last');

    % Save cut table in P5
    T_cut = T(cutStartIdx:cutEndIdx, :);
    save(filePathP5, 'T_cut', '-append');

    fprintf('Updated %s | Peak1 %.4f s (%.4f), Peak2 %.4f s (%.4f) | Cut %.4f–%.4f s (%d rows)\n\n', ...
            fileNameP5, peakTime1, peakVal1, peakTime2, peakVal2, ...
            startTime, endTime, size(T_cut,1));

    % ----- locate the matching P1–P4 files ---------------------------------
    tokens = regexp(fileNameP5,'(G\d+)_P5_(case.*)\.mat','tokens');
    if isempty(tokens), continue; end
    group    = tokens{1}{1};   % e.g. G1
    caseName = tokens{1}{2};   % e.g. case11

    for p = 1:4
        otherFileName = sprintf('%s_P%d_%s.mat', group, p, caseName);
        otherFilePath = fullfile(folderPath, otherFileName);
        if ~exist(otherFilePath,'file')
            fprintf('Missing file: %s\n', otherFileName);
            continue;
        end

        otherData = load(otherFilePath);
        if ~isfield(otherData,'T_upsampled')
            fprintf('Skipping %s (T_upsampled not found)\n', otherFileName);
            continue;
        end

        % *No cutting* for P1–P4 — just copy full table
        T_cut = otherData.T_upsampled;
        save(otherFilePath,'T_cut','-append');
        fprintf('Added full-length T_cut to %s (%d rows)\n', ...
                 otherFileName, size(T_cut,1));
    end
    fprintf('\n');
end

