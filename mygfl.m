function [filelist, folder] = mygfl(mask, keepExt)
if nargin<2, keepExt = 1; end
FLs = dir(mask); filelist = {FLs.name}';
folder = {FLs.folder}';
if ~keepExt
    for i = 1:numel(filelist)
        [p, f, e]=fileparts(filelist{i});
        filelist{i} = f; 
    end
end