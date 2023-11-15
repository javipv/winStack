" Script Name: winStack.vim
" Description: manage a window layout configuration based on two vertical
" splits, one without horizontal splits (main window), the other with several
" horizontal splits (window stack).
" The plugin helps exchange the window on any buffer opened on a split on the stack 
" with the one on the main window (WinUnstack).
" Or move a buffer opened on the main window to the stack (WinStack).
" Quickix items can be open too on the stack or main window directly from the quickfix list .
"
" 1) Window layout with stack on the right:
" 
" ┌─────────┐──────────┐
" │         │ Stack-1  │
" │         │──────────│
" │  Main   │ Stack-2  │
" │         │──────────│
" │         │ Stack-3  │
" └─────────┘──────────┘
" 
" 2) Window layout with stack on the left:
" let g:windowStack_defaultSide = "left"
" 
" ┌──────────┐─────────┐
" │ Stack-1  │         │
" │──────────│         │
" │ Stack-2  │  Main   │
" │──────────│         │
" │ Stack-3  │         │
" └──────────┘─────────┘
"
" Copyright:   (C) 2019-2020 Javier Puigdevall Garcia
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  Javier Garcia Puigdevall <javierpuigdevall@gmail.com>
" Contributors:
"
" Dependencies:
"
" Version:      0.0.1
" Changes:
" 0.0.1 	Tue, 21 Feb 20.     JPuigdevall



"- functions -------------------------------------------------------------------
"
function! s:Error(mssg)
    echohl ErrorMsg | echom s:plugin.": ".a:mssg | echohl None
endfunction


function! s:Warn(mssg)
    echohl WarningMsg | echom a:mssg | echohl None
endfunction


" Debug function. Log message
function! s:Verbose(level,func,mssg)
    if s:verbose >= a:level
        echom "["s:plugin_name." : ".a:func." ] ".a:mssg
    endif
endfunction


" Debug function. Log message and wait user key
function! s:VerboseStop(level,func,mssg)
    if s:verbose >= a:level
        call input("[".s:plugin_name." : ".a:func." ] ".a:mssg." (press key)")
    endif
endfunction


" Set/show the log level.
" Arg1: [optional] level. set the log level
" Commands: WinStv
func! winStack#Verbose(level)
    if a:level == ""
        call s:Verbose(0, expand('<sfile>'), "Verbose level: ".s:verbose)
        return
    endif
    let s:verbose = a:level
    call s:Verbose(0, expand('<sfile>'), "Set verbose level: ".s:verbose)
endfun


function! s:Initialize()
    let s:verbose = 0
endfunction


" Get the plugin reload command
function! winStack#Reload()
    let l:pluginPath = substitute(s:plugin_path, "autoload", "plugin", "")
    let l:autoloadFile = s:plugin_path."/".s:plugin_name
    let l:pluginFile = l:pluginPath."/".s:plugin_name
    return "unlet g:loaded_winStack | so ".l:autoloadFile." | so ".l:pluginFile
endfunction


" On quickfix window extract the file, line and column on current line.
" Return: list with, file, line, column
function! s:GetQfLineInfo()
    call s:Verbose(1, expand('<sfile>'), "")

    if getwinvar(winnr(), '&syntax') != 'qf'
        call s:Error("Assert. Not a quickfix window")
        return ["","",""]
    endif

    " Get file line and column form qf line.
    "normal vf|f|y
    normal Y
    let l:fileLineCol = @"
    call s:Verbose(2, expand('<sfile>'), "qf line: ".l:fileLineCol)

    let l:list = split(l:fileLineCol,'|')
    if len(l:list) < 1
        call s:Error("File not found on quickfix line")
        return ["","",""]
    endif

    let l:file = l:list[0]
    let l:line    = 0
    let l:column  = 0

    if len(l:list) < 2
        call s:Warn("Line and column number not found on quickfix line")
    else
        let l:lineCol = l:list[1]
        let l:list    = split(l:lineCol," col ")

        if len(l:list) >= 1
            let l:line    = l:list[0]
        endif
        if len(l:list) >= 2
            let l:column  = l:list[1]
        endif
    endif
    call s:Verbose(2, expand('<sfile>'), "File:".l:file." line:".l:line." column:".l:column)
    return [l:file, l:line, l:column]
endfunction


" Arg1: side. left or right.
" Return: 0 on success, 1 on failure.
function! s:GotoWindowOposedSide(side)
    if a:side == "right"
        let l:side = "left"
    else  
        let l:side = "right"
    endif
    return s:GotoWindowSide(l:side)
endfunction


