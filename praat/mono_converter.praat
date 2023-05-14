# This script converts all the files in a specified folder into mono files. 
# written by Shigeto Kawahara. version 4/7/2009


form mono converter
	sentence InputDir  ./
endform


createDirectory ("original")
Create Strings as file list... list 'inputDir$'*.wav
numberOfFiles = Get number of strings

for ifile to numberOfFiles

	select Strings list
	fileName$ = Get string... ifile
	Read from file... 'inputDir$''fileName$'
	sound_name$ = selected$ ("Sound")
	Write to WAV file... ./original/'fileName$'

	select Sound 'sound_name$'
	Convert to mono
	Save as WAV file: "./'fileName$'"

	select all
	minus Strings list
	Remove

endfor

select all
Remove