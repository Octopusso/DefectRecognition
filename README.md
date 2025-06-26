## Project Overview

This project uses linear acceleration signals to monitor the structural health of a production system. We divide the workflow into four main stages: preprocessing, feature extraction, feature selection, and modeling & evaluation.

You can change the position such as from P1 to P2 to see diffrent result. It only takes two files into account: "Px_case_perfect" and "Px_case92". So this is just an example of the whole plan of action totaly done by ChatGPT.
Since it mentions in the last page of the file "Project_introduction" that it is just "Sample plan of action", so this code is correct though there are some steps missing such as Hyperparameter tuning.

---

### 1. Preprocessing

- **Read data**  
  Load `G0_P5_case_perfect.xls` and `G9_P5_case92.xls` (preserve original column names), extract time vector and Z-axis acceleration.

- **Detrend signals**  
  Remove linear trend from each signal using `detrend`.

- **Bandpass filter design & zero-phase filtering**  
  1. Compute sampling rate and Nyquist frequency.  
  2. Design a 4th-order Butterworth bandpass (1–100 Hz) with auto-Nyquist correction.  
  3. Pad 0.2 s of mirrored data at each end and apply `filtfilt` to eliminate edge ringing.

- **Normalize to [0,1]**  
  Linearly scale each filtered signal.

- **Save & quick visualization**  
  Save `timeP, normP` and `timeC, normC` to MAT files, plot normalized waveforms for sanity check.

---

### 2. Feature Extraction

- **Sliding-window segmentation**  
  Use 1 s non-overlapping windows to segment each signal.

- **Time-domain features (per window)**  
  - RMS  
  - Skewness  
  - Kurtosis  
  - Crest factor (peak/ RMS)

- **Frequency-domain features**  
  - Bandpower in 30–40 Hz  
  - Wavelet packet energy (3-level DB4) in low, mid1, mid2, high bands

---

### 3. Feature Normalization & Selection

- **Z-score normalization**  
  Standardize each of the 9 extracted features.

- **Filter method**  
  Rank features by absolute correlation with labels.

- **Wrapper method**  
  5-fold sequential forward selection using SVM misclassification rate.

- **Embedded method**  
  L1-regularized logistic regression (Lasso) to select nonzero coefficients.

---

### 4. Modeling & Evaluation

- **Single-threshold classifier**  
  Classify defect if `E_low` Z-score ≤ 0; compute TP/FP/TN/FN, Accuracy, Recall, Precision.

- **Train/test split**  
  80% training / 20% testing.

- **Logistic regression (Lasso)**  
  Train, predict probabilities, threshold at 0.5, compute confusion matrix, Accuracy, Recall, Precision, F1, AUC; plot ROC.

- **Linear SVM**  
  5-fold cross-validation error, test-set performance, plot decision boundary (if ≥2 features).

- **Visualization & reporting**  
  Generate RMS, PSD, boxplots, ROC curve, and decision-boundary plots; save metrics summary.

