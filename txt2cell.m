function lines = txt2cell(filename, encoding)
% Read text file into cell array. 
% Each line is stored in one cell in a cell array.
% W.Chen   DEC-18-2019
if ~exist(filename, 'file'), lines = {}; return; end
if nargin < 2 || isempty(encoding), encoding = 'US-ASCII';end
permission = 'r'; % read file in text mode. See 'help fopen'.
machinefmt = 'n'; % reading or writing in bytes or bits. 'n' = 'native' {default}
cr = 13; % carriage return = 13 
lf = 10; % line feed = 10
fid = fopen(filename,permission, machinefmt, encoding);
s = fscanf(fid, '%c');
fclose(fid);
% if the first character is BOM, then remove it:
if unicode2native(s(1))==26, s = s(2:end);end 
% if the file is not ended with EOL, then add an EOL to the end:
isLastCR=abs(s(end)) == cr;  isLastCRLF = abs(s(end-1))==cr && abs(s(end))==lf;
isEndedWithEOL = isLastCR || isLastCRLF;
if ~isEndedWithEOL,  s = [s, char(cr)]; end
%%
cr_inds = find(abs(s) == cr)'; lf_inds = find(abs(s) == lf)';
nRows = numel(cr_inds);
lines = cell(nRows,1); % output lines in cell array
% 1st line:
i=1; i1 = 1; i2 = cr_inds(i)-1; lines{i} = s(i1:i2);
if nRows ==1, return;end
% 2ed line forward:
for i = 2:nRows
    i1 = cr_inds(i-1)+1+any(ismember(lf_inds, cr_inds(i)+1));  i2 = cr_inds(i)-1;
    lines{i} = s(i1:i2);
end

return