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
	 if exists("g:stp_host")
	    let host = g:stp_host
	 else
	    let host = "localhost"
	 endif
	 if exists("g:stp_port")
	    let port = g:stp_port
	 else
	    let port = 7654
	 endif
	 let s:channel = ch_open(host . ":" . port, {"mode": "raw"})
	 while type(ch_info(s:channel)) == 0  	    "hack; channel info turns from num to dict when connected
	    sleep 50m
	    let s:channel = ch_open(host . ":" . port, {"mode": "raw"})
	 endwhile
	autocmd VimLeavePre * call ChannelClose()
endfunction

function ChannelInfo()
	 echo ch_info(s:channel)
endfunction

function ChannelClose()
	 call ch_close(s:channel)
endfunction

function s:SendText(text)
	call ch_sendraw(s:channel, a:text)
endfunction

",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,",,

nnoremap <leader>s :call StartServerConnect()<CR>
nnoremap <leader>x :call ChannelClose()<CR>
nnoremap <leader>c<enter> :call <SID>SendText("enter")<CR>

" from https://vim.fandom.com/wiki/Act_on_text_objects_with_custom_functions
function! s:DoAction(algorithm,type)
  " backup settings that we will change
  let sel_save = &selection
  let cb_save = &clipboard
  " make selection and clipboard work the way we need
  set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
  " backup the unnamed register, which we will be yanking into
  let reg_save = @@
  " yank the relevant text, and also set the visual selection (which will be reused if the text
  " needs to be replaced)
  if a:type =~ '^\d\+$'
    " if type is a number, then select that many lines
    silent exe 'normal! V'.a:type.'$y'
  elseif a:type =~ '^.$'
    " if type is 'v', 'V', or '<C-V>' (i.e. 0x16) then reselect the visual region
    silent exe "normal! `<" . a:type . "`>y"
  elseif a:type == 'line'
    " line-based text motion
    silent exe "normal! '[V']y"
  elseif a:type == 'block'
    " block-based text motion
    silent exe "normal! `[\<C-V>`]y"
  else
    " char-based text motion
    silent exe "normal! `[v`]y"
  endif
  " call the user-defined function, passing it the contents of the unnamed register
  let repl = s:{a:algorithm}(@@)
  " if the function returned a value, then replace the text
  if type(repl) == 1
    " put the replacement text into the unnamed register, and also set it to be a
    " characterwise, linewise, or blockwise selection, based upon the selection type of the
    " yank we did above
    call setreg('@', repl, getregtype('@'))
    " relect the visual region and paste
    normal! gvp
  endif
  " restore saved settings and register value
  let @@ = reg_save
  let &selection = sel_save
  let &clipboard = cb_save
endfunction

function! s:ActionOpfunc(type)
  return s:DoAction(s:encode_algorithm, a:type)
endfunction

function! s:ActionSetup(algorithm)
  let s:encode_algorithm = a:algorithm
  let &opfunc = matchstr(expand('<sfile>'), '<SNR>\d\+_').'ActionOpfunc'
endfunction

function! MapAction(algorithm, key)
  exe 'nnoremap <silent> <Plug>actions'    .a:algorithm.' :<C-U>call <SID>ActionSetup("'.a:algorithm.'")<CR>g@'
  exe 'xnoremap <silent> <Plug>actions'    .a:algorithm.' :<C-U>call <SID>DoAction("'.a:algorithm.'",visualmode())<CR>'
  exe 'nnoremap <silent> <Plug>actionsLine'.a:algorithm.' :<C-U>call <SID>DoAction("'.a:algorithm.'",v:count1)<CR>'
  exe 'nmap '.a:key.'  <Plug>actions'.a:algorithm
  exe 'xmap '.a:key.'  <Plug>actions'.a:algorithm
  exe 'nmap '.a:key.a:key[strlen(a:key)-1].' <Plug>actionsLine'.a:algorithm
endfunction

call MapAction('SendText', '<leader>c')
