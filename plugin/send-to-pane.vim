",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,

let s:path = expand('<sfile>:p:h:h')

",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,

function StartServer()
	let server_command = ['python3', s:path . '/server/send-to-pane.py']
	let arglist = []
	if exists("g:stp_host")
		call extend(arglist, ["-n", g:stp_host])
	endif
	if exists("g:stp_port")
		call extend(arglist, ["-p", g:stp_name])	
	endif
	if exists("g:stp_target")
		call extend(arglist, (["-t", g:stp_target])
	endif
	let g:stp_job = job_start(server_command + arglist)
	"must maintain reference to job lest it be garbage collected
endfunction

function StartServerConnect()
	 call StartServer()
	 if exists("g:stp_port")
	    let port = g:stp_port
	 else
	    let port = 7654
	 endif
	 if exists("g:stp_host")
	    let host = g:stp_host
	 else
	    let host = "localhost"
	 endif
	 let s:channel = ch_open(host . ":" . port, {"mode": "raw"})
	 while type(ch_info(s:channel)) == 0  	    "hack; channel info turns from num to dict when connected
	    sleep 50m
	    let s:channel = ch_open(host . ":" . port, {"mode": "raw"})
	 endwhile
endfunction

function ChannelInfo()
	 echo ch_info(s:channel)
endfunction

function ChannelClose()
	 call ch_close(s:channel)
endfunction

",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,

function SendChCurrLine()
	let line = getline(".")
	call ch_sendraw(s:channel, line)
endfunction

function SendChCurrLineEval()
	 call SendChCurrLine()
	 call ch_sendraw(s:channel, "enter")
endfunction

",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,



",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,
" " " " " Old function to choose pane from tmux through vim. A LOT OF EFFORT!!
" function SetPaneInter()
" call  system('tmux choose-tree "set-environment inferiorproc ''%%''"')
" let msg = system('tmux show-environment inferiorproc')	
" let target =  matchstr(msg, '=\(.*=\)\@!.*')
" py3 'import subprocess; subprocess.Popen(["python3", "~/scratch/send-to-pane.py"])'
" let args = ['python3', '~/scratch/send-to-pane.py', '-t', target]
" let job = job_start(args)
" endfunction
",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,
