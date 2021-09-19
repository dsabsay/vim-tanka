if g:vim_tanka_enabled && g:vim_tanka_env != ''
    call VimTankaSetPath()
    call VimTankaSetCompiler()
endif
