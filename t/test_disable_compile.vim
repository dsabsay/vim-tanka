function! s:TestStartup()
    call testify#assert#equals(g:vim_tanka_enabled, 0)
endfunction
call testify#it(
    \ 'Tanka disabled on start',
    \ function('s:TestStartup'))

function! s:TestDisableCompile()
    let s:efmBefore = &errorformat
    let g:vim_tanka_compile_enabled = v:false
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    execute 'TankaSetEnv'

    call testify#assert#equals(g:vim_tanka_enabled, 1)
    call testify#assert#equals(g:vim_tanka_env, 'environments/default')
    call testify#assert#equals(
        \ g:vim_tanka_env_fullpath,
        \ getcwd() . '/example/prom-grafana/environments/default/main.jsonnet')
    " make is the default
    call testify#assert#equals(&makeprg, 'make')
    call testify#assert#equals(&errorformat, s:efmBefore)
endfunction
call testify#it(
    \ 'makeprg and errorformat are disabled when TankaSetEnv is run',
    \ function('s:TestDisableCompile'))

function! s:TestDisableCompileNewBuffer()
    " Should also be disabled for other buffers that are opened
    execute 'find path-rank-1.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/vendor/path-rank-1.libsonnet')
    call testify#assert#equals(&makeprg, 'make')
    call testify#assert#equals(&errorformat, s:efmBefore)
endfunction
call testify#it(
    \ 'makeprg and errorformat are disabled for new buffers',
    \ function('s:TestDisableCompileNewBuffer'))

function! s:TestDisableCompileTankaOff()
    " Pretend user had customized this
    let &l:makeprg = 'foobar'
    let &l:errorformat = 'baz'

    execute 'TankaOff'
    call testify#assert#equals(&makeprg, 'foobar')
    call testify#assert#equals(&errorformat, 'baz')
endfunction
call testify#it(
    \ 'makeprg and errorformat are not modified by :TankaOff',
    \ function('s:TestDisableCompileTankaOff'))
