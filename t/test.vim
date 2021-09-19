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

" NOTE: assumes tanka environment is active
function! s:TestTkEval()
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    let &makeprg="cat t/samples/tk-error.txt"
    execute 'silent make!'
    " 4 lines because it includes blank lines and the printed offending line.
    " Not 5 because for some reason the first blank line after the first
    " non-blank line is not in the qf list.
    call testify#assert#equals(len(getqflist()), 4)
    let item = getqflist()[0]
    call testify#assert#equals(item.lnum, 47)
    call testify#assert#equals(item.col, 12)
    call testify#assert#equals(bufname(item.bufnr), "example/prom-grafana/environments/default/main.jsonnet")
    set makeprg&
endfunction
call testify#it('Test tk eval error output', function('s:TestTkEval'))

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
    " Make sure local options are cleared
    call testify#assert#equals(&l:path, '')
    call testify#assert#equals(&statusline, '')
    call testify#assert#equals(&l:makeprg, '')
    call testify#assert#equals(&l:errorformat, '')

    " Make sure options are cleared for other buffer
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/environments/default/main.jsonnet')
    call testify#assert#equals(&l:path, '')
    call testify#assert#equals(&statusline, '')
    call testify#assert#equals(&l:makeprg, '')
    call testify#assert#equals(&l:errorformat, '')
endfunction
call testify#it('Check TankaOff', function('s:TestTankaOff'))

" NOTE: Depends on previous test having run :TankaOff
function! s:TestDisableStatusline()
    " Disable statusline feature
    set statusline=foo
    let g:vim_tanka_statusline_enabled = v:false

    " Set Tanka env
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    execute 'TankaSetEnv'
    call testify#assert#equals(g:vim_tanka_enabled, 1)
    call testify#assert#equals(g:vim_tanka_env, 'environments/default')
    call testify#assert#equals(g:vim_tanka_env_fullpath, getcwd() . '/example/prom-grafana/environments/default/main.jsonnet')
    call testify#assert#equals(&statusline, 'foo')

    execute 'TankaOff'
    call testify#assert#equals(&statusline, 'foo')
endfunction
call testify#it('Check disabling statusline', function('s:TestDisableStatusline'))

function! s:TestSwitchEnv()
    call testify#assert#equals(g:vim_tanka_enabled, 0)
    call testify#assert#equals(g:vim_tanka_env, '')

    " Set Tanka env
    execute 'edit example/prom-grafana/environments/default/main.jsonnet'
    execute 'TankaSetEnv'
    call testify#assert#equals(g:vim_tanka_enabled, 1)
    call testify#assert#equals(g:vim_tanka_env, 'environments/default')
    call testify#assert#equals(g:vim_tanka_env_fullpath, getcwd() . '/example/prom-grafana/environments/default/main.jsonnet')

    " Verify path is correct
    execute 'find path-rank-4.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/environments/default/path-rank-4.libsonnet')

    " Change environment
    execute 'edit example/prom-grafana/environments/secondary/main.jsonnet'
    execute 'TankaSetEnv'
    execute 'find wiz.libsonnet'
    call testify#assert#equals(@%, 'example/prom-grafana/environments/secondary/vendor/wiz.libsonnet')
endfunction
call testify#it('Check switching environment', function('s:TestSwitchEnv'))
