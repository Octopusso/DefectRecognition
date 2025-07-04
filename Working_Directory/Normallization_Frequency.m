% Define the folder path
% Directory containing .mat files
folderPath = fullfile(pwd, 'Matlab_Import');
fileList = dir(fullfile(folderPath, '*.mat'));

for k = 1:length(fileList)
    fileName = fileList(k).name;
    filePath = fullfile(folderPath, fileName);
    
    % Load T_upsampled from file
    data = load(filePath, 'T_upsampled');
    
    if isfield(data, 'T_upsampled')
        T_upsampled = data.T_upsampled;
        
        % Initialize output table
        T_normalized_frequency = T_upsampled;

        % Normalize each column except the first (assumed time)
        for col = 2:width(T_upsampled)
            x = T_upsampled{:, col};
            minX = min(x);
            maxX = max(x);
            if maxX ~= minX
                x_norm = 2 * (x - minX) / (maxX - minX) - 1;
            else
                x_norm = zeros(size(x)); % Avoid NaNs if constant
            end
            T_normalized_frequency{:, col} = x_norm;
        end

        % Save T_normalized_frequency to the same .mat file
        save(filePath, 'T_normalized_frequency', '-append');

        fprintf('Normalized and saved: %s\n', fileName);
    else
        warning('No T_upsampled found in %s\n', fileName);
    end
end