" Goto window on left or right column.
" Skip quickfix window.
" Arg1: side. left or right.
" Return: 0 on success, 1 on failure.
function! s:GotoWindowSide(side)
    call s:Verbose(1, expand('<sfile>'), "side:".a:side)

    let l:initWinNr = win_getid()

    if a:side == "right" | wincmd l 
    else  | wincmd h
    endif
    call s:Verbose(2, expand('<sfile>'), "Goto side: ".a:side." file:".expand("%"))

    if win_getid() == l:initWinNr
        "call s:Warn("Column not found on: ".a:side." side")
        return 1
    endif
    return 0
endfunction


" Goto window on top or bottom of the column.
" Skip quickfix window.
" Arg1: heigh. top ro bottom.
" Return: 0 on success, 1 on failure.
function! s:GotoWindowHeigh(heigh)
    call s:Verbose(1, expand('<sfile>'), "heigh:".a:heigh)

    let l:initWinNr = win_getid()

    while 1
        let tmpWinNr = win_getid()
        call s:Verbose(2, expand('<sfile>'), "Current winNr:".l:tmpWinNr." ".expand("%"))

        if a:heigh == "top" | wincmd k 
        else | wincmd j 
        endif
        call s:Verbose(2, expand('<sfile>'), "current file:".expand("%"))

        if win_getid() == l:tmpWinNr
            call s:Verbose(2, expand('<sfile>'), "Last window found")
            break
        endif
        if getwinvar(winnr(), '&syntax') == 'qf'
            call s:Verbose(2, expand('<sfile>'), "Qf window. Goto previous window.")
            call win_gotoid(l:tmpWinNr)
            break
        endif
        if &buftype == 'terminal'
            call s:Verbose(2, expand('<sfile>'), "Terminal window. Goto previous window.")
            call win_gotoid(l:tmpWinNr)
            break
        endif
    endwhile

    if win_getid() == l:initWinNr
        "call s:Warn("Row not found on: ".a:heigh)
        return 1
    endif
    return 0
endfunction


" If there's a column available to the left return "left"
" If there's a window available to the right, return "right"
" When there are windows availble on boths sides, ask user wich side to pick.
" Return: "left" or "right".
function! s:GetSide()
    call s:Verbose(1, expand('<sfile>'), "")
    let side = ""

    " Check if there's a window to the right.
    let initWinNr = win_getid()

    if getwinvar(winnr(), '&syntax') == 'qf'
        wincmd j 
    endif
    if &buftype == 'terminal'
        wincmd j 
    endif

    wincmd l 
    call s:Verbose(2, expand('<sfile>'), "current file:".expand("%"))
    if win_getid() != l:initWinNr
        let side .= "right"
    endif

    " Return to previous window
    call win_gotoid(l:initWinNr)

    if getwinvar(winnr(), '&syntax') == 'qf'
        " Goto upper window.
        wincmd k
    endif
    if &buftype == 'terminal'
        " Goto upper window.
        wincmd k
    endif

    " Check if there's a window to the left.
    wincmd h 
    call s:Verbose(2, expand('<sfile>'), "current file:".expand("%"))
    if win_getid() != l:initWinNr
        let side .= "left"
    endif

    " Return to previous window
    call win_gotoid(l:initWinNr)

    if l:side == ""
        "call s:Warn("Column not found neither on right or left side")
        return ""
    endif

    if l:side == "rightleft"
        if confirm("Stack to the ".g:windowStack_defaultSide." column?","&yes\n&no\n",1) == 1
            let side = g:windowStack_defaultSide
        else
            if g:windowStack_defaultSide == "right"
                let side = "left"
            else
                let side = "right"
            endif
        endif
    endif
    call s:Verbose(2, expand('<sfile>'), "side:".l:side)
    return l:side
endfunction


" Stack the current window on left or right column.
" Arg1: top or bottom
" Arg2: left or right.
func! s:StackWindow(heigh,side)
    call s:Verbose(1, expand('<sfile>'), "heigh:".a:heigh." side:".a:side)

    if a:heigh != "top" && a:heigh != "bottom"
        call s:Error("Unknown argument ".a:heigh." use top or bottom")
        return 1
    endif
    if a:side != "right" && a:side != "left"
        call s:Error("Unknown argument ".a:side." use left or right")
        return 1
    endif

    let l:initWinNr = win_getid()
    let l:stackWinName = expand("%")
    let l:stackWinContent = ""
    let l:stackBuffNr = bufnr("")

    " Save window position
    let l:winview = winsaveview()

    if s:GotoWindowSide(a:side) != 0 | return 1 | endif
    call s:GotoWindowHeigh(a:heigh)

    call s:Verbose(2, expand('<sfile>'), "Close window: ".l:stackWinName)
    silent new
    let finalWinNr = win_getid()
    call win_gotoid(l:initWinNr)
    close
    call win_gotoid(l:finalWinNr)
    execute ":buffer ". l:stackBuffNr

    " Restore window position
    call winrestview(l:winview)
    return 0
