function out = getdcmp(in,target,varargin)
% Get parameter values from a bunch of DCMs in an array.
% Second input is the field to retrieve, e.g. "B" to get posterior beta
% matrix (i.e. the letter corresponds to fieldnames of DCM.Ep).
%
% *Update: optionally add third input = 1 to return exp(n) values
% AS2016 [util]

if iscell(in) && ~isstruct(in{1,1});
     try    in = loadarraydcm(in);
     catch; out = []; return; 
     end
end

out = cell(size(in));


% find 'all' parameters in list
if iscell(target)
    p = cell(1,2);
    for i  = 1:length(target)
        ip = getdcmp(in,target{i},varargin);
        %p  = [p, (ip)];
        p{:,1} = [ p{:,1} , VecRetainDim(ip(:,1),1 ) ];
        p{:,2} = [ p{:,2} , VecRetainDim(ip(:,2),1 ) ];
    end
    out = p;
    return
end
    
for i = 1:size(in,1)
    for j = 1:size(in,2)
        out{i,j} = spm_vec( in{i,j}.Ep.(target));
    end
end
    
   