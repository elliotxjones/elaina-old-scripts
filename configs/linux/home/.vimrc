set nocompatible

" Load plugins first so vimrc configs take precedent.
" NERDTree config {{{
let NERDTreeQuitOnOpen = 1
let NERDTreeAutoDeleteBuffer = 1
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1

silent! nmap <C-p> :NERDTreeToggle<CR>
silent! map <F3> :NERDTreeFind<CR>

let g:NERTreeMapActivateNode="<F3>"
let g:NERDTreeMapPreview="<F4>"

nmap xecute "NERDTree"

" }}}
" Gruvbox (colorscheme) config {{{
syntax on
set background=dark

let g:gruvbox_transparent_bg = '1'
let g:gruvbox_bold = '1'
let g:gruvbox_italic = '1'

colorscheme gruvbox

nnoremap <silent> [oh :call gruvbox#hls_show()<CR>
nnoremap <silent> ]oh :call gruvbox#hls_hide()<CR>
nnoremap <silent> coh :call gruvbox#hls_toggle()<CR>

nnoremap * :let @/ = ""<CR>:call gruvbox#hls_show()<CR>*
nnoremap / :let @/ = ""<CR>:call gruvbox#hls_show()<CR>/
nnoremap ? :let @/ = ""<CR>:call gruvbox#hls_show()<CR>?
" }}}
" GitGutter Colors {{{
let g:gitgutter_override_sign_column_highlight = 0
highlight clear SignColumn
highlight GitGutterAdd ctermfg=2 ctermbg=black
highlight GitGutterChange ctermfg=3 ctermbg=black
highlight GitGutterDelete ctermfg=1 ctermbg=black
highlight GitGutterChangeDelete ctermfg=4 ctermbg=black
" }}}

" Configs from Jason {{{
" automatically show matching brackets. works like it does in bbedit.
set showmatch                   
" Set auto-indenting on for programming
set ai
"" Show the current mode
"set showmode
" Better command line completion
set wildmode=list:longest,longest:full

"" Show EOL type and last modified timestamp, right after the filename
"" Set the statusline...
"" ...filename relative to current $PWD
"set statusline=%f               
"" ...help file flag
"set statusline+=%h              
"" ...modified flag
"set statusline+=%m              
"" ...readonly flag
"set statusline+=%r              
"" ...fileformat [unix]/[dos] etc...
"set statusline+=\ [%{&ff}]      
"" ...last modified timestamp
"set statusline+=\ (%{strftime(\"%H:%M\ %d/%m/%Y\",getftime(expand(\"%:p\")))})  
"" ...Rest: right align
"set statusline+=%=              
"" ...position in buffer: linenumber, column, virtual column
"set statusline+=%l,%c%V         
"" ...position in buffer: Percentage
"set statusline+=\ %P            
" }}}

" Fix for starting in replace mode.
set t_u7=
" Use at least 256 colors.
set t_co=256

" Disable arrow key navigation.
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" Disable accidental termination.
"     ctrl + z
"     fn + w
noremap <C-z> <Nop>
noremap <f> <Nop>

" Set Proper Tabs
set tabstop=4
set shiftwidth=4
set smarttab
set autoindent
set expandtab

" Always display the status line
set laststatus=2

" Show linenumbers
set number
set ruler

" Highlight config
"highlight LineNr ctermfg=lightgrey
highlight LineNr ctermfg=darkgrey
highlight Folded ctermbg=NONE
highlight Normal guibg=NONE ctermbg=NONE
set cursorline
highlight CursorLineNR ctermbg=None cterm=bold
highlight CursorLine ctermbg=None
set fillchars+=vert:\ 
highlight VertSplit ctermfg=None ctermbg=None
" Use marker as fold method
set foldmethod=marker
set foldtext=MyFoldText()

" Functions
function! MyFoldText()
    let line = getline(v:foldstart)
    let folded_line_num = v:foldend - v:foldstart
    let line_text = substitute(line, '^"{\+', '', 'g')
    let fillcharcount = &textwidth - len(line_text) - len(folded_line_num)
    return '+'. repeat('-', 4) . line_text . repeat('.', fillcharcount) . ' (' . folded_line_num . ' L)'
endfunction

