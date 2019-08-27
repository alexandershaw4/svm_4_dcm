function [PerfGeneralise,PatientCategorySVM,Preds,SVMModel,Parameters] = new_svm4dcm(A,A2, P, NumPerms, NumCrossVals,varargin)
% Apply a linear SVM to some DCMs.
%
% Input A is a cell array of DCM filenames, of shape A{subjects x group}
%       P is the parameters to use, e.g. 'H' or {'H','T'};
%       NumPerms is the number of permutations (def: 10000)
%       NumCrossVals is the number of cross validations (def: 100)
%
% A wrapper on Krish SVM code
%
% AS

if nargin < 3 
    NumPerms     = 10000;
end
if nargin < 4 
    NumCrossVals = 100;
end

a  = loadarraydcm(A);                 % get models
a2 = loadarraydcm(A2);

a = [a; a2]; % conncatenate


B  = getdcmp(a,P);                    % get posterior matrices

PatientCode = [zeros(size(A,1),1); ones(size(A2,1),1)];

% unpack the parameters returned into a 3D array
for i = 1:2
    these = find(PatientCode==(i-1));
    c{i} = squeeze(cat(4,B{these}))';
    %c(:,:,i) = squeeze(cat(4,B{these}));
    %c(:,:,i) = squeeze(cat(4,B{:,i}))';
    
end

% if size(c,1) ~= (floor(length(PatientCode)/2))
%     c = permute(c,[2 1 3]);
% end


% if ismember(P,{'A','AN'})
%     fprintf('expoonentiating');
%     c(c==-32) = -inf;
%     c = exp(c);
%     c(c==1) = 0;
% end

% normalise parameters across subjects to have SD=1
for i = 1:2
    for j=1:size(c,2)
        c{i}(:,j) = c{i}(:,j)/std(c{i}(:,j));
        %c(:,j,i)=c(:,j,i)/std(c(:,j,i));
        c{i}(isnan(c{i})) = 0;
    end
end



% remove any NaNs we introduced
%c(isnan(c)) = 0;

% reshape this 3D matrix from (sub x param x group) to (allsubs x param)
%Parameters = [c(:,:,1); c(:,:,2)];
Parameters = [c{1}; c{2}];
%Parameters = shrink(Parameters,2);
size(Parameters)

% Classify using repeated Parameters
DCMParametersToClassify = Parameters;
    
Nsub         = length(PatientCode);


for j=1:NumPerms
   if(mod(j,100)==0)
       fprintf('Done randomisation iteration %d of %d\n',j,NumPerms);
   end

    RandPatientCode=PatientCode(randperm(length(PatientCode)));

    SVMModel = fitcsvm(DCMParametersToClassify,RandPatientCode,'KernelFunction','Linear','Standardize',true);

    PatientCategorySVM = predict(SVMModel,DCMParametersToClassify);
    Csvm=confusionmat(RandPatientCode,PatientCategorySVM);
    BadSVM(j)=Csvm(1,2)+Csvm(2,1);
    Perf(j)=100*(1-(BadSVM(j)/Nsub));
end


SVMModel = fitcsvm(DCMParametersToClassify,PatientCode,'KernelFunction','Linear','Standardize',true);
TheFold  = 1;
for j=1:NumCrossVals
    if(mod(j,10)==0)
        fprintf('Doing k-fold crossval iteration %d of %d\n',j,NumCrossVals);
    end
    CVSVMModel = crossval(SVMModel);
    NumFolds=length(CVSVMModel.Trained);
    for k=1:NumFolds
        PerfGeneralise(TheFold)=100*(1-kfoldLoss(CVSVMModel,'folds',k));
        TheFold=TheFold+1;
    end
end

PatientCategorySVM = predict(SVMModel,DCMParametersToClassify);
Csvm=confusionmat(PatientCode,PatientCategorySVM);
TrueBadSVM=Csvm(1,2)+Csvm(2,1);
TruePerf=100*(1-(TrueBadSVM/Nsub));
NullDist=sort(Perf);
Pvalue=length(find(NullDist>=TruePerf))/NumPerms;

G1 = find(PatientCode==0);
G2 = find(PatientCode==1);
NParam =  size(Parameters,2);

figure
subplot(1,3,1);
plot(G1,PatientCategorySVM(find(PatientCode==0)),'bo',G2,PatientCategorySVM(find(PatientCode==1)),'ro');title(sprintf('SVM class,bad=%d, perf= %4.1f per, RandP=%g',TrueBadSVM,TruePerf,Pvalue));
ylim([-0.2 1.2]);
subplot(1,3,2);
[N,x]=hist(PerfGeneralise,unique(PerfGeneralise));
bar(x,100*(N/sum(N)),'hist');
xlim([-5 105]);
title(sprintf('CrossVal(10-fold) MeanPerc= %4.1f ModePerc=%4.1f MedianPerc=%4.1f',mean(PerfGeneralise),mode(PerfGeneralise),median(PerfGeneralise)));
xlabel('CrossVal Performance');
ylabel('PercentageOfTests');

%
clear XC;
clear CumPerf;
for j=1:1:NParam
    XC(j)=10*(j-1);
    CumPerf(j)=100*length( (find(PerfGeneralise>XC(j)))) / length(PerfGeneralise);
end
subplot(1,3,3);
plot(XC,CumPerf,XC,CumPerf,'ro');
title('Cumulative CrossVal Performance');
xlabel('CrossVal Performance');
ylabel('PercentageOfTests Exceeding This Value');
ylim([0 100]);
xlim([0 100]);
grid on;

Preds = predictive([PatientCode PatientCategorySVM]);