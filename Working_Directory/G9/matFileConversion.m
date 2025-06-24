clc;
clear;

% Define parameters
Ps = 1:5;
Cases = 91:96;

% Initialize variable to track minimum data size
minDataLength = inf;  % Start with infinity so any real size will be smaller

for p = Ps
    for c = Cases
        % Construct file name
        filename = sprintf('G9_P%d_case%d.xls', p, c);
        
        if isfile(filename)
            % Read the table from sheet 1, columns A to E
            T = readtable(filename, 'Sheet', 1, 'Range', 'A:E');
            data = table2array(T);
            
            % Update minimum data size
            dataLength = size(data, 1);
            if dataLength < minDataLength
                minDataLength = dataLength;
            end
            
            % Calculate time vector
            time = data(:,1) - data(1,1);
            data(:,1) = time;
            ax = data(:,2);
            ay = data(:,3);
            az = data(:,4);
            aTotal = data(:,5);
            
            % Calculate and round sampling rate
            dt = diff(time);
            samplingRate = round(1 / mean(dt));
            
            % Save .mat file
            mat_filename = sprintf('p%d_case%d.mat', p, c);
            save(mat_filename, 'data', 'time', 'samplingRate', "ax","ay","az","aTotal");
            
            fprintf('Processed and saved %s (Sampling rate: %d Hz, Data length: %d)\n', ...
                mat_filename, samplingRate, dataLength);
        else
            warning('File %s does not exist. Skipping...', filename);
        end
    end
end

% Display the minimum data size encountered
fprintf('\nMinimum data length found across all files: %d samples\n', minDataLength);
clear;
