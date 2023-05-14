function [TextGridStruct,tierNames,TierStartLineNum, IsPointTier]= ReadTextGrid(tgFName)
% This function reads TextGrid file and returns a struct of TextGrid.
% Output : 
%   'TextGridStruct' : TextGrid structure with the following format: 
%       TextGrid(i).NAME : tier name
%       TextGrid(i).segs :
%            n Intervals x 2 ([StartTime EndTime]) matrix, if  this tier is interval tier; 
%            n Intervals x 1 ([Time]) array, if  this tier is point tier; 
%       TextGrid(i).labs=labs : n Intervals x 1 cell array
%       TextGrid(i).IsPointTier= 0 : if this tier is interval tier; 
%                                         1 : if this tier is point tier; 
% 
% Weirong Chen  Apr-19-2016
% Update:  Aug-1-2018:  Fix the issue of double quotation marks. 
%                      double quotation " is stored as duplication: ""
%                      in Praat TextGrid internally. 
%
[~,~,e]=fileparts(tgFName); 
if ~exist(tgFName, 'file'), error('File NOT exist!');end
if isempty(e), tgFName=[tgFName '.TextGrid'];end
[lines, isShort, startTime, totalDur, nTiers] = ReadValidateDataProc(tgFName); %#ok<ASGLU>
[tierNames,TierStartLineNum, IsPointTier] = GetTierNamesAndTypes(lines);

for i=1:numel(tierNames)
    tierName=tierNames{i};
    isPoint = IsPointTier(i); tierStart = TierStartLineNum(i);
    [segs, labs]=ParseOneTier(lines, isShort, isPoint, tierStart);
    TextGridStruct(i).NAME=tierName;
    TextGridStruct(i).segs=segs; %#ok<*AGROW>
    TextGridStruct(i).labs=labs;
    TextGridStruct(i).IsPointTier=isPoint;
end
% end %ReadTextGrid()


%% 
function [segs, labs]=ParseOneTier(lines, isShort, isPoint, tierStart)
nSegs = str2double(lines{tierStart+3}(regexp(lines{tierStart+3},'\d'):end));
M = 4 - isShort - isPoint;
StartLineNum = tierStart + 4;  EndLineNum = nSegs*M + StartLineNum - 1;
nIntervals = (EndLineNum - StartLineNum + 1) / M;
items = reshape(lines(StartLineNum:EndLineNum),M,nIntervals)';
labs = items(:,M);
kk = cellfun(@strfind, labs,repmat({'"'}, length(labs),1), 'UniformOutput',false);
idx1 = num2cell(cellfun(@(x) x(1), kk)+1); idx2 = num2cell(cellfun(@(x) x(end), kk)-1);
labs = cellfun(@(x, a,b) x(a:b), labs, idx1, idx2, 'UniformOutput',false);
for i = 1:numel(labs)
    lab = labs{i};
    labs{i} = strrep(lab, '""', '"');
end
lines1 = items(:,2-isShort:(M-1));
segs = cellfun(@str2double,regexprep(lines1, '[^0-9.]', ''));
% end %ParseOneTier
%%
function [lines, isShort, startTime, totalDur, nTiers] = ReadValidateDataProc(fName)
    encoding = DetectTextGridEncoding(fName);
    try
        lines = textscanu1(fName, encoding);
    catch
        error('error attempting to load from %s', fName);
    end
    lines=DetectStrainedQuotationSybol2(lines);
    % format checking
    if length(lines)<15 || isempty(strfind(lines{1},'ooTextFile')) || isempty(strfind(lines{2},'"TextGrid"')) || isempty(strfind(lines{6},'exists'))    
        error('%s : unrecognized file format', fName);
    end
    [isShort, startTime, totalDur, nTiers]=DetectTextGridCellsLongOrShort(lines);
