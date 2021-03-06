" These variables are open to users
let g:vim_tanka_statusline_enabled = v:true
let g:vim_tanka_compile_enabled = v:true

" These variables must be changed simultaneously
let g:vim_tanka_enabled = 0
let g:vim_tanka_env = ''
let g:vim_tanka_env_fullpath = ''

" This is the 'errorformat' used to parse Tanka's Jsonnet error messages:
"
"   Start a multi-line error message that extracts filename, line, column, and
"   message. Note that there is typically only one error reported, so this
"   errorformat is only designed for that.
"
"       %EError:\ %.%#:\ %f:%l:%c\-%*[0-9]\ %m,
"
"   The next pattern captures the following lines that typically show
"   context of the error (i.e. the offending line). The 'C' matches a line
"   continuation; the '+' includes it in the output.
"
"       %+C,
"
"   This took probably around 2 hours to figure out...
let s:errorformat = '%EError:\ %.%#:\ %f:%l:%c\-%*[0-9]\ %m,%+C'

command! -nargs=0 TankaOff call s:TankaOff()
command! -nargs=0 TankaEnv call s:PrintTankaEnv()
command! -nargs=0 TankaSetEnv call s:SetTankaEnv()

function! s:PrintTankaEnv()
    if g:vim_tanka_enabled == 0
        echo "vim-tanka is disabled!"
    elseif g:vim_tanka_env == ''
        echo 'Tanka environment is not set.'
    else
        echo g:vim_tanka_env '->' g:vim_tanka_env_fullpath
    endif
endfunction

function! s:TankaOff()
    let g:vim_tanka_enabled = 0
    let g:vim_tanka_env = ''

    " Reset statusline
    if g:vim_tanka_statusline_enabled == v:true
        set statusline=
    endif

    " Reset path value (will use global value)
    " path was changed to a buffer-local value. We don't restore
    " any previous buffer-local path because it's unlikely anyone
    " does that. If they did, it would probably conflict with this
    " plugin anyway.
    for buf in getbufinfo()
        if getbufvar(buf.bufnr, '&filetype') == "jsonnet"
            call setbufvar(buf.bufnr, '&path', '')
            if g:vim_tanka_compile_enabled == v:true
                call setbufvar(buf.bufnr, '&makeprg', '')
                call setbufvar(buf.bufnr, '&errorformat', '')
            endif
        endif
    endfor
endfunction

function! s:TankaOn()
    let g:vim_tanka_enabled = 1

    if g:vim_tanka_statusline_enabled == v:true
        execute 'set statusline=%<%f\ [' . g:vim_tanka_env . ']\ %*%h%m%r%=%-14.(%l,%c%V%)\ %P'
    endif

    " Try to get Jpath from tk
    try
        let p = s:VimTankaGetPath()
    catch 'error'
        echoerr 'Unable to get jpath from Tanka!'
        return
    endtry

    " Set file search 'path' for all jsonnet buffers
    for buf in getbufinfo()
        if getbufvar(buf.bufnr, '&filetype') == "jsonnet"
            call setbufvar(buf.bufnr, '&path', p)
            if g:vim_tanka_compile_enabled == v:true
                call setbufvar(buf.bufnr, '&makeprg', 'tk eval ' . g:vim_tanka_env_fullpath)
                call setbufvar(buf.bufnr, '&errorformat', s:errorformat)
            endif
        endif
    endfor
endfunction

function! s:SetTankaEnv()
    let l:fullpath = expand('%:p')
    let spec_path = expand('%:p:h') . '/spec.json'
    if filereadable(spec_path) == v:false
        echoerr 'No spec.json found at' expand('%:p:h')
        return
    endif

    try
        let spec = join(readfile(spec_path), "\n")
    catch
        echoerr 'Unable to read environment spec:' spec_path
    endtry

    try
        let spec = json_decode(spec)
    catch
        echoerr 'Unable to parse spec (invalid JSON):' spec_path
        return
    endtry

    try
        let l:name = spec.metadata.name
    catch
        echoerr 'Unable to extract environment name (metadata.name) from spec.json!'
        return
    endtry

    " Set these vars at the same time to prevent inconsistency
    call s:TankaOff()
    let g:vim_tanka_env = name
    let g:vim_tanka_env_fullpath = fullpath
    call s:TankaOn()
    call s:PrintTankaEnv()
endfunction

function! VimTankaSetPath()
    if &filetype == 'jsonnet'
        try
            let p = s:VimTankaGetPath()
        catch 'error'
            echoerr 'Unable to get jpath from Tanka!'
            return
        endtry
        execute 'setlocal path=' . p
    endif
endfunction

function! VimTankaSetCompiler()
    let &l:makeprg = "tk eval " . g:vim_tanka_env_fullpath
    let &l:errorformat = s:errorformat
endfunction

function! s:VimTankaGetPath()
    let jpath = system('tk tool jpath ' . g:vim_tanka_env_fullpath)
    if v:shell_error != 0
        echoerr 'Failed to get jpath from Tanka!'
        echoerr jpath
        throw 'error'
    endif
    " NOTE: Before searching JPaths, Jsonnet looks in the directory of the
    " file with the import statement:
    " https://github.com/google/go-jsonnet/blob/2f2f6d664f06d064c4b3525ea34a789c1ac95cda/imports.go#L242
    " Tanka doesn't appear to change that behavior, except that it does
    " seem to resolve 'tk.libsonnet' before anything else:
    " https://github.com/grafana/tanka/blob/68efdb984ae3f1752ca67528e0c82bd74c62e548/pkg/jsonnet/importer.go#L37
    return '.,' . join(reverse(split(jpath, ':')), ',')
endfunction

