% Define the folder path
% Directory containing .mat files
folderPath = fullfile(pwd, 'Matlab_Import');
fileList = dir(fullfile(folderPath, '*P5*.mat'));

for k = 1:length(fileList)
    fileName = fileList(k).name;
    filePath = fullfile(folderPath, fileName);
    
    % Load T_cut from file
    data = load(filePath, 'T_cut');
    
    if isfield(data, 'T_cut')
        T_cut = data.T_cut;
        
        % Initialize output table
        T_normalized = T_cut;

        % Normalize each column except the first (assumed time)
        for col = 2:width(T_cut)
            x = T_cut{:, col};
            minX = min(x);
            maxX = max(x);
            if maxX ~= minX
                x_norm = 2 * (x - minX) / (maxX - minX) - 1;
            else
                x_norm = zeros(size(x)); % Avoid NaNs if constant
            end
            T_normalized{:, col} = x_norm;
        end

        % Save T_normalized to the same .mat file
        save(filePath, 'T_normalized', '-append');

        fprintf('Normalized and saved: %s\n', fileName);
    else
        warning('No T_cut found in %s\n', fileName);
    end
end
