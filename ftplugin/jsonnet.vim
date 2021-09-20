if g:vim_tanka_enabled && g:vim_tanka_env != ''
    call VimTankaSetPath()
    if g:vim_tanka_compile_enabled == v:true
        call VimTankaSetCompiler()
    endif
endif
