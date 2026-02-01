function process_F_Normallization(dataDir)
%PROCESS_F_NORMALLIZATION Normalizes the signal data to the range [-1, 1].
%   Inputs:
%       dataDir - Directory containing the .mat files to process.

folderPath = dataDir;
fileList = dir(fullfile(folderPath, '*.mat'));

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
    else
        warning('No T_cut found in %s\n', fileName);
    end
end

fprintf('Step F (Normallization) completed for directory: %s\n', dataDir);

end
