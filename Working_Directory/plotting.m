% Assume T and T_filtered are already loaded and exist in the workspace

% % Extract time and signal
% time = T{:,1};                 % First column: time
% signal_raw = T{:,4};           % Fourth column: raw signal
% signal_filtered = T_filtered{:,4};  % Fourth column: filtered signal
% 
% % Plotting
% figure;
% plot(time, signal_raw, 'b-', 'DisplayName', 'Raw Signal');
% hold on;
% plot(time, signal_filtered, 'r-', 'DisplayName', 'Filtered Signal');
% xlabel('Time (s)');
% ylabel('Signal Value');
% title('Raw vs. Filtered Signal (4th Column)');
% legend;
% grid on;

%% Comparing Upsampling

% %Extract time and 4th column from both tables
% time_filtered = T_filtered{:,1};
% val_filtered = T_filtered{:,4};
% 
% time_upsampled = T_upsampled{:,1};
% val_upsampled = T_upsampled{:,4};
% 
% % Plot
% figure;
% plot(time_filtered, val_filtered, 'o-', 'DisplayName', 'Filtered (Original)');
% hold on;
% plot(time_upsampled, val_upsampled, '-', 'DisplayName', 'Upsampled (480 Hz)');
% xlabel('Time (s)');
% ylabel(T_filtered.Properties.VariableNames{4});
% title('Comparison of Filtered vs Upsampled Data');
% legend;
% grid on;

%% Noormalization Comparision
% % Extract time (assumed to be column 1)
% time = T_cut{:,1}; 
% % Extract 4th column data
% signal_cut  = T_cut{:,4};
% signal_normalized = T_normalized{:,4};
% 
% % Plot both signals
% figure;
% plot(time, signal_cut, 'b-', 'DisplayName', 'Upsampled');
% hold on;
% plot(time, signal_normalized, 'r--', 'DisplayName', 'Normalized');
% hold off;
% %
% xlabel('Time (s)');
% ylabel('Signal Value');
% title('Comparison: 4th Column of T\_cut vs T\_normalized');
% legend('show');
% grid on;

% % Extract time and 4th column from both tables
% time_upsampeld = T_upsampled{:,1};
% val_upsampled = T_upsampled{:,4};
% 
% time_cut = T_cut{:,1};
% val_cut = T_cut{:,4};
% 
% % Plot
% figure;
% plot(time_upsampeld, val_upsampled,'--', 'DisplayName', 'Upsampled');
% hold on;
% plot(time_cut, val_cut, 'DisplayName', 'DIngo');
% xlabel('Time (s)');
% ylabel(T_cut.Properties.VariableNames{4});
% title('NA');
% legend;
% grid on;


close all;
clc;

% Column indices (adjust if different)
time_col = 1;
signal_col = 4;

% Create figure
figure('Name', 'Preprocessing Comparisons', 'NumberTitle', 'off');

%% --- 1. Filtered vs Raw ---
subplot(2,2,1);
plot(T{:, time_col}, T{:, signal_col}, 'b-', 'DisplayName', 'Raw');
hold on;
plot(T_filtered{:, time_col}, T_filtered{:, signal_col}, 'r-', 'DisplayName', 'Filtered');
title('Filtered vs Raw');
xlabel('Time (s)');
ylabel('Signal');
legend;
grid on;

%% --- 2. Filtered vs Upsampled (only first 0.5s) ---
subplot(2,2,2);
% Mask for first 0.5 seconds
mask_filtered = T_filtered{:, time_col} <= 0.5;
mask_upsampled = T_upsampled{:, time_col} <= 0.5;
plot(T_upsampled{mask_upsampled, time_col}, T_upsampled{mask_upsampled, signal_col}, 'b-o', 'DisplayName', 'Upsampled');
hold on;
plot(T_filtered{mask_filtered, time_col}, T_filtered{mask_filtered, signal_col}, 'r-', 'DisplayName', 'Filtered');
title('Filtered vs Upsampled (0–0.5s)');
xlabel('Time (s)');
ylabel('Signal');
legend;
grid on;

%% --- 3. Upsampled vs Cutting ---
subplot(2,2,3);
plot(T_upsampled{:, time_col}, T_upsampled{:, signal_col}, 'b-', 'DisplayName', 'Upsampled');
hold on;
plot(T_cut{:, time_col}, T_cut{:, signal_col}, 'r-', 'DisplayName', 'Cutting');
title('Upsampled vs Cutting');
xlabel('Time (s)');
ylabel('Signal');
legend;
grid on;

%% --- 4. Cutting vs Normalized ---
subplot(2,2,4);
plot(T_cut{:, time_col}, T_cut{:, signal_col}, 'b-', 'DisplayName', 'Cutting');
hold on;
plot(T_normalized{:, time_col}, T_normalized{:, signal_col}, 'r-', 'DisplayName', 'Normalized');
title('Cutting vs Normalized');
xlabel('Time (s)');
ylabel('Signal');
legend;
grid on;
