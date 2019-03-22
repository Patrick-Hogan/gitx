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

" Simple wrapper for executing git comands and returning the results:
function! gitx#GitCmd(cmd)
   return Trim(system('git --git-dir='.b:gitdir.' '.a:cmd.s:shh))
endfunction

" Utility function to set the buffer variable for repo name and update status
" bar:
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

" Set b:gitref to a human-readable reference to the current git ref:
function! gitx#SetRef()
    if exists("b:git_reffile") && b:git_reffile > 0
        return
    endif
    if !exists("b:gitdir")
        if exists("b:gitref")
            unlet b:gitref
        endif 
        call gitx#UnsetStatus()
        return
    endif
    let b:gitref=gitx#GitCmd('rev-parse --abbrev-ref HEAD')
    if v:shell_error > 0 | unlet b:gitref | return | endif
    " Try to expand 'HEAD' to something useful:
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

" Get the full listing of git references
function! gitx#GetRefs()
    return split(gitx#GitCmd('rev-parse --symbolic-full-name --all'))
endfunction

" Get the path name for a file relative to the repo root:
function! gitx#GetRelativeFilename(fname)
    if !exists('b:gitdir')
        return a:fname
    endif
    let l:cwd = getcwd()
    let l:gitrepo = b:gitrepo
    if system('uname') =~ "NT"
        let l:cwd = substitute(l:cwd, "^\\([A-Za-z]*\\):/", "\\L/\\1/", "")
        let l:gitrepo = substitute(b:gitrepo, "^\\([A-Za-z]*\\):/", "\\L/\\1/", "")
    endif
    cd l:gitrepo
    let l:fname = fnamemodify(a:fname, ':.')
    cd l:cwd
    return l:fname
endfunction

" Update the status bar with: [repo-name:ref] relative/filename
function! gitx#SetStatus(...)
    if !exists("b:gitdir") || !exists("b:gitrepo")
                \ || !exists("b:gitreposhort")
                \ || !exists("b:gitref")
                \ || (b:gitdir == "" && b:gitref == "") 
        call gitx#UnsetStatus()
        return
    endif
    if exists("b:git_reffile") && b:git_reffile > 0
        return
    endif
    if exists("b:git_statusline") && b:git_statusline > 0
        let b:original_statusline = &statusline
    endif 
    let l:ref = get(a:, 1, b:gitref)
    let l:fname = get(a:, 2, expand('%'))
    let &l:statusline = '%<'
    "let &l:statusline .= '[%{fnamemodify(b:gitrepo,":.")}:'
    let &l:statusline .= '[%{b:gitreposhort}:'
    let &l:statusline .= '%{b:gitref}]'
    let &l:statusline .= ' %f'
    let &l:statusline .= '%=%c, %l/%L %P [%y]'
    let b:git_statusline = 1
endfunction

" Revert the statusline to whatever it was before we messed with it:
function! gitx#UnsetStatus()
    if exists("b:git_reffile") && b:git_reffile > 0
        return
    endif
    let b:git_statusline = 0
    if exists("b:original_statusline")
        let &l:statusline = b:original_statusline
    else
        let &l:statusline = ""
    endif
endfunction

" Get the path to a file from repo root:
function! gitx#GetRepoFilename(fname)
    if !exists("b:gitrepo")
        return ""
    endif
    let l:cwd = getcwd()
    execute "cd ".fnamemodify(b:gitrepo, ':p')
    let l:fname = fnamemodify(a:fname, ":.")
    execute "cd ".l:cwd
    return l:fname 
endfunction

" Show a git file from any ref:
function! gitx#ShowGitFile(ref, fname)
    let l:gitdir = b:gitdir
    let l:gitrepo = b:gitrepo
    let l:gitreposhort = b:gitreposhort
    let l:fname = gitx#GetRepoFilename(a:fname)
    let l:ft = &filetype
    enew
    let msg = "DNE" | if exists("b:fname") | let msg = b:fname | endif
    let b:gitdir = l:gitdir
    let b:gitrepo = l:gitrepo
    let b:gitreposhort = l:gitreposhort
    let b:fname = l:fname
    let &ft = l:ft
    execute '0:read !git --git-dir='.b:gitdir.' show '.a:ref.':'.b:fname
    normal! J <CR>
    set bt=nofile
    let b:gitref = a:ref
    let &l:statusline = '%<[git]'
    let &l:statusline .= '[%{b:gitreposhort}:%{b:gitref}]'
    let &l:statusline .= ' %{b:fname}'
    let &l:statusline .= '%=%c, %l/%L %P [%y]'
    let b:git_statusline = 1
    let b:git_reffile = 1
endfunction

" Open a diff of the current buffer and the same file on any git ref in vsplit:
function! gitx#DiffThis(...)
    if !exists("b:gitdir") || !exists("b:gitref")
        echom "Must be in a git repository to execute git#Diff"
    endif

    let l:ref = get(a:, 1, 'HEAD')
    diffthis 
    vsplit
    call gitx#ShowGitFile(l:ref, expand('%'))
    diffthis 
endfunction
