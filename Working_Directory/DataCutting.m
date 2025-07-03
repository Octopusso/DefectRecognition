% Sampling frequency
Fs = 480;  % Hz

% Directory containing .mat files
folderPath = fullfile(pwd, 'Matlab_Import');
files = dir(fullfile(folderPath, '*P5*.mat'));

for k = 1:length(files)
    fileName = files(k).name;
    filePath = fullfile(folderPath, fileName);

    loadedData = load(filePath);

    if ~isfield(loadedData, 'T_upsampled')
        fprintf('Skipping %s (T_upsampled not found)\n', fileName);
        continue;
    end

    T = loadedData.T_upsampled;
    time = T{:, 1};
    accZ = T{:, 4};

    %% Find peak in 3-9 seconds window
    idxWindow1 = find(time >= 3 & time <= 9);
    time_window1 = time(idxWindow1);
    accZ_window1 = accZ(idxWindow1);
    [peakVal1, peakIdx1] = max(accZ_window1);
    peakTime1 = time_window1(peakIdx1);

    %% Find peak in 40-47 seconds window
    idxWindow2 = find(time >= 40 & time <= 47);
    time_window2 = time(idxWindow2);
    accZ_window2 = accZ(idxWindow2);
    [peakVal2, peakIdx2] = max(accZ_window2);
    peakTime2 = time_window2(peakIdx2);

    %% Calculate start and end cut times (0.5 sec before peaks)
    startTime = peakTime1 - 0.5;
    endTime = peakTime2 - 0.55;

    % Ensure startTime and endTime are within data range
    startTime = max(startTime, time(1));
    endTime = min(endTime, time(end));

    %% Find corresponding indices in full data
    cutStartIdx = find(time >= startTime, 1, 'first');
    cutEndIdx = find(time <= endTime, 1, 'last');

    %% Extract the cut data table
    T_cut = T(cutStartIdx:cutEndIdx, :);

    %% Save T_cut back to the same .mat file
    save(filePath, 'T_cut', '-append');

    %% Report
    fprintf('Updated file: %s\n', fileName);
    fprintf('Peak1 at %.4f sec (value %.4f), Peak2 at %.4f sec (value %.4f)\n', ...
            peakTime1, peakVal1, peakTime2, peakVal2);
    fprintf('Cut data from %.4f to %.4f sec, size: %d x %d\n\n', ...
            startTime, endTime, size(T_cut,1), size(T_cut,2));
end
