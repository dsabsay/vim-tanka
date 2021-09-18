function! s:TestTestify()
    call testify#assert#equals(1, 1)
endfunction
call testify#it('Test should pass', function('s:TestTestify'))

function! s:TestStartup()
    call testify#assert#equals(g:vim_tanka_enabled, 0)
endfunction
call testify#it('Tanka disabled on start', function('s:TestStartup'))

function! s:TestTankaSetEnv()
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    execute 'TankaSetEnv'
    call testify#assert#equals(g:vim_tanka_enabled, 1)
    call testify#assert#equals(g:vim_tanka_env, 'environments/default')
    call testify#assert#equals(g:vim_tanka_env_fullpath, getcwd() . '/example/prom-grafana/environments/default/main.jsonnet')
endfunction
call testify#it('Check TankaSetEnv', function('s:TestTankaSetEnv'))

" Depends on TestTankaSetEnv() running first
function! s:TestFind()
    execute 'find path-rank-4.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/environments/default/path-rank-4.libsonnet')
    " Go back to main.jsonnet to make sure we're testing the resolution from
    " the top.
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    execute 'find path-rank-3.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/lib/path-rank-3.libsonnet')
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    execute 'find path-rank-2.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/environments/default/vendor/path-rank-2.libsonnet')
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    execute 'find path-rank-1.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/vendor/path-rank-1.libsonnet')

    " Now test that an import relative to the file making the import works
    " (this is default Jsonnet behavior).
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    execute 'find example-lib.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/lib/example-lib.libsonnet')
    " Now pretend example-lib.libsonnet has an import like this:
    "   local x = import 'example-lib/foo.libsonnet';
    " Note that this is still in the jpath given by `tk tool jpath`
    execute 'find example-lib/foo.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/lib/example-lib/foo.libsonnet')
    " Now pretend foo.libsonnet has an import:
    "   local bar = import 'bar.libsonnet';
    execute 'find bar.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/lib/example-lib/bar.libsonnet')
endfunction
call testify#it('Check finding imports', function('s:TestFind'))

function! s:TestTankaOff()
    " Make sure two different buffers are open
    execute 'find main.jsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/environments/default/main.jsonnet')
    execute 'find path-rank-1.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/vendor/path-rank-1.libsonnet')
    let bn = bufnr('')

    execute 'TankaOff'
    " Make sure we're still in the same buffer and file
    call testify#assert#equals(bufnr(''), bn)
    call testify#assert#equals(@%, 'example/prom-grafana/vendor/path-rank-1.libsonnet')
    " Make sure 'path' and 'statusline' are cleared
    call testify#assert#equals(&l:path, '')
    call testify#assert#equals(&l:statusline, '')

    " Make sure path and statusline are cleared for other buffer
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/environments/default/main.jsonnet')
    call testify#assert#equals(&l:path, '')
    call testify#assert#equals(&l:statusline, '')
endfunction
call testify#it('Check TankaOff', function('s:TestTankaOff'))