endfunc


" Unstack the current window to the left or right column.
" Arg1: top or bottom.
" Arg2: left or right.
func! s:UnstackWindow(heigh,side)
    call s:Verbose(1, expand('<sfile>'), "heigh:".a:heigh." side:".a:side)

    if a:heigh != "top" && a:heigh != "bottom"
        call s:Error("Unknown argument ".a:heigh." use top or bottom")
        return 1
    endif
    if a:side != "right" && a:side != "left"
        call s:Error("Unknown argument ".a:side." use left or right")
        return 1
    endif

     "Save stacked window's info 
    let l:stackedWinNr = win_getid()
    let l:stackWinName = expand("%")
    let l:stackWinContent = ""
    let l:stackBuffNr = bufnr("")
    let l:stackWinView = winsaveview()

    " Goto main window
    if s:GotoWindowSide(a:side) != 0 | return 1 | endif
    " Goto top/bottom window
    call s:GotoWindowHeigh(a:heigh)

     "Save main window's info 
    let mainWinNr = win_getid()
    let l:mainBuffNr = bufnr("")
    let l:mainWinView = winsaveview()

    " Move buffer on main window to stacked window
    silent execute ":buffer ". l:stackBuffNr
    " Restore window position
    call winrestview(l:stackWinView)
    " Goto stacked window
    call win_gotoid(l:stackedWinNr)

    " Open on stacked window the buffer previously on main window.
    silent execute ":buffer ". l:mainBuffNr
    " Restore window position
    call winrestview(l:mainWinView)
    " Goto main window
    call win_gotoid(l:mainWinNr)

    return 0
endfunc


" Open current qf file on main window.
" Arg1: top or bottom.
" Arg2: left or right.
func! s:QfOpenMain(heigh,side)
    call s:Verbose(1, expand('<sfile>'), "heigh:".a:heigh." side:".a:side)

    if getwinvar(winnr(), '&syntax') != 'qf'
        call s:Error("Assert. Not a quickfix window")
        return
    endif

    " Get file line and column form qf line.
    let qfInfoList = s:GetQfLineInfo()
    let l:file = l:qfInfoList[0]
    let l:line = l:qfInfoList[1]
    let l:column = l:qfInfoList[2]

    let l:qfWinNr = win_getid()

    " Goto upper window.
    wincmd k
    call s:Verbose(2, expand('<sfile>'), "Goto upperWindow: ".expand("%"))

    " Goto main window
    call s:GotoWindowSide(a:side)
    " Goto top/bottom window
    call s:GotoWindowHeigh(a:heigh)

    "call s:Verbose(2, expand('<sfile>'), "Close window: ".l:stackWinName)
     "Save main window's info 
    let mainWinNr = win_getid()
    let l:mainBuffNr = bufnr("")
    let l:mainWinView = winsaveview()

    " Goto stack column
    call s:GotoWindowOposedSide(a:side)

    if win_getid() == l:mainWinNr
        silent vertical split
    else
        call s:GotoWindowHeigh(a:heigh)
        new
    endif

    " Open on stacked window the buffer previously on main window.
    silent execute ":buffer ". l:mainBuffNr
    " Restore window position
    call winrestview(l:mainWinView)
    " Return to main window
    call win_gotoid(l:mainWinNr)

    " Open current selected qf file on the main window.
    silent execute ":edit ". l:file
    " Goto required window position
    silent exec "normal ".l:line."G"
    silent exec "normal 0".l:column."l"

    if g:windowStack_closeQuickfix == 1
        " Close the qf window
        call win_gotoid(l:qfWinNr)
        if getwinvar(winnr(), '&syntax') == 'qf'
            silent close!
        endif
        call win_gotoid(l:mainWinNr)
    endif
endfunc


