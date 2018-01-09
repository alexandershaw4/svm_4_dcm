function m = svm_dcm_p(A, Pc, P, nperm, Scl)
% A wrapper around spm_dcm_f permitting n permutations.
% Returns the mean accuracy values
%
% Inputs:
%   A  = cell array of DCM file names, subject by group. Classifier is for
%        discriminating these groups
%   Pc = percent of the data to use for training (e.g. 80) 
%   P  = posterior parameter (from dcm) to extract and test
%   nperm = number of permutations
%
% Outputs:
%  m.A   = average accuracy (total correct classifications)
%   .TP  = true positives
%   .TN  = true neg
%   .FP  = false pos
%   .FN  = false neg
%   .PPV = positive predictive value
%   .NPV = negative predictive value
%
%   .Sensitivity
%   .Specificity
%
% note: is there any point in doing more than factorial(length(n)) perms?
% AS2016

h2  = waitbar(0, 'Running permutations through SVM');
%Scl = 1; % scaling [def]


o = svm_dcm_f2(A, Pc, P, 1,[],Scl); % first train/class

%plot_reduceddata(o.TrainDat,o.TrainTrue,o.ClassDat,o.ClassTrue)


for i = 1:nperm
    waitbar(i/nperm)

    o = svm_dcm_f2(A, Pc, P, 1,[],Scl); % train & classify
    %o = svm_dcm_f2(A, Pc, P, 1,[],Scl,o.svm);% just classify w/ existing
    %o = svm_dcm_f(A,Pc,P,1);
    
    a(i) = o.Ac;  % overall correctness [TP + TN]
    T(i) = o.T;   % predictive powers & t/f p/n
    s(i) = o.svm; % the svms themselves [w/ sup vecs]
    
end
try close(h2); end
    clc;
    

m.A   = mean(a);
m.a   = a;

m.PPV = mean(spm_vec({T.PPV}));
m.NPV = mean(spm_vec({T.NPV}));

m.Sensitivity = mean(spm_vec({T.Sensitivity}));
m.Specificity = mean(spm_vec({T.Specificity}));

m.TP = mean(spm_vec({T.TP}));
m.TN = mean(spm_vec({T.TN}));
m.FP = mean(spm_vec({T.FP}));
m.FN = mean(spm_vec({T.FN}));

% re-normalise averaged measures to == 100%
ss = m.TP + m.TN + m.FP + m.FN;

m.TP = m.TP/ss*100;
m.TN = m.TN/ss*100;
m.FP = m.FP/ss*100;
m.FN = m.FN/ss*100;


m.svm  = o.svm;
m.svms = s;
m.T    = T;

plot_reduceddata(o.TrainDat,o.TrainTrue,o.ClassDat,o.ClassTrue)
title('2D Euclidean representation of n-D svm','fontsize',18);
