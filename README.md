# winStack

Manage window splits as a main window and a stack of splits on the side.

Previously on: https://www.vim.org/scripts/script.php?script_id=5891

Based on a window layout configuration with two vertical splits, one without horizontal splits (main window), the other with several horizontal splits (window stack).

1) Window layout with stack on the right:

| Main | Stack |
| --- | --- |
|     | Window 2 |
| Window 1 | Window 3 |
|     | Window 4 |

3) Window layout with stack on the left:
let g:windowStack_defaultSide = "left"


| Stack | Main |
| --- | --- |
| Window 1 |  |
| Window 2 | Window 4 |
| Window 3 | |

The plugin helps moving a buffer to the main window, add it to the window stack as a new split, or exchange buffers between stack tnd main window.

Quickix items can be opened too on the stack or main window directly from the quickfix list .

Recomended .vimrc mappings:
nmap <unique> <F5> :WinUnstack<CR>
nmap <unique> <F8> :WinStack<CR>

## Commands:

:WinStack, <leader>ws or <F5>
Stack a window, move it to the bottom of the window stack.

:WinUnstack, <leader>wu or <F8>
Unstack a window, move it to the main window split.

:WinStTest
Open an example window layout to test the commands.
 
## Install details
Simplest method:
- Just unzip to your .vim folder.

Plugin manager:
- Either vim-pathogen or Vundle are recommended.
