function process_C_Filtering(dataDir)
%PROCESS_C_FILTERING Applies a Savitzky-Golay filter to the data.
%   Inputs:
%       dataDir - Directory containing the .mat files to process.

folderPath = dataDir;

% Get list of all .mat files
matFiles = dir(fullfile(folderPath, '*.mat'));

% Filtering parameters
polynomial_order = 11;
frame_length_11 = 21;

% Process each file
for k = 1:length(matFiles)
    fileName = matFiles(k).name;
    filePath = fullfile(folderPath, fileName);

    % Load the file
    data = load(filePath);

    % Check for table T
    if isfield(data, 'T') && istable(data.T)
        T = data.T;

        % Filter columns 2–4
        filteredCols = T(:, 2:4);
        filteredData = varfun(@(x) sgolayfilt(x, polynomial_order, frame_length_11), filteredCols);

        % Create filtered table
        T_filtered = T(:,1:4);
        T_filtered(:, 2:4) = filteredData;

        % Save T_filtered back into the same .mat file
        save(filePath, 'T_filtered', '-append');
    else
        warning('File "%s" does not contain a table named T.', fileName);
    end
end

fprintf('Step C (Filtering) completed for directory: %s\n', dataDir);

end
