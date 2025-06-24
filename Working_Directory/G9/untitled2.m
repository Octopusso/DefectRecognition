clc;
clear;

% === 1. 读取数据 ===
filename = 'G9_P1_case91.xls';  % 改成你当前处理的文件名
T = readtable(filename);
data = table2array(T);

% === 2. 时间轴 & 原始加速度 ===
time = data(:, 1) - data(1,1);   % 统一起点为 0
acc_x = data(:, 2);
acc_y = data(:, 3);
acc_z = data(:, 4);

% === 3. 原始加速度可视化 ===
figure;
subplot(3,1,1); plot(time, acc_x); title('a_x'); xlabel('Time (s)');
subplot(3,1,2); plot(time, acc_y); title('a_y'); xlabel('Time (s)');
subplot(3,1,3); plot(time, acc_z); title('a_z'); xlabel('Time (s)');

% === 4. 绝对加速度计算 ===
abs_acc = sqrt(acc_x.^2 + acc_y.^2 + acc_z.^2);

figure;
plot(time, abs_acc);
title('Absolute Acceleration (Raw)');
xlabel('Time (s)');
ylabel('|a|');

% === 5. Butterworth 低通滤波 ===
Fs = round(1/mean(diff(time)));  % 估算采样频率
fc = 20;                         % 截止频率
order = 4;
[b, a] = butter(order, fc/(Fs/2), 'low');

acc_x_filt = filtfilt(b, a, acc_x);
acc_y_filt = filtfilt(b, a, acc_y);
acc_z_filt = filtfilt(b, a, acc_z);

abs_acc_filt = sqrt(acc_x_filt.^2 + acc_y_filt.^2 + acc_z_filt.^2);

% === 6. 滤波效果可视化 ===
figure;
plot(time, abs_acc, 'b', 'DisplayName', 'Raw'); hold on;
plot(time, abs_acc_filt, 'r', 'DisplayName', 'Filtered');
title('Absolute Acceleration (Raw vs. Filtered)');
xlabel('Time (s)');
ylabel('|a|');
legend;

% === 7. FFT 分析（滤波后） ===
L = length(abs_acc_filt);
Y = fft(abs_acc_filt);
f = Fs*(0:(L/2))/L;
P = abs(Y/L);
P1 = P(1:L/2+1);

figure;
plot(f, P1);
title('FFT of Filtered Absolute Acceleration');
xlabel('Frequency (Hz)');
ylabel('|P(f)|');

% === 8. 标准化处理（Z-score） ===
acc_x_z = (acc_x_filt - mean(acc_x_filt)) / std(acc_x_filt);
acc_y_z = (acc_y_filt - mean(acc_y_filt)) / std(acc_y_filt);
acc_z_z = (acc_z_filt - mean(acc_z_filt)) / std(acc_z_filt);
abs_acc_z = (abs_acc_filt - mean(abs_acc_filt)) / std(abs_acc_filt);

% === 9. 保存数据 ===
preprocessed_data = table(time, acc_x_z, acc_y_z, acc_z_z, abs_acc_z, ...
    'VariableNames', {'time', 'acc_x', 'acc_y', 'acc_z', 'abs_acc'});
save('G9_P1_case91_preprocessed.mat', 'preprocessed_data');
writetable(preprocessed_data, 'G9_P1_case91_preprocessed.csv');
