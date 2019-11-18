" Runtime path manipulation
execute pathogen#infect()

" This changes the values of a LOT of options, enabling features which are not
" Vi compatible but really really nice.
set nocompatible

" Disable `safe write` for Parcel bundler
set backupcopy=yes

set ignorecase
set infercase
set smartcase
set endofline

syntax enable

set colorcolumn=80

set foldmethod=indent

" Keep all folds open when a file is opened
augroup OpenAllFoldsOnFileOpen
  autocmd!
  autocmd BufRead * normal zR
augroup END

" Save folds even if you close the file
"augroup AutoSaveFolds
  "autocmd!
  "autocmd BufWinLeave * mkview
  "autocmd BufWinEnter * silent loadview
"augroup END

augroup scroll
    au!
    au  VimEnter * :silent !synclient VertEdgeScroll=0
    au  VimLeave * :silent !synclient VertEdgeScroll=1
augroup END

" Line numbers
set number

set t_Co=256
set guifont=Hack:h14
set guioptions=
set linespace=7
set lines=30
set columns=125

colorscheme one
set background=dark

" Loads indent.vim. The result is when a file is edited its indent file is
" loaded
filetype plugin indent on

" Text width=80
set textwidth=80

" UNIX line endings
set ff=unix

" NO WRAP!
"set nowrap

" Line breaks
set linebreak

" This value allows to use the backspace character for moving the
" cursor over automatically inserted indentation and over the start/end of line.
set bs=2

" Highlight search
set hlsearch

" Indentation
set autoindent
set expandtab
set shiftwidth=2
set softtabstop=2

" There are several commands which move the cursor within the line. When you get
" to the start/end of a line then these commands will fail as you cannot go on.
" However, many users expect the cursor to be moved onto the previous/next line.
" Vim allows you to chose which commands will wrap the cursor around the line
" borders. Here I allow the cursor left/right keys as well as the 'h' and 'l'
" command to do that.
set ww=<,>,h,l

" Paste toggle
set pastetoggle=<F4>

set path+=**
set wildignore+=*/node_modules/*
set wildignore+=*/vendor/*
set wildignore+=*/.git/*
set wildmenu

" Highlight unwanted whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

" Map <leader>n to toggle NERDTree
map <leader>n :NERDTreeToggle<CR>

" Map :fw to invoke :FixWhitespace
nmap :fw :FixWhitespace<CR>
nmap :nct :!ctags -R --exclude={.git,node_modules,dist,.cache,package-lock.json,yarn.lock,package.json,.eslintrc.json,.prettierrc.json}

nmap :ex :Explore .<CR>

" Open a NERDTree automatically when vim starts up on opening a directory
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif

" NERDTree size
let g:NERDTreeWinSize=25

" Change NERDTree default arrows
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

" NERDTree show hidden files
let NERDTreeShowHidden = 1

" NERDTree ignore some files
let NERDTreeIgnore = ['DS_Store', 'node_modules', 'vendor']

" enable line numbers on NERDTree
"let NERDTreeShowLineNumbers=1
" make sure relative line numbers are used on NERDTree
"autocmd FileType nerdtree setlocal

" ctrlp show hidden files
let g:ctrlp_show_hidden = 1

" ctrlp custom ignore
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|\.git/\|vendor\|_site\|_production*'

" cli-override|file-override|prefer-file
let g:prettier#config#config_precedence = 'prefer-file'


runtime macros/matchit.vim

set directory^=$HOME/.vim/tmp//

" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" < Other Plugins, if they exist >
Plug 'fatih/vim-go'

" Use release branch (Recommend)
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Or latest tag
Plug 'neoclide/coc.nvim', {'tag': '*', 'branch': 'release'}
" Or build from source code by use yarn: https://yarnpkg.com
Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}

" Initialize plugin system
call plug#end()

" -------------------------------------------------------------------------------------------------
" coc.nvim default settings
" -------------------------------------------------------------------------------------------------

" if hidden is not set, TextEdit might fail.
set hidden
" Better display for messages
set cmdheight=2
" Smaller updatetime for CursorHold & CursorHoldI
set updatetime=300
" don't give |ins-completion-menu| messages.
set shortmess+=c
" always show signcolumns
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use `[c` and `]c` to navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use U to show documentation in preview window
nnoremap <silent> U :call <SID>show_documentation()<CR>

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

" disable vim-go :GoDef short cut (gd)
" this is handled by LanguageClient [LC]
let g:go_def_mapping_enabled = 0
