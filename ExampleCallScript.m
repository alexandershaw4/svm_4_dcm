
% List the DCM filenames in 
PLA = dir('wDelay_Euler_*PLA*.mat'); PLA={PLA.name}'; % group/condition 1
PRO = dir('wDelay_Euler_*PRO*.mat'); PRO={PRO.name}'; % group/condition 2

% sort into a new array so that files(:,1) = group 1 file names, 
% files(:,2) = group 2 file names. This is what we will use the paramer(s) 
% to predict ...

files(:,1) = PRO;
files(:,2) = PLA;

mysvm           = svm_4_dcm; % create an instance 
mysvm.A         = files;     % add cell array of DCM filenames
mysvm.Pc        = 80;        % percent of data to use for training
mysvm.P         = 'H';       % parameter field to extract 'H' or {'H' 'T'} etc
mysvm.DoPermute = 1;         % do permutations
mysvm.nperm     = 5000;
mysvm.f         = @fitNaiveBayes; % machine: @fitNaiveBayes or @svmtrain
mysvm.Scl       = 1;         % scale the vectors
mysvm.NumCrossVals = 10;     

[PatientCategorySVM,Preds] = NewSVM(mysvm);