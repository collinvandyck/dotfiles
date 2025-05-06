" Have j and k navigate visual lines rather than logical ones
nmap j gj
nmap k gk

" Yank to system clipboard
set clipboard=unnamed

exmap logcursor jscommand { console.log(editor.getCursor()); }
exmap yankall jscommand {navigator.clipboard.writeText(editor.getValue());}
exmap back obcommand app:go-back
exmap forward obcommand app:go-forward

imap jk <Esc>

nmap <C-i> :forward<CR>
nmap <C-o> :back<CR>
nmap <F9> :nohl
nmap <F8> :yankall<CR>