% end %ReadValidateDataProc
%%
function [tierNames,TierStartLineNum, IsPointTier] = GetTierNamesAndTypes(lines)
% get tier names and types
    pointTierNames = {};pointTiers=[];
    intTierNames = {};intTiers =[];
    
	k = find(~cellfun(@isempty,regexp(lines,'TextTier')));
	if ~isempty(k)
		pointTiers = k + 1;
        TierNameLines = lines(pointTiers);
        kk = cellfun(@strfind,TierNameLines,repmat({'"'}, length(TierNameLines),1), 'UniformOutput',false);
        idx1 = cellfun(@(x) x(1), kk); idx2 = cellfun(@(x) x(end), kk);
        pointTierNames = cellfun(@(x, a,b) x(a:b), TierNameLines,  num2cell(idx1+1), num2cell(idx2-1), 'UniformOutput',false);
    end
    
	k = find(~cellfun(@isempty,regexp(lines,'IntervalTier')));
	if ~isempty(k)
		intTiers = k + 1;
        TierNameLines = lines(intTiers);
        kk = cellfun(@strfind,TierNameLines,repmat({'"'}, length(TierNameLines),1), 'UniformOutput',false);
        idx1 = cellfun(@(x) x(1), kk); idx2 = cellfun(@(x) x(end), kk);
        intTierNames = cellfun(@(x, a,b) x(a:b), TierNameLines,  num2cell(idx1+1), num2cell(idx2-1), 'UniformOutput',false);
    end
    tierNames = [pointTierNames;intTierNames]; 
    TierStartLineNum = [pointTiers;intTiers]; 
    IsPointTier = [true(size(pointTiers)); false(size(intTiers))]; 
    [~, TierOrder]=sort(TierStartLineNum);
    tierNames = tierNames(TierOrder); 
    TierStartLineNum = TierStartLineNum(TierOrder);
    IsPointTier = IsPointTier(TierOrder);
% end %GetTierNamesAndTypes
%%
function [isShort, startTime, totalDur, nTiers]=DetectTextGridCellsLongOrShort(TGlineCells)
try
    metaData = TGlineCells([4 5 7]);
    idx1 = ~isempty(strfind(lower(metaData{1}),'xmin'));
    idx2 = ~isempty(strfind(lower(metaData{2}),'xmax'));
    idx3 = ~isempty(strfind(lower(metaData{3}),'size'));
    if idx1 && idx2 && idx3
        isShort = 0;
        data =str2double(regexprep(metaData,'(XMIN|XMAX|SIZE|xmin|xmax|size|=| )',''));
    elseif ~idx1 && ~idx2 && ~idx3
        isShort = 1;
        data = str2num(char(metaData)); %#ok<ST2NM>
%         data = cellfun(@str2double, metaData);
    else 
        error('%s has unrecognized file format', fName);
    end
catch
	error('%s has unrecognized file format', fName);
end
startTime = data(1); totalDur = data(2); nTiers = data(3);
% end % end of DetectTextGridCellsLongOrShort

%%
function outTextGridLines=DetectStrainedQuotationSybol(TextGridLines) %#ok<DEFNU>
%Weirong Chen  Sep-08-2015
outTextGridLines = TextGridLines;
AnomalyLines=[FindWhich(TextGridLines,'" ') FindWhich(TextGridLines,'"')];
ToDelete=[];
if numel(AnomalyLines)>1
    for i = 1:numel(AnomalyLines)-1
        if AnomalyLines(i) == AnomalyLines(i+1)-1, ToDelete=[ToDelete i];end
    end
end
AnomalyLines(ToDelete) = [];
delLineNum=[];
for i = 1:numel(AnomalyLines)
    AnomalyLineNum=AnomalyLines(i);
    if AnomalyLineNum < 2, continue;end
    preLineNum = []; 
    for j = AnomalyLineNum-1:-1:1
        oneLine = strrep(TextGridLines{j},' ','');
        if ~isempty(oneLine)
            preLineNum=j;
            outTextGridLines{j} = [outTextGridLines{j} '"'];
            break;
        end
    end
    if ~isempty(preLineNum)
        delLineNum=[delLineNum preLineNum+1:AnomalyLineNum];
    end
end
outTextGridLines(delLineNum)=[];
% end %DetectStrainedQuotationSybol
function outTextGridLines=DetectStrainedQuotationSybol2(TextGridLines)
%Weirong Chen  Oct-02-2015
outTextGridLines = TextGridLines;
ToDelete=[];
for i = 1:length(TextGridLines)-1
    thisLine = TextGridLines{i};
    nextLine = TextGridLines{i+1};
    thisLine = strrep(thisLine,' ','');
    nextLine = strrep(nextLine,' ','');
    if strcmp(thisLine,'text="') && strcmp(nextLine(end),'"')
        ToDelete = [ToDelete i+1]; 
        outTextGridLines{i} = [TextGridLines{i} TextGridLines{i+1}];
    end
end
outTextGridLines(ToDelete) = [];

% end %DetectStrainedQuotationSybol2
%%
function encoding = DetectTextGridEncoding(TextGridFName)
% Detect the text encoding method of a PRAAT .TextGrid file.
% Usage: encoding = DetectTextGridEncoding(TextGridFName)
% 
% Weirong Chen    JAN-13-2014

