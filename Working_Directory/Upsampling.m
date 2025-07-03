% Define parameters
folderPath = './Matlab_Import'; % adjust if needed
targetFs = 480;  % Target sampling frequency (Hz)

% Get all .mat files in the folder
fileList = dir(fullfile(folderPath, '*.mat'));

for i = 1:length(fileList)
    % Load the .mat file
    filePath = fullfile(folderPath, fileList(i).name);
    data = load(filePath);

    % Check if T_filtered exists
    if isfield(data, 'T_filtered')
        T_filtered = data.T_filtered;

        % Extract time and data
        time = T_filtered{:,1};
        dataVals = T_filtered{:,2:end};
        
        % Calculate original sampling rate
        dt = mean(diff(time));
        origFs = 1 / dt;

        % Time vector for upsampled data
        totalTime = time(end) - time(1);
        newTime = (0 : 1/targetFs : totalTime)';
        newTime = newTime + time(1);  % align start time

        % Preallocate upsampled data
        newData = zeros(length(newTime), size(dataVals,2));
        
        % Interpolate each column
        for j = 1:size(dataVals,2)
            newData(:,j) = interp1(time, dataVals(:,j), newTime, 'linear');
        end

        % Construct new table
        T_upsampled = array2table([newTime, newData], ...
            'VariableNames', T_filtered.Properties.VariableNames);

        % Save into the same .mat file
        save(filePath, 'T_upsampled', '-append');
    else
        warning('T_filtered not found in %s. Skipped.', fileList(i).name);
    end
end

disp('Upsampling complete.');
