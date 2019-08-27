function o = loadarraydcm(in)
% Same as loadarray.m but for dcm models.
% Loads a cell array of file names into array of structures.
% AS2016 [util]

try in = {in.name}; end     % in case of input from 'dir'
if ~iscell(in); return; end % nope

if isstruct(in{1,1});
    fprintf('Already loaded\n');
    o = in;
    return;
end

for i = 1:size(in,1)
    for j = 1:size(in,2)
        t = load(in{i,j});
        o{i,j} = t.DCM;
    end
end