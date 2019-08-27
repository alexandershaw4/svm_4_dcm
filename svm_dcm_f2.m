function o = svm_dcm_f2(A, Pc, P, DoPermute,varargin)
% Set up an SVM for DCM posteriors.
%
% Inputs:
%   A  = cell array of DCM file names, subject by group
%   Pc = percent of the data to use for training (e.g. 80) 
%   P  = posterior parameter (from dcm) to extract and test {DCM.Ep.(*)}
%   DoPermute = Permute data first
%
%   optional final arg: @fitNaiveBayes or @svmtrain
%
%   Example usage: o = svm_dcm_f([Cons;FTD],80,'B',0) 
%
% Dependencies: loadarraydcm, getdcmp/j/x, shrink, spm_vec, predictive
% AS2016


% Data set up
%--------------------------------------------------------------------------
a  = loadarraydcm(A);                 % get models
B  = getdcmp(a,P);                    % get posterior B matrices

for i = 1:2
    c(:,:,i) = squeeze(cat(4,B{:,i}))';
end

b  = c;
Q  = @squeeze;
Pc = round(size(b,1)*(Pc/100));       % percent of data to train with


%Decide whether to set up an svm or reuse existing
%--------------------------------------------------------------------------
verbose = 0;
try verbose = varargin{3}; end
try
    if isstruct(varargin{3})
         SVMS = varargin{3}; % initialise existing svm?
         Build = 0;
         if verbose
             fprintf('existing svm, not re-training\n');
         end
    else Build = 1;
         if verbose
             fprintf('building and training new svm\n');
         end
    end
catch Build = 1;
    if verbose
        fprintf('building and training new svm\n');
    end
    
end
    

% Scale input vectors [0 1] if requested
%--------------------------------------------------------------------------
M = b;

% scale vectors?
try if varargin{2} == 1;
        for i = 1:size(M,1)
            for j = 1:size(M,3)
                x = M(i,:,j);
                x = x - min(x) / (max(x) - min(x));
                M(i,:,j) = x;
            end
        end
    end;
end
    


% make test dataset
%--------------------------------------------------------------------------
for i = 1:Pc
    G1(i,:) = spm_vec(M(i,:,1)); % group 1
    G2(i,:) = spm_vec(M(i,:,2)); % group 2
end

% input vector & test data
Tr = [G1;G2];                        % training set
Tr = shrink(Tr);                     % remove emptys
Y  = [G1(:,1)*0;G2(:,1)*0+1];        % grouping vector [0,1]


% make classify data
%--------------------------------------------------------------------------
Clas  = Pc+1:size(b,1);  
for i = 1:length(Clas)
    C1(i,:) = spm_vec(M(Clas(i),:,1));
    C2(i,:) = spm_vec(M(Clas(i),:,2));
end


% input test matrix for classification (& truth vector)
%--------------------------------------------------------------------------
TEST  = [C1;C2];
TEST  = shrink(TEST);
ACT   = [C1(:,1)*0;C2(:,1)*0+1];
%TEST  = TSNorm(TEST,6,1,1); %normalise


if DoPermute
    
    x1    = Tr;
    y1    = Y;
    
    x2    = TEST;
    y2    = ACT;
    
    
    i1     = randperm(length(y1)); % permutation vector
    i2     = randperm(length(y2));
    
    x1     = x1(i1,:);              % p(x)
    y1     = y1(i1,:);              % p(y)

    x2     = x2(i2,:);
    y2     = y2(i2,:);
    
    Tr    = x1;           % new training
    Y     = y1;           % new truths

    TEST  = x2;
    ACT   = y2;
end

warning off


% remove empties
Tr = shrink(Tr,2);
TEST = shrink(TEST,2);

% train if new
%--------------------------------------------------------------------------
if Build;
    
    try varargin{1};
        f = varargin{1};
    catch
        f = @svmtrain;
    end
    if isempty(f); f = @svmtrain; end
    
    %SVMS  = svmtrain(Tr, Y,'kernel_function','linear','method','LS'); % train
    %SVMS = fitNaiveBayes(Tr,Y);
    SVMS = f(Tr,Y);
 
end



% test....
%--------------------------------------------------------------------------
try   GROUP = SVMS.predict(TEST);
catch GROUP = svmclassify(SVMS, TEST);
end

warning on

%GROUP = svmclassify(SVMS, TEST);                                  % classify
%GROUP = SVMS.predict(TEST);
Ac    = [ACT,GROUP];

if DoPermute
    st1   = find(Ac(:,1));
    st0   = 1:length(Ac(:,1));
    st0   = Ac(~ismember(st0,st1)',:);
    st1   = Ac(st1,:);
    Ac    = [st0;st1]; % the actual classification, ordered
end

Acur = sum(ACT==GROUP)/length(ACT)*100;
T    = predictive(Ac);

o.Ac  = Acur;
o.T   = T;
o.svm = SVMS;

o.TrainDat = Tr;
o.ClassDat = TEST;
o.TrainTrue = Y;
o.ClassTrue = GROUP;

% pca
%Pred_coeff = pca(SVMS.SupportVectors);

%SV = SVMS.SupportVectors;
%f  = feval(SVMS.KernelFunction,SV,TEST);
%a = SVMS.Alpha;
%p = f'*a + SVMS.Bias;
% %db = sign(p);

%d  = pdist(p);
%l  = linkage(d);
%b = {'Con','Pat'};
%lb = lb(ACT+1);

%figure,
%[H,T]=dendrogram(l,2,'labels',lb);
%plot(Ac(:,1)==Ac(:,2),'o'); ylim([-.1 1.1])
%set(gca, 'YTick',1:2, 'YTickLabel',{'Correct';'Incorrect'});
%set(gca,'fontsize',18);

