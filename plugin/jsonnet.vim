let g:vim_tanka_enabled = 0

" These variables must be changed simultaneously
let g:vim_tanka_env = ''
let g:vim_tanka_env_fullpath = ''

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

    " Reset statuslines
    for win in getwininfo()
        if getbufvar(win.bufnr, '&filetype') == "jsonnet"
            call setwinvar(win.winnr, '&statusline', '')
        endif
    endfor
    let curBufNr = bufnr('')
    for buf in getbufinfo()
        if getbufvar(buf.bufnr, '&filetype') == "jsonnet"
            " echom 'clearing statusline for buf: ' . buf.bufnr
            execute 'buffer ' . buf.bufnr
            execute 'setlocal statusline='
            " call setbufvar(buf.bufnr, '&statusline', '')
        endif
    endfor
    execute 'buffer ' . curBufNr

    " Reset path value (will use global value)
    " path was changed to a buffer-local value. We don't restore
    " any previous buffer-local path because it's unlikely anyone
    " does that. If they did, it would probably conflict with this
    " plugin anyway.
    for buf in getbufinfo()
        if getbufvar(buf.bufnr, '&filetype') == "jsonnet"
            call setbufvar(buf.bufnr, '&path', '')
        endif
    endfor

    " augroup vim_tanka_group
    "     autocmd!
    " augroup END
endfunction

function! s:ResetStatusline()
    if &filetype == "jsonnet"
        setlocal statusline=
    endif
endfunction

function! s:TankaOn()
    let g:vim_tanka_enabled = 1

    " Show statuslines on all Jsonnet windows
    let curWinNr = winnr()
    for win in getwininfo()
        if getbufvar(win.bufnr, '&filetype') == "jsonnet"
            execute win.winnr . 'wincmd w'
            call VimTankaShowStatusline()
        endif
    endfor
    execute curWinNr . 'wincmd w'

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
        endif
    endfor
    
    " augroup vim_tanka_group
    "     autocmd!
    "     autocmd BufLeave *.jsonnet,*.libsonnet call s:ResetStatusline()
    " augroup END
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

function! VimTankaShowStatusline()
    execute 'setlocal statusline=%<%f\ [' . g:vim_tanka_env . ']\ %*%h%m%r%=%-14.(%l,%c%V%)\ %P'
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

