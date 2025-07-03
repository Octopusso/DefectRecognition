% Directory containing .mat files
folderPath = fullfile(pwd, 'Matlab_Import');
files = dir(fullfile(folderPath, '*P5*.mat'));

% ---- First cut parameters (0–6s) ----
col1 = 4;
thresh1 = 0.1;
interval1 = 0.1;
max_time1 = 6;

% ---- Second cut parameters (40–46s) ----
col2 = 4;
thresh2 = 1;
interval2 = 0.1;
start_time2 = 40;
max_time2 = 6;  % analyze from 40 to 46s

for k = 1:length(files)
    filePath = fullfile(folderPath, files(k).name);
    fileData = load(filePath);

    if ~isfield(fileData, 'T_upsampled')
        fprintf('Skipping %s: T_upsampled not found.\n', files(k).name);
        continue;
    end

    T = fileData.T_upsampled;
    time = T{:,1};
    signal = T{:, col1};

    if any(diff(time) <= 0)
        fprintf('Skipping %s: non-monotonic time values.\n', files(k).name);
        continue;
    end

    % ---------- First Cut Time (start_time) ----------
    prev_mean = mean(signal(time >= 0 & time < interval1));
    t_start = 0;
    for t = interval1 : interval1 : max_time1
        curr_mean = mean(signal(time >= t & time < t + interval1));
        if abs(curr_mean - prev_mean) > thresh1
            t_start = t;
            break;
        end
        prev_mean = curr_mean;
    end

    % ---------- Second Cut Time (end_time) ----------
    prev_mean = mean(signal(time >= start_time2 & time < start_time2 + interval2));
    t_end = time(end);  % fallback to end of signal
    for t = start_time2 + interval2 : interval2 : start_time2 + max_time2
        curr_mean = mean(signal(time >= t & time < t + interval2));
        if abs(curr_mean - prev_mean) > thresh2
            t_end = t;
            break;
        end
        prev_mean = curr_mean;
    end

    % ---------- Cut Data Between t_start and t_end ----------
    keep_idx = time >= t_start & time <= t_end;
    T_cut = T(keep_idx, :);

    % Save result
    save(filePath, 'T_cut', '-append');

    % Save to workspace
    [~, baseName, ~] = fileparts(files(k).name);
    varName = matlab.lang.makeValidName(['T_cut_' baseName]);
    assignin('base', varName, T_cut);

    fprintf('Saved T_cut for %s (%.2f s to %.2f s)\n', files(k).name, t_start, t_end);
end
