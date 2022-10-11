# plover-tapey-tape.nvim

A neovim plugin to help display your latest output from the
[plover tapey tape](https://github.com/rabbitgrowth/plover-tapey-tape)
[Plover](https://github.com/openstenoproject/plover) stenography
plugin.

## Plugin Modes

There are two modes that this plugin can work with:

1. Status line showing the last line of output
2. Buffer split showing live updates and more than one line of output

## Install

Requires neovim version 0.8.0

### Install With Packer

```lua
use('derekthecool/plover-tapey-tape.nvim')
```

### install With Vim Plug

```vim
Plug 'derekthecool/plover-tapey-tape.nvim'
```

## Screenshots

![Status line and vertical split](./images/plover-tapey-tape-demo1.jpg)

[![asciicast](https://asciinema.org/a/kMIty8IZvSYhbVaaeKG8DbBqr.svg)](https://asciinema.org/a/kMIty8IZvSYhbVaaeKG8DbBqr)

## Implemented Features

- [x] Enable auto discovery of tapey-tape log file. Supports Linux, WSL,
      Windows, Mac.
- [x] Draw a steno keyboard in realtime that show your keys highlighted
- [x] Show notifications for suggestions
- [x] Autocommand to close file watcher when neovim is closing
- [x] Autocommand to disable autoscrolling when inside tapey-tape log buffer
- [x] Autocommand to enable autoscrolling when outside tapey-tape log buffer
