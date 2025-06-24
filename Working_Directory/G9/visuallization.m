% plot_case91_motion_data.m

% Clear workspace and figures
clear;
close all;

% Create figures
figure(1); hold on; grid on;
title('Acceleration vs Time'); xlabel('Time [s]'); ylabel('Acceleration [units]');
colors = lines(5);

figure(2); hold on; grid on;
title('Velocity (Integrated Acceleration) vs Time'); xlabel('Time [s]'); ylabel('Velocity [units]');

figure(3); hold on; grid on;
title('Position (Integrated Velocity) vs Time'); xlabel('Time [s]'); ylabel('Position [units]');

% Loop over all cases
for i = 1:4
    % Build filename
    filename = sprintf('p%d_case91.mat', i);

    % Load .mat file
    loaded = load(filename);

    % Extract time and data
    time = loaded.time;
    data = loaded.data;

    % Check for valid acceleration data
    if size(data, 2) < 3
        warning('%s does not have at least 3 columns in data.', filename);
        continue;
    end

    % Extract acceleration
    acceleration = data(:,2);

    % Integrate acceleration -> velocity
    velocity = cumtrapz(time, acceleration);

    % Integrate velocity -> position
    position = cumtrapz(time, velocity);

    % Plot acceleration
    figure(1);
    plot(time, acceleration, 'DisplayName', sprintf('p%d', i), 'Color', colors(i,:));

    % Plot velocity
   figure(2);
    plot(time, velocity, 'DisplayName', sprintf('p%d', i), 'Color', colors(i,:));

    % Plot position
    figure(3);
    plot(time, position, 'DisplayName', sprintf('p%d', i), 'Color', colors(i,:));
end

% Add legends to all figures
for fig = 1:3
    figure(fig);
    legend show;
end
