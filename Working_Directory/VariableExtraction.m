folderPath = 'Matlab_Import'; % Folder with .mat files
files = dir(fullfile(folderPath, '*.mat'));

for k = 1:length(files)
    fileName = files(k).name;
    filePath = fullfile(folderPath, fileName);
    
    data = load(filePath, 'T');
    if isfield(data, 'T') && istable(data.T)
        T = data.T;
        timeVec = T{:,1}; % First column as vector
        
        if length(timeVec) > 1
            dt = diff(timeVec);
            dt = dt(dt > 0); % remove invalid intervals
            
            if ~isempty(dt)
                avg_dt = mean(dt);
                fs = 1 / avg_dt; % raw sampling rate

                % Apply rounding rules
                if abs(fs - 99) <= 2 || abs(fs - 101) <= 2
                    fs_adj = 100;
                elseif abs(fs - 121) <= 2 || abs(fs - 122) <= 2
                    fs_adj = 120;
                elseif abs(fs - 202) <= 3
                    fs_adj = 200;
                elseif abs(fs - 398) <= 5
                    fs_adj = 400;
                elseif abs(fs - 477) <= 5
                    fs_adj = 480;
                else
                    fs_adj = round(fs); % default rounding
                end
                
                SamplingRate = fs_adj;
                new_dt = 1 / SamplingRate;

                % Replace the time column with new uniform time vector
                nRows = height(T);
                startTime = timeVec(1); % keep original start time
                newTimeVec = startTime + (0:nRows-1)' * new_dt;

                T{:,1} = newTimeVec; % overwrite time column

                % Save updated T and SamplingRate
                save(filePath, 'T', 'SamplingRate', '-append');
            else
                warning('File %s has invalid time intervals.', fileName);
            end
        else
            warning('File %s has insufficient time data.', fileName);
        end
    else
        warning('File %s does not contain a table named T.', fileName);
    end
end

disp('All .mat files updated with uniform time intervals and sampling rates.');
