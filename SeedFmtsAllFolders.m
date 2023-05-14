function SeedFmtsAllFolders(myPath)
%  This wrapper script will loop through all folders to run 
%   Seeding method of formant analysis  (Chen, Whalen & Shadle, 2019). 
%  
% Chen, W.-R., Whalen, D. H., & Shadle, C. H. (2019). 
% F0-induced formant measurement errors result in biased variabilities. 
% JASA, 145(5), EL360-EL366.
%
% Wei-Rong Chen   March-12-2020
if nargin < 1 || isempty(myPath), myPath = pwd; end % set path to the current folder
subjlist = readtable([myPath filesep 'subjlist.csv']); % read subject list
whichTier = 1; % which tier in TextGrid contains vowel labels
nPoints = 10;   % # points of samples per vowel label
win = 0.050;    % window size in seconds
step = 0.002;   % step size in seconds
% Smoothing: 
%  Set 'smooth' to non-zero number to apply "Robust Smoothing" [Garcia, 2010; Comput Stat Data Ana. (54)]
%  Set 'smooth' to 0 to avoid smoothing. 
smooth=0; % 
warning('off', 'MATLAB:smoothn:SLowerBound');
%%

nSubjs = size(subjlist,1); % Get the number of subjects
outTable = [];
for i = 1:nSubjs % loop through all subjects
    subj = subjlist.Subject{i}; gender = subjlist.Gender{i};
    subjPath = [myPath filesep subj];
    subjTable = SeedFmtsOneFolder(subjPath, [], [], whichTier, gender, nPoints, win, step, subj, smooth);
    outTable = [outTable; subjTable];
end
writetable(outTable, [myPath filesep 'praatFmts.csv']); 
warning('on', 'MATLAB:smoothn:SLowerBound');
return