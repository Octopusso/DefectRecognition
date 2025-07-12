clc;
close all;

disp('Running Script 1...');
run("DataImporting.m");

disp('Running Script 2...');
run("SamplingRate_Sync.m");

disp('Running Script 3...');
run("Filtering.m");

disp('Running Script 4...');
run("Upsampling.m");

disp('Running Script 5...');
run("DataCutting.m");

disp('Running Script 6...');
run("Normallization.m");

disp('Running Script 7...');
run("General_Feature_Extraction.m");

disp('Running Script 8...');
run("GeneralMerge.m");

disp('All scripts executed successfully.');
