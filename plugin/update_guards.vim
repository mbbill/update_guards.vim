" vim script to batch update include guards
" bai.ming@intel.com
" 
function! s:UpdateGuard(path)
	"Generate the new guard
	let fname = glob('%:p')
	let new_guard = matchstr(fname,a:path.'[^A-Za-z]*\zs.*\ze$')
	if new_guard == ""
		return -1
	endif
	let new_guard = substitute(toupper(new_guard),"[^A-Z0-9]","_","g").'_'

	"Search for the old guard
	call cursor(1,1)
	if search('#ifndef','cW') == 0
		return -2
	endif

	" Now we're in the line of '#ifdef'
	let linenr1 = line('.')
	let line1 = getline(linenr1)
	let orig_guard = matchstr(line1,'^\s*#ifndef\s*\zs[0-9A-Z_]\+\ze$')
	if orig_guard == ''
		return -3
	endif
	if orig_guard == new_guard
		return -4
	endif

	"search for '#define', note that it may not be the following line.
	if search('#define'.'\s*'.orig_guard,'cW') == 0
		return -5
	endif
	let linenr2 = line('.')

	"search for the closing #endif
	"Do a backward search from the file end and match the 1st #endif
	"It should look like this
	"#endif // PATH_TO_THIS_FILE_
	"otherwise pupop a warning.
	norm! G$
	if search('#endif','bcW') == 0
		return -6
	endif
	let linenr3 = line('.')
	if search('#endif.*'.orig_guard.'\s*$','cW') == 0
		echoerr "Warning: #endif should go with a comment."
	endif

	"Begin to replace the guards.
	call setline(linenr1, '#ifndef '.new_guard)
	call setline(linenr2, '#define '.new_guard)
	call setline(linenr3, '#endif  // '.new_guard)
	update
endfunction

function! s:UpdateGuardHere(recursive)
	let cwd = getcwd()
	if a:recursive
		let choice = confirm("Re-generate all include guards for *.h under ".cwd."?","&Yes\n&No",2)
		if choice != 1
			return -1
		endif
	endif
	let cwd = input("Cut out prefix: ",cwd,"dir")
	if !isdirectory(cwd)
		echoerr cwd." is not a valid directory"
		return -2
	endif
	if a:recursive
		args **/*.h
		argdo call s:UpdateGuard(cwd)
	else
		call s:UpdateGuard(cwd)
	endif
endfunction

command! UpdateGuardThis call s:UpdateGuardHere(0)
command! UpdateGuardRecursive call s:UpdateGuardHere(1)
