" XXX wtf does bang mean in this context?

" XXX I don't understand the rele:w

let ui#skip = 'synIDattr(synID(line("."),col("."),1),"name") =~? "comment\\|string\\|char\\|regexp"'
let ui#open = '[[{(]'
let ui#close = '[]})]'

if !exists('s:qffiles')
  let s:qffiles = {}
endif

function! s:buf() abort
  if exists('s:input')
    return s:input
  elseif has_key(s:qffiles, expand('%:p'))
    return s:qffiles[expand('%:p')].buffer
  else
    return '%'
  endif
endfunction

function! s:buffer_path(...) abort
  let buffer = a:0 ? a:1 : s:buf()
  if getbufvar(buffer, '&buftype') =~# '^no'
    return ''
  endif
  let path = substitute(fnamemodify(bufname(buffer), ':p'), '\C^zipfile:\(.*\)::', '\1/', '')
  for dir in ui#path(buffer)
    if dir !=# '' && path[0 : strlen(dir)-1] ==# dir && path[strlen(dir)] =~# '[\/]'
      return path[strlen(dir)+1:-1]
    endif
  endfor
  return ''
endfunction

function! s:path_extract(path)
  let path = []
  if a:path =~# '\.jar'
    for elem in split(substitute(a:path, ',$', '', ''), ',')
      if elem ==# ''
        let path += ['.']
      else
        let path += split(glob(substitute(elem, '\\\ze[\\ ,]', '', 'g'), 1), "\n")
      endif
    endfor
  endif
  return path
endfunction

function! ui#path(...) abort
  let buf = a:0 ? a:1 : s:buf()
  " for repl in s:repls
  "   if s:includes_file(fnamemodify(bufname(buf), ':p'), repl.path())
  "     return repl.path()
  "   endif
  " endfor
  return s:path_extract(getbufvar(buf, '&path'))
endfunction

function! ui#namespace(code) abort
  " XXX works for src + other folders e.g test + any def'd source dirs e.g dev
  let filename = expand('%:p')
  if filename =~ 'src'
    let namespace =  split(filename, 'src')[-1]
  else
    let namespace = split(filename, 'test')[-1]
  endif
  let namespace = split(namespace, '/')
  let namespace = join(namespace, '.')
  let namespace = substitute(namespace, '.clj\(s\)\=', '', '')
  let namespace = substitute(namespace, '_', '-', 'g')
  let namespace = '(ns ' . namespace . ")\n\n"
  return namespace . a:code
endfunction

" XXX pass ns if available at the top of the file
" XXX :Require loads the current file
function! ui#eval_input_handler(line1, line2, count, args) abort
  let options = {}
  if a:args !=# '' " if :Eval <statement>
    let expr = a:args
  else
    if a:count ==# 0 " what?!? maybe press 3:Eval?
      let [start_line, start_col] = ui#current_sexp_position('bcrn')
      let [end_line, end_col] = ui#current_sexp_position('rn')
      if !start_line && !end_start
        let [start_line, start_col] = ui#current_sexp_position('brn')
        let [end_line, end_col] = ui#current_sexp_position('crn')
      endif
      while col1 > 1 && getline(line1)[col1-2] =~# '[#''`~@]'
        let col1 -= 1
      endwhile
    else
      let start_line = a:line1
      let end_line = a:line2
      let start_col = 1
      let end_col = strlen(getline(end_line))
    endif
    if !start_line || !end_line
      return ''
    endif
    let options.file_path = s:buffer_path()
    if expand('%:e') ==# 'cljs'
      "leading line feed don't work on cljs repl
      let expr = ''
    else
      let expr = repeat("\n", start_line-1).repeat(" ", start_col-1)
    endif
    if start_line == end_line
      let expr .= getline(start_line)[start_col-1 : end_col-1]
    else
      let expr .= getline(start_line)[start_col-1 : -1] . "\n"
            \ . join(map(getline(start_line+1, end_line-1), 'v:val . "\n"'))
            \ . getline(end_line)[0 : end_col-1]
    endif
  endif
  call link#run_background_command(ui#namespace(expr))
endfunction
