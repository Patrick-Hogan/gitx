" Vim plugin to add repo info to the status line and add commands for easily
" diffing between git commit-ish versions of files

augroup GitX
    autocmd BufRead,BufEnter,BufNewFile,BufCreate,BufNew * call gitx#SetRepo()
    autocmd BufRead,BufEnter,FocusGained,FileChangedShell,CmdlineEnter,CmdlineLeave * call gitx#SetRef()
    autocmd BufRead,BufEnter,FocusGained,FileChangedShell,CmdlineEnter,CmdlineLeave * call gitx#SetStatus()
    autocmd BufUnload ADD_EDIT.patch call gitx#ApplyPatch()
augroup END

command! -nargs=? GitDiffThis :call gitx#DiffThis(<f-args>)
command! -nargs=+ GitShow :call gitx#ShowGitFile(<f-args>)
command! GitAddThis :call gitx#AddThis()
command! -nargs=? GitAdd :call gitx#AddI(<f-args>)
