" Same thing that vim-jsonnet does:
" https://github.com/google/vim-jsonnet/blob/b7459b36e5465515f7cf81d0bb0e66e42a7c2eb5/ftdetect/jsonnet.vim#L15
autocmd BufNewFile,BufRead *.jsonnet setf jsonnet
autocmd BufNewFile,BufRead *.libsonnet setf jsonnet
