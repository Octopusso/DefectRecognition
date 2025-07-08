% Define paths
srcFolder = fullfile(pwd, 'Matlab_Import');
allFiles = dir(fullfile(srcFolder, '*.mat'));

% Initialize reference structure
referenceVarNames = {};
referenceFile = '';

for i = 1:length(allFiles)
    fpath = fullfile(srcFolder, allFiles(i).name);
    data = load(fpath);
    
    if isfield(data, 'General_Features')
        tbl = data.General_Features;
        varNames = tbl.Properties.VariableNames;
        
        fprintf('📄 %s: %d rows × %d cols\n', allFiles(i).name, size(tbl,1), size(tbl,2));
        
        % Save reference from first valid file
        if isempty(referenceVarNames)
            referenceVarNames = varNames;
            referenceFile = allFiles(i).name;
        else
            % Compare column count
            if length(varNames) ~= length(referenceVarNames)
                fprintf('❌ Column count mismatch in file: %s\n', allFiles(i).name);
            end
            
            % Compare column names
            if ~isequal(varNames, referenceVarNames)
                fprintf('❌ Column names mismatch in file: %s\n', allFiles(i).name);
                fprintf('Expected: %s\n', strjoin(referenceVarNames, ', '));
                fprintf('Found   : %s\n\n', strjoin(varNames, ', '));
            end
        end
    else
        fprintf('⚠️ No General_Features table in: %s\n', allFiles(i).name);
    end
end
