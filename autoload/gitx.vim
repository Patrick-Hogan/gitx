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
