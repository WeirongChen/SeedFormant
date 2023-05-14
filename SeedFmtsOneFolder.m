function outTable = SeedFmtsOneFolder(dataPath, fmtRefs, skip_list, whichTier, gender, nPoints, win, step, subjName, smooth)
% Run Praat formant analysis for each label in TextGrid for all sound files in a folder
% using 'seeding method of formant analysis'  (Chen, Whalen & Shadle, 2019). 
%  
% Chen, W.-R., Whalen, D. H., & Shadle, C. H. (2019). 
% F0-induced formant measurement errors result in biased variabilities. 
% JASA, 145(5), EL360-EL366.
%
% Wei-Rong Chen  March-12-2020
sep = filesep;
thisScriptPathFileName = mfilename('fullpath');
codePath = fileparts(thisScriptPathFileName); 
if nargin < 10 || isempty(smooth), smooth = 0; end
if nargin < 9 || isempty(subjName), subjName = 'subj'; end
if nargin < 8 || isempty(step), step = 0.002; end
if nargin < 7 || isempty(win), win = 0.050; end
if nargin < 6 || isempty(nPoints), nPoints = 10; end
if nargin < 5 || isempty(gender), gender = 'M'; end
if nargin < 4 || isempty(whichTier), whichTier = 1; end
if nargin < 3 || isempty(skip_list), skip_list = txt2cell([codePath sep 'skip_list.txt']); end
if nargin < 2 || isempty(fmtRefs), fmtRefs = readtable([codePath sep 'formant_refs.csv']); end 
if nargin < 1 || isempty(dataPath); dataPath = pwd;end

wavfl = mygfl([dataPath sep '*.wav'], 0); tgfl = mygfl([dataPath sep '*.TextGrid'], 0);
nFiles = numel(wavfl);
outTable = [];
for i = 1:nFiles
    f = wavfl{i}; 
    if ~ismember(tgfl, f), continue;end
    wavFName = [dataPath sep f '.wav']; tgFName = [dataPath sep f '.TextGrid']; 
    fmtTable = SeedFmtsOneFile(wavFName, tgFName, whichTier, gender, fmtRefs, skip_list, nPoints, win, step, subjName, smooth); 
    outTable = [outTable; fmtTable];
end
outFName = [dataPath sep 'seedFmts.csv'];
if exist(outFName, 'file'), delete(outFName); end
writetable(outTable, outFName);
return


