syntax on
set term=screen-256color
set laststatus=2
set scrolloff=4
set mouse=i
set backspace=indent,eol,start
set ttimeoutlen=10
set tabstop=2 shiftwidth=2 expandtab smarttab autoindent
set showmatch
set hlsearch incsearch
set linebreak
set novisualbell noerrorbells
set number relativenumber
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END