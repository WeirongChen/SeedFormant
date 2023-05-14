# This script goes through sound and TextGrid files in a directory,
# This script is distributed under the GNU General Public License.
# Copyright 4.7.2003 Mietta Lennes
#
# Dec-29-2016, Weirong Chen: 
#	If the textgrid file doesn't exist, 
#	it automatically creates one textgrid and save it.
#          

form Read all wav and textgrid from folder
	integer Start_from 1
	sentence Sound_file_extension .wav
	sentence TextGrid_file_extension .TextGrid
endform

Create Strings as file list... list *'sound_file_extension$'
numberOfFiles = Get number of strings

for ifile from start_from to numberOfFiles
	filename$ = Get string... ifile
	Read from file... 'filename$'

	soundname$ = selected$ ("Sound", 1)
	sound_id = selected("Sound",1)
	# Open a TextGrid by the same name:
	gridfile$ = soundname$+textGrid_file_extension$
	if fileReadable (gridfile$)
		grid_id = Read from file... 'gridfile$'
		@edit_one_file
	else
		select sound_id
		grid_id = To TextGrid... durations
		@edit_one_file
	endif
	select sound_id
	plus grid_id
	Remove
	select Strings list
	# and go on with the next sound file!
endfor

Remove


##====================
procedure edit_one_file
	select sound_id
	plus grid_id
	Edit
	editor: grid_id
		Move cursor to: 0
	endeditor
	pauseScript: "OK?  #", ifile
	select grid_id
	Write to text file... 'soundname$'.TextGrid
endproc