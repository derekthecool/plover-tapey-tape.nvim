# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Neovim plugin for displaying output from [plover-tapey-tape](https://github.com/rabbitgrowth/plover-tapey-tape), a [Plover](https://github.com/openstenoproject/plover) stenography plugin. It reads the `tapey_tape.txt` log file and provides two display modes:

1. **Status line** — exposes a global `TapeyTape` variable with the latest steno stroke for use in lualine or custom statuslines
2. **Buffer split** — live-updating window with scrolling log output and a virtual steno keyboard overlay drawn via extmarks

Requires neovim >= 0.8.0.

## Architecture

- **`lua/plover-tapey-tape/init.lua`** — Public API (`setup`, `start`, `stop`, `toggle`). Runs a `vim.loop` timer (90ms interval) that polls the tapey-tape log file and triggers display updates.
- **`lua/plover-tapey-tape/opts.lua`** — Default configuration table. `setup()` merges user options into this table in-place.
- **`lua/plover-tapey-tape/utils.lua`** — Core logic: file I/O (`read_last_line_of_tapey_tape`, `get_tapey_tape_filename` with cross-platform auto-detection for Linux/WSL/Mac/Windows), log line parsing (`parse_log_line`), window/buffer management (`open_window`, `close_window`, `scroll_buffer_to_bottom`), and steno keyboard rendering via extmarks (`draw_steno_keyboard_extmark`, `find_char_highlight`).
- **`lua/plover-tapey-tape/steno-keyboard-layout.lua`** — Static data: steno keyboard layout tables (left/right halves + row borders) used for the virtual keyboard overlay.
- **`lua/tests/utils_spec.lua`** — Tests using [busted](https://olivinelabs.com/busted/) (lua test framework, typically run via [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) test harness).

### Key globals

The plugin uses several global variables for state: `TapeyTapeActive`, `TapeyTape`, `TapeyTapeWindowOpen`, `InsideTapeBuffer`, `Previous_line`, `Tapey_tape_buffer_number`, `Tapey_tape_window_number`.

## Commands

### Formatting

```bash
stylua .
```

Config in `.stylua.toml`: 120 col width, 4-space indentation, single quotes, Unix line endings.

### Testing

Tests use busted via plenary.nvim. From neovim:

```vim
:PlenaryBustedDirectory lua/tests/
```

## Tapey-Tape Log Format

Lines follow this pattern: `strokes | steno_keys | translation [timestamp] [>>suggestions]`

The steno key capture between `|` delimiters is always 23 characters wide. Suggestions appear after `>>` at end of line.
