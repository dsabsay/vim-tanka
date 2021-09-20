function! s:TestStartup()
    call testify#assert#equals(g:vim_tanka_enabled, 0)
endfunction
call testify#it(
    \ 'Tanka disabled on start',
    \ function('s:TestStartup'))

function! s:TestEnableCompile()
    let s:errorformatBefore = &errorformat
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    execute 'TankaSetEnv'

    let s:makeprgExpected = "tk eval " . getcwd() . "/example/prom-grafana/environments/default/main.jsonnet"
    let s:errorformatExpected = '%EError:\ %.%#:\ %f:%l:%c\-%*[0-9]\ %m,%+C'

    call testify#assert#equals(&makeprg, s:makeprgExpected)
    call testify#assert#equals(&errorformat, s:errorformatExpected)
endfunction
call testify#it(
    \ 'makeprg and errorformat are set by default',
    \ function('s:TestEnableCompile'))

function! s:TestEnableCompileNewBuffer()
    " Make sure it works for other buffers
    execute 'find path-rank-1.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/vendor/path-rank-1.libsonnet')
    call testify#assert#equals(&makeprg, s:makeprgExpected)
    call testify#assert#equals(&errorformat, s:errorformatExpected)
endfunction
call testify#it(
    \ 'makeprg and errorformat are set for new buffers',
    \ function('s:TestEnableCompileNewBuffer'))

function! s:TestEnableCompileTankaOff()
    execute 'TankaOff'
    call testify#assert#equals(&makeprg, 'make')
    call testify#assert#equals(&errorformat, s:errorformatBefore)

    " Make sure it's cleared for all buffers
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    call testify#assert#equals(&makeprg, 'make')
    call testify#assert#equals(&errorformat, s:errorformatBefore)
endfunction
call testify#it(
    \ 'makeprg and errorformat are reset by :TankaOff',
    \ function('s:TestEnableCompileTankaOff'))