" Open current qf file on stacked window.
" Arg1: top or bottom.
" Arg2: left or right.
func! s:QfOpenStacked(heigh,side)
    call s:Verbose(1, expand('<sfile>'), "heigh:".a:heigh." side:".a:side)

    if getwinvar(winnr(), '&syntax') != 'qf'
        call s:Error("Assert. Not a quickfix window")
        return
    endif

    " Get file line and column form qf line.
    let qfInfoList = s:GetQfLineInfo()
    let l:file = l:qfInfoList[0]
    let l:line = l:qfInfoList[1]
    let l:column = l:qfInfoList[2]

    let l:qfWinNr = win_getid()

    " Goto upper window.
    wincmd k
    call s:Verbose(2, expand('<sfile>'), "Goto upperWindow: ".expand("%"))

    " Goto main window
    call s:GotoWindowOposedSide(a:side)

    if win_getid() == l:qfWinNr
        call s:Warn("Column not found on: ".a:side." side")
        return
    endif

    call s:GotoWindowHeigh(a:heigh)

    " Move buffer on main window to stacked window
    silent execute "new ". l:file
    let l:newWinNr = win_getid()
    " Restore window position
    silent exec "normal ".l:line."G"
    silent exec "normal 0".l:column."l"

    if g:windowStack_closeQuickfix == 1
        " Close the qf window
        call win_gotoid(l:qfWinNr)
        if getwinvar(winnr(), '&syntax') == 'qf'
            silent close!
        endif
        call win_gotoid(l:newWinNr)
    endif
endfunc


" Stack the current window.
" Arg1: heigh, top or bottom.
" Commands: WinStack
func! winStack#stackWindow(heigh)
    call s:Verbose(1, expand('<sfile>'), "")

    let l:side = s:GetSide()
    if l:side == "" | return | endif

    if getwinvar(winnr(), '&syntax') == 'qf'
        return s:QfOpenStacked(a:heigh,l:side)
    else
        return s:StackWindow(a:heigh,l:side)
    endif

    call s:VerboseStop(1, expand('<sfile>'), "")
endfunction


" Stack the current window on left or right column.
" Arg1: heigh, top or bottom.
" Arg2: On 0, leave quickfix window open.
" Commands: WinUnstack
func! winStack#unstackWindow(heigh, closeQfFlag)
    call s:Verbose(1, expand('<sfile>'), "")

    let l:closeQuickfix = g:windowStack_closeQuickfix
    let g:windowStack_closeQuickfix = a:closeQfFlag

    let l:side = s:GetSide()
    if l:side == ""
        " Main window not found.
        if g:windowStack_defaultSide == "right"
            " Move split to main position on the left of the stack
            wincmd H
        else
            " Move split to main position on the right of the stack
            wincmd L
        endif
        return
    endif

    if getwinvar(winnr(), '&syntax') == 'qf'
        call s:QfOpenMain(a:heigh,l:side)
    else
        call s:UnstackWindow(a:heigh,l:side)
    endif

    call s:VerboseStop(1, expand('<sfile>'), "")

    let g:windowStack_closeQuickfix = l:closeQuickfix
endfunc


" Arg1: [optional] number of windows to go up.
" Commands: WinStUp
"func! winStack#stackWindowUp(n)
    "let n = 0
    "while l:n <= a:n
        "wincmd R
        "let l:n += 1
    "endwhile
"endfunc


"" Arg1: [optional] number of windows to go down.
"" Commands: WinStDown
"func! winStack#stackWindowDown(n)
    "let n = 0
    "while l:n <= a:n
        "wincmd j
        "wincmd R
        "let l:n += 1
    "endwhile
"endfunc


" Open a test tab to test the window stack functions.
" Open newtab with several splits, vertical splits and quickfix window. 
" Commands: WinStTest
func! winStack#test()
    call s:Verbose(1, expand('<sfile>'), "")

    tabnew
    let test = "Buffer1"
    silent put = l:test
    silent! exec("0file | file! ".l:test)

    vnew
    let test = "Buffer2"
    silent put = l:test
    silent! exec("0file | file! ".l:test)

    new
    let test = "Buffer3"
    silent put = l:test
    silent! exec("0file | file! ".l:test)

    new
    let test = "Buffer4"
    silent put = l:test
    silent! exec("0file | file! ".l:test)

    call setloclist(0,map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), '{"bufnr": v:val}'))
    lopen
endfunc


"- Release tools ------------------------------------------------------------
"

" Create a vimball release with the plugin files.
" Commands: Svnvba
function! winStack#NewVimballRelease()
    let text  = ""
    let text .= "plugin/winStack.vim\n"
    let text .= "autoload/winStack.vim\n"

    silent tabedit
    silent put = l:text
    silent! exec '0file | file vimball_files'
    silent normal ggdd

    let l:plugin_name = substitute(s:plugin_name, ".vim", "", "g")
    let l:releaseName = l:plugin_name."_".g:windowStack_version.".vmb"

    let l:workingDir = getcwd()
    silent cd ~/.vim
    silent exec "1,$MkVimball! ".l:releaseName." ./"
    silent exec "vertical new ".l:releaseName
    silent exec "cd ".l:workingDir
endfunction


"- initializations ------------------------------------------------------------

let  s:plugin = expand('<sfile>')
let  s:plugin_path = expand('<sfile>:p:h')
let  s:plugin_name = expand('<sfile>:t')

call s:Initialize()

