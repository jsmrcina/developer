" Windows-style keybindings (CTRL-C/V/X, shifted arrows select). mswin.vim ships
" with vim on Linux too, but guard it so a minimal vim install still starts, and
" guard :behave since it is deprecated and slated for removal.
if filereadable($VIMRUNTIME . "/mswin.vim")
    source $VIMRUNTIME/mswin.vim
    if exists(":behave")
        behave mswin
    endif
endif

set nobackup
set nowritebackup
set noswapfile
set backspace=indent,eol,start

set tabstop=4
set shiftwidth=4
set expandtab

vmap <Tab> >gv
vmap <S-Tab> <gv