[~,~,e]=fileparts(TextGridFName);
if isempty(e), TextGridFName=[TextGridFName '.TextGrid'];end
encodings{1}='UTF-8';
encodings{2}='UTF-16BE';
encodings{3}='UTF-16LE';
encodingWeight=NaN*zeros(1,length(encodings));
wid='MATLAB:iofun:UnsupportedEncoding';
warning('off',wid);
for i=1:length(encodings)
    fid = fopen(TextGridFName, 'r', 'l', encodings{i});
    S = fscanf(fid, '%c');
    fclose(fid);
    out = strfind(S, 'Text');
    encodingWeight(i)=length(out);
end

[~,idx]=max(encodingWeight);
encoding=encodings{idx};
warning('on',wid);
% end %DetectTextGridEncoding
%%
function C = textscanu1(filename, encoding)

% C = textscanu1(filename, encoding) reads Unicode 
% strings from a file and outputs a cell array of strings. 
% 
% Syntax:
% -------
% filename - string with the file's name and extension
%                 example: 'unicode.txt'
% encoding - encoding of the file
%                 default: UTF-16LE
%                 examples: UTF16-LE (little Endian), UTF8.
%                 See http://www.iana.org/assignments/character-sets
%                 MS Notepad saves in UTF-16LE ('Unicode'), 
%                 UTF-16BE ('Unicode big endian'), UTF-8 and ANSI.

% 
% Example:
% -------
% C = textscanu_wr('unicode.txt', 'UTF8');
% Reads the UTF8 encoded file 'unicode.txt', which has
% columns and lines delimited by tabulators, respectively 
% carriage returns. Shows a waitbar to make the progress 
% of the functions action visible.
%
% Note:
% -------
% Matlab's textscan function doesn't seem to handle 
% properly multiscript Unicode files. Characters 
% outside the ASCII range are given the \u001a or 
% ASCII 26 value, which usually renders on the 
% screen as a box.
% 
% Additional information at "Loren on the Art of Matlab":
% http://blogs.mathworks.com/loren/2006/09/20/
% working-with-low-level-file-io-and-encodings/#comment-26764
% 
% Bug:
% -------
% When inspecting the output with the Array Editor, 
% in the Workspace or through the Command Window,
% boxes might appear instead of Unicode characters.
% Type C{1,1} at the prompt: you will see the correct
% string. Also: in Array Editor click on C then C{1,1}.
% 
% Matlab version: starting with R2006b
%
% Revisions:
% -------
% 2009.06.13 - added option to display a waitbar
% 2008.02.27 - function creation
% 
% Created by: Vlad Atanasiu / atanasiu@alum.mit.edu

switch nargin
    case 1
        encoding = 'UTF16-LE';
end
warning off MATLAB:iofun:UnsupportedEncoding;
% read input
fid = fopen(filename, 'r', 'l', encoding);
S = fscanf(fid, '%c'); A=abs(S);
fclose(fid);
% end of line symbol (CR=13, LF=10)
eol_sym1 = 13;% CR: carriage return
eol_sym2 = 10;% LF: line feed
% remove Byte Order Marker 
if A(1)==65279, S = S(2:end); A=abs(S);end  %Byte Order Marker = 65279
% locates column delimitators and end of lines
eol1 = find(A == eol_sym1);
eol2 = find(A == eol_sym2);
if isempty(eol2) && ~isempty(eol1) 
    eol=eol1; eol_sym=eol_sym1; nCharEol=1;
elseif   isempty(eol1) && ~isempty(eol2) 
    eol=eol2; eol_sym=eol_sym2; nCharEol=1;
elseif ~isempty(eol1) && length(eol2)==length(eol1)
    B=eol2-eol1; 
    tt=find(B==1); if length(tt)==length(B),eol=eol1; nCharEol=2;eol_sym=[eol_sym1 eol_sym2];end;
    tt=find(B==-1); if length(tt)==length(B),eol=eol2; nCharEol=2;eol_sym=[eol_sym2 eol_sym1];end;
else
    eol=[eol1 eol2];eol=sort(eol);eol_sym=eol_sym2;
end
% add an end of line mark at the end of the file
S = [S char(eol_sym)]; 
% get number of rows and columns in input
row = numel(eol);
C = cell(row,1); % output cell array
m = 1;
n = 1;
sos = 1;
% parse input
    % single column input
    for r = 1:row
        eos = eol(n) - 1;
        C(r,1) = {S(sos:eos)};
        n = n + 1;
        sos = eos + nCharEol+1;
    end
% end % end of textscanu1
%%