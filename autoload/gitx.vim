" Autoload gitx functions

let s:shh = ' 2>/dev/null'
let s:original_statusline = &statusline
let b:git_statusline = 0

function! Trim(str)
    return substitute(a:str,"\s*\n$","","")
endfunction

function! TrimSys(cmd)
    return Trim(system(a:cmd.s:shh))
endfunction

function! gitx#GitCmd(cmd)
   return Trim(system('git --git-dir='.b:gitdir.' '.a:cmd.s:shh))
endfunction

function! gitx#SetRepo()
    let b:gitdir=TrimSys('cd '.expand('%:h').' && git rev-parse --absolute-git-dir'.s:shh)
    let b:gitrepo = substitute(b:gitdir, '\/\.git', '', '')
    if (v:shell_error) > 0 | unlet b:gitrepo | return | endif
endfunction

function! gitx#SetRef()
    if !exists("b:gitdir")
        if exists("b:gitref")
            unlet b:gitref
        endif
        return
    endif
    let b:gitref=gitx#GitCmd('rev-parse --abbrev-ref HEAD')
    if v:shell_error > 0 | unlet b:gitref | return | endif
    if b:gitref == "HEAD"
        let b:gitref = gitx#GitCmd('describe --all --always --long')
        if v:shell_error > 0 | let b:gitref = "HEAD" |  return | endif 
        " with --all, ref will start with tags/, heads/ or remotes/, and, with
        " --long, will end with '-gSHA1SUM'
        let b:gitref = substitute(b:gitref, '^\([rht]\)\(emotes\|eads\|ags\)/', '\1:', '')
        let b:gitref = substitute(b:gitref, '-g[A-Fa-f0-9]\+$', '', '')
        let b:gitref = substitute(b:gitref, '-0$', '', '')
    endif
endfunction

function! gitx#SetStatus()
    if !exists("b:gitdir") || !exists("b:gitref")
        if exists("s:original_statusline")
            let &l:statusline = s:original_statusline
        else
            let &l:statusline=""
        endif
        let b:git_statusline = 0
        return
    endif
    if !exists("b:git_statusline") && b:git_statusline > 0
        let s:original_statusline = &statusline
    endif 
    let &l:statusline = '%<'
    let &l:statusline .= '[%{fnamemodify(b:gitrepo,":.")}:'
    let &l:statusline .= '%{b:gitref}]'
    let &l:statusline .= ' %f'
    let b:git_statusline = 1
endfunction

function! gitx#Diff(...)
    if !exists("b:gitdir") || !exists("b:gitref")
        echom "Must be in a git repository to execute git#Diff"
    endif

    if len(a:000) > 4 | echom "Too many arguments! Ignoring extra args." | endif
    lf len(a:000) > 3 | let f2 = a:4 | endif
    if len(a:000) > 2 | let f1 = a:3 | endif
    if len(a:000) > 1 | let ref2 = a:2 | endif
    if len(a:000) > 0 | let ref1 = a:1 | endif 

    let fidx = len(a:000) - 1
    if fidx > 0 | let f2 = a:000[fidx] | let f1dx -= 1 | endif
    let f1 = a:000[fidx]
    let fidx -= 1
    if fidx > 0 let r2 = a:000[fidx] | let fidx -= 1 | endif
    let f2 = a:000[fidx] 
    
    " TODO: Handle cases: 
    "   ref1 file1 ref2 file2
    "   ref1 file1 file2
    "   ref1 ref2 file1
    "   ref1 ref2
    "   ref1
    "   file1

    " Actual execution:
    diffthis
    vnew | r !git show :autoload/gitx.vim
    diffthis
    set bt=nofile
    let &l:statusline = '%<'
    let &l:statusline .= '[%{fnamemodify(b:gitrepo,":.")}:'
    let &l:statusline .= '%{b:gitref}]'
    let &l:statusline .= ' %f'
    let b:git_statusline = 1

    
    echo "git diff ".ref1." ".ref2." -- ".f1
endfunction
