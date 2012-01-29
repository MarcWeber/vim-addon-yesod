" exec vam#DefineAndBind('s:c','g:addon_yesod','{}')
if !exists('g:addon_yesod') | let g:addon_yesod = {} | endif | let s:c = g:addon_yesod

if (!exists('s:cabal_file'))
  let s:cabal_file = []
endif

fun! vim_addon_yesod#Restart() abort
  let new = readfile(glob('*.cabal'))
  if (new != s:cabal_file)
    let s:cabal_file = new
    " restart process
    call vim_addon_yesod#Stop()
    sleep 1
    call vim_addon_yesod#Start('vim_addon_yesod#TryLoad')
  else
    " reload
    " .status indicates shutdown of process
    if has_key(s:c, 'ctx') && !has_key(s:c, 'ctx.status')
      " stop server so that it can be reloaded and started again
      " this only "stops" executing "main" in ghci
      call s:c.ctx.kill('SIGINT')
      call vim_addon_yesod#TryLoad('')
    else
      call vim_addon_yesod#Start('vim_addon_yesod#TryLoad')
    endif
  endif
endf

fun! vim_addon_yesod#Start(continuation_func) abort
  " 'debug_process':1,
  let p = 'Executing ghci with the following options: \zs.*'
  let options_escaped = join(map(split(system("cabal-ghci --cabal-ghci-print-ghci-args", "exit"),"\n"),'shellescape(v:val)'),' ')
  let cmd = 'ghci '.options_escaped
  let s:c.ghci_cmd = cmd
  let s:c.ctx = async_porcelaine#LogToBuffer({'cmd':cmd, 'move_last':1, 'buf_name' : 'YESOD_SERVER_GHCI'})
  let s:c.ctx.buf_nr = bufnr('.')
  echom "starting yesod. If you don't see any additional messages cabal-ghci was not found or such"
  call s:c.ctx.dataTillRegexMatchesLine("Prelude>", funcref#Function(function(a:continuation_func), {'self': s:c.ctx } ), {'echo' : 1})
endf

fun! vim_addon_yesod#Stop() abort
  if (has_key(s:c, 'ctx'))
  endif
endf

fun! vim_addon_yesod#TryLoad(data) abort
  " reload code into ghci:
  call s:c.ctx.dataTillRegexMatchesLine("FINISHED_TRYING_LOADING", funcref#Function(function('vim_addon_yesod#PopulateQuickFix')), {'echo' : 1})
  let cmds = [':set args development', ':m +System.IO', ':l main.hs', 'putStrLn "FINISHED_TRYING_LOADING"']
  call s:c.ctx.send_command(join(cmds,"\n")."\n")
endf

fun! vim_addon_yesod#PopulateQuickFix(data) abort
  if (!has_key(s:c,'tmp_file'))
    let s:c.tmp_file = tempname()
  endif
  call writefile(split(s:c.ctx.received_data, "\n"), s:c.tmp_file)
  exec 'cfile '.fnameescape(s:c.tmp_file)
  " if loading failed this should cause error as well
  call s:c.ctx.send_command("main\n")
endf
" exec 'e '.g:addon_yesod.tmp_file
