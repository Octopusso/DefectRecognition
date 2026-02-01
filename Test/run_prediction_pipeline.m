% ==================================================
% === 预测流水线主控脚本 (Prediction Master Script) ===
% ==================================================
% 该脚本用于对一个全新的、未见过的数据集执行完整的预测流程。
% 
% 使用方法:
% 1. 在 "用户配置区" 修改 newDataInputPath 和 predictionOutputPath。
% 2. 运行此脚本。
% ==================================================

clear; clc; close all;

% --- 1. 用户配置区 ---
% 在这里指定您老师给的新数据所在的路径
% 重要提示: 新数据的文件夹结构应与原始的 'Measurement Data' 文件夹结构相同。
newDataInputPath = 'C:\Users\MSI-\Documents\MATLAB\DefectRecognition\Test\test data'; % <--- 修改这里

% 在这里指定一个全新的、空的文件夹，用于存放本次预测过程的所有中间和最终结果
predictionOutputPath = 'C:\Users\MSI-\Documents\MATLAB\DefectRecognition\Test\Prediction_Results_NewData'; % <--- 修改这里

% --- 2. 训练好的模型和处理函数所在的路径 ---
% 假设此脚本、所有 process_*.m 函数和训练好的模型都在同一个 'Test' 目录下
[codePath, ~] = fileparts(which('run_prediction_pipeline.m'));
addpath(codePath); % 将当前目录添加到MATLAB路径

% --- 3. 创建输出文件夹结构 ---
if ~exist(predictionOutputPath, 'dir')
    mkdir(predictionOutputPath);
end
matlabImportPath = fullfile(predictionOutputPath, 'Matlab_Import');
trainingDataPath = fullfile(matlabImportPath, 'Training');

% --- 4. 按顺序执行流水线 ---
try
    disp('>> 步骤 A: 导入数据...');
    process_A_DataImporting(newDataInputPath, matlabImportPath);

    disp('>> 步骤 C: 滤波...');
    process_C_Filtering(matlabImportPath);
    
    disp('>> 步骤 D: 上采样...');
    process_D_Upsampling(matlabImportPath);
    
    disp('>> 步骤 E: 数据截取...');
    process_E_DataCutting(matlabImportPath);
    
    disp('>> 步骤 F: 归一化...');
    process_F_Normallization(matlabImportPath);
    
    disp('>> 步骤 G: 特征提取...');
    % The original label file is used as a template, but for new data, labels will not be found.
    % The function is designed to handle this gracefully and proceed without labeling.
    process_G_FeatureExtraction(matlabImportPath, fullfile(codePath, 'GeneralLable.xlsx')); 
    
    disp('>> 步骤 H: 特征合并...');
    process_H_GeneralMerge(matlabImportPath, trainingDataPath);
    
    disp('>> 步骤 I: 特征分离...');
    % This step is necessary to create the specialized CSVs for the prediction models.
    process_I_GeneralSeparation(trainingDataPath);
    
    disp('>> 步骤 J: 执行最终预测...');
    % The function uses the trained models from the codePath, reads the features
    % from trainingDataPath (which now contains the new data), and saves the
    % final result to the main predictionOutputPath.
    process_J_TestModel(codePath, trainingDataPath, predictionOutputPath);
    
    fprintf('\n>> 流水线完整执行完毕！\n');
    fprintf('>> 最终预测结果已保存在: %s\n', fullfile(predictionOutputPath, 'Final_Predictions.xlsx'));

catch ME
    fprintf('\n>> 流水线执行出错:\n');
    rethrow(ME);
end
