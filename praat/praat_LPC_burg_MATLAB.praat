# praat_LPC_burg_MATLAB.praat  -- compute LPC (burg) formant tracks with refs in PRAAT
# 
# Wei-rong Chen March-12-2019


form ExtractFormants
       sentence wav_fname T0001.wav
       real start_time_(s) 0.85
       real end_time_(s_0=end) 0.95
       real window_size_(s) 0.045
       real step_size_(s) 0.002
       real f1ref_(Hz) 550
       real f2ref_(Hz) 1650
       real f3ref_(Hz) 2750
       real f4ref_(Hz) 4100
       real f5ref_(Hz) 4950
	   boolean preserve_time 1
	   real max_formant_freq_(Hz) 5500 (=adult female)
	   real number_of_poles 14 (=2*maximum number of formants)
	   real number_of_tracks 3
	   boolean if_export_to_txt 0
endform

nFmts = number_of_poles /2
longSoundID = Open long sound file... 'wav_fname$'
total_dur = Get total duration
sampling_rate = Get sampling frequency
resampling_rate = max_formant_freq * 2
if end_time = 0
	end_time = total_dur
endif

soundID = Extract part: 'start_time', 'end_time', 'preserve_time'
removeObject: longSoundID
if resampling_rate <> sampling_rate
	resampled_soundID = Resample... 'resampling_rate' 50
	removeObject: soundID
	soundID = resampled_soundID
endif
duration = end_time - start_time
half_window_size = window_size / 2

### Compute formants:
#   Praat "To Formant (burg)" actually takes in 'half window size' as the argument for "window size"
fmtID = To Formant (burg)... 'step_size' 'nFmts' 'max_formant_freq' 'half_window_size' 50
fmtTrackID = Track... 'number_of_tracks' 'f1ref' 'f2ref' 'f3ref' 'f4ref' 'f5ref' 1 1 1
fmtTierID = Down to FormantTier
matID = Down to TableOfReal... yes no
mat$ = selected$("TableOfReal")
nRows = Get number of rows
removeObject: fmtID, fmtTrackID, fmtTierID
###------------
accum$ = ""

for r to nRows
	t = TableOfReal_'mat$'[r,1]
 	f1 = TableOfReal_'mat$'[r,2]
   	f2 = TableOfReal_'mat$'[r,3]
	f3 = TableOfReal_'mat$'[r,4]
	f1_a = f1-(f1/10)
	f1_b = f1+(f1/10)
	f2_a = f2-(f2/10)
	f2_b = f2+(f2/10)
	f3_a = f3-(f3/10)
	f3_b = f3+(f3/10)
	t1 = t - (window_size/2)
	t2 = t + (window_size/2)
	if t1 <= 0
		t1 = 0
		t2 = t1 + window_size
	endif
	if t2 >= end_time
		t2 = end_time
		t1 = t2 - window_size
		if t1 <= 0
			t1 = 0
		endif
	endif
	selectObject: soundID
	soundSliceID = Extract part... t1 t2 Rectangular 1 no
	ltasID = To Ltas... 50
	a1 = Get maximum... f1_a f1_b None
	a2 = Get maximum... f2_a f2_b None
	a3 = Get maximum... f3_a f3_b None
	##
	t$ = fixed$(t,4)
	f1$ = fixed$(f1,1)
	f2$ = fixed$(f2,1)
	f3$ = fixed$(f3,1)
	a1$ = fixed$(a1,1)
	a2$ = fixed$(a2,1)
	a3$ = fixed$(a3,1)
	#writeInfo: 't2', " ", 't1', " ", 'f1_a', " ", 'f1_b', " ", 'a1'
	spc$ = " "
 	accum$ = accum$ + t$ + spc$  + f1$ + spc$ + f2$ + spc$ + f3$
 	accum$ = accum$ + spc$ + a1$ + spc$ + a2$ + spc$ + a3$ + spc$ 
 	removeObject: 'soundSliceID', 'ltasID'
endfor
out_file_name$ = left$(wav_fname$, length(wav_fname$)-3) + "formants"
selectObject: matID
if if_export_to_txt
	Save as headerless spreadsheet file: out_file_name$
	#writeFileLine: "fmt.txt", accum$ 
endif
removeObject: matID, soundID
fileappend <stdout> 'accum$'
