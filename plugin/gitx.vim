" Vim plugin to add repo info to the status line and add commands for easily
" diffing between git commit-ish versions of files

autocmd BufRead,BufEnter,BufNewFile,BufCreate,BufNew * call gitx#SetRepo()
autocmd BufRead,BufEnter,FocusGained,FileChangedShell,CmdlineEnter,CmdlineLeave * call gitx#SetRef()
autocmd BufRead,BufEnter,FocusGained,FileChangedShell,CmdlineEnter,CmdlineLeave * call gitx#SetStatus()
