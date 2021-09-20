.PHONY: test
test:
	vim -Nu t/vimrc -c 'TestifyFile' t/test_enable_compile.vim
	vim -Nu t/vimrc -c 'TestifyFile' t/test_disable_compile.vim
	vim -Nu t/vimrc -c 'TestifyFile' t/test.vim
