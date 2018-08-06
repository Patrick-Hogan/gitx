" Autoload gitx functions

let s:shh = ' 2>/dev/null'
let b:original_statusline = &statusline
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
    if (v:shell_error) > 0 
        unlet b:gitrepo 
        call gitx#UnsetStatus()
        return
    endif
    let b:gitreposhort = substitute(b:gitrepo, '.*\/\([^/]\+\)', '\1', '')
endfunction

function! gitx#SetRef()
    if !exists("b:gitdir")
        if exists("b:gitref")
            unlet b:gitref
        endif 
        call gitx#UnsetStatus()
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
    if !exists("b:gitdir") || !exists("b:gitref")  || !exists("b:gitrepo")
                \ || !exists("b:gitreposhort")
                \ || (b:gitdir == "" && b:gitref == "") 
        call gitx#UnsetStatus()
        return
    endif
    if exists("b:git_statusline") && b:git_statusline > 0
        let b:original_statusline = &statusline
    endif 
    let &l:statusline = '%<'
    "let &l:statusline .= '[%{fnamemodify(b:gitrepo,":.")}:'
    let &l:statusline .= '[%{b:gitreposhort}:'
    let &l:statusline .= '%{b:gitref}]'
    let &l:statusline .= ' %f'
    let b:git_statusline = 1
endfunction

function! gitx#UnsetStatus()
    let b:git_statusline = 0
    if exists("b:original_statusline")
        let &l:statusline = b:original_statusline
    else
        let &l:statusline = ""
    endif
endfunction

function! gitx#Diff(...) 
    let ref = get(a:, 1, "HEAD")
    let fname2 = get(a:, 2, expand('%'))
    let fname1 = get(a:, 3, expand('%'))
    
endfunction
