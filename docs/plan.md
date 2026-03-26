# Plan: Migrate to mini.test + Improve File Tailing

## Context

The plugin currently uses plenary.nvim/busted for tests (run manually via `:PlenaryBustedDirectory`) and a naive 90ms synchronous polling approach for tailing `tapey_tape.txt` (opens/closes the file handle every cycle). This plan replaces both:

1. **Tests** → mini.test with a proper `Makefile` for headless CLI execution
2. **File tailing** → libuv `fs_event` watcher with async incremental reads

---

## Phase 1: Test Infrastructure (mini.test)

### New files to create

| File | Purpose |
|------|---------|
| `scripts/minimal_init.lua` | Bootstrap test env: adds plugin + `deps/mini.nvim` to rtp, calls `require('mini.test').setup()` |
| `tests/test_utils.lua` | Migrated test suite (15 tests) using mini.test native syntax |
| `Makefile` | `deps` (clone mini.nvim), `test` (headless run), `clean` targets |

### Modifications

- **`.gitignore`** — add `deps/`
- **`lua/tests/utils_spec.lua`** — delete after migration is verified

### Test translation reference

| Busted | mini.test |
|--------|-----------|
| `describe('name', fn)` | `T = MiniTest.new_set()` |
| `it('name', fn)` | `T['name'] = function() ... end` |
| `assert.are.same(a, b)` | `MiniTest.expect.equality(a, b)` |
| `assert.are.not_same(a, b)` | `MiniTest.expect.no_equality(a, b)` |

### Test isolation

A `pre_case` hook resets `package.loaded` for all plugin modules and clears global state (`TapeyTapeActive`, `TapeyTape`, `Previous_line`, etc.) between tests.

### Portability fixes

- `execute_command` tests: use `echo hello` instead of `ls /` for cross-platform
- `file_exists` tests: use `vim.fn.tempname()` instead of hardcoded `~/.config/nvim/README.md`
- `get_tapey_tape_filename`: wrap with `MiniTest.skip()` if plover isn't installed

### Running tests

```bash
make test
# or: nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"
```

---

## Phase 2: File Tailing Refactor (libuv)

### Design: `vim.uv.new_fs_event` + async `fs_read`

Replace the timer-based polling with event-driven file watching:

1. **Watch** — `vim.uv.new_fs_event()` fires on file changes (inotify/FSEvents/ReadDirectoryChangesW)
2. **Read** — keep file descriptor open, track byte offset, read only new bytes on each event
3. **Fallback** — if `fs_event` errors, degrade to `vim.uv.new_fs_poll()` at configurable interval

### Module-level state in `utils.lua`

```lua
local watcher_state = {
    fs_event = nil,
    fd = nil,
    offset = 0,
    filepath = nil,
    line_buffer = '',  -- partial line accumulator
}
```

### New functions in `utils.lua`

- **`start_watching(filepath, on_new_line)`** — resolve path, open fd, stat for initial offset (start at EOF), create `fs_event` watcher, on change call `read_new_data()`
- **`read_new_data()`** — stat fd for current size, read `new_size - offset` bytes, extract last complete line, invoke callback via `vim.schedule_wrap`
- **`stop_watching()`** — stop + close fs_event, close fd, reset state
- **`resolve_tapey_tape_filepath()`** — extracted from `read_last_line_of_tapey_tape`, handles `auto` detection and caching

### Changes to `init.lua`

Replace the `vim.loop.new_timer()` block with:

```lua
local function start()
    TapeyTapeActive = true
    InsideTapeBuffer = false
    local utils = require('plover-tapey-tape.utils')
    local filepath = utils.resolve_tapey_tape_filepath()
    if filepath then
        utils.start_watching(filepath, function(line)
            if line ~= nil and line ~= Previous_line then
                Previous_line = line
                utils.update_display(line)
                utils.scroll_buffer_to_bottom()
            end
        end)
    end
end
```

Remove the `update()` local function entirely.

### Changes to `opts.lua`

Add:
```lua
watcher = {
    poll_fallback_interval = 500,  -- ms, used if fs_event fails
},
```

### Edge cases

- **File doesn't exist yet** — retry resolution on a slow timer (5s) until file appears
- **File truncation/rotation** — if `new_size < offset`, reset offset to 0
- **Partial lines** — buffer incomplete lines in `watcher_state.line_buffer`, emit only on `\n`
- **Multiple start() calls** — call `stop_watching()` first if already active
- **Callback safety** — all libuv callbacks that touch nvim APIs wrapped in `vim.schedule_wrap()`

---

## Implementation Order

### Step 1: Test infra (no plugin logic changes)
1. Add `deps/` to `.gitignore`
2. Create `scripts/minimal_init.lua`
3. Create `Makefile`
4. Create `tests/test_utils.lua` with all 15 migrated tests
5. Run `make test`, fix failures
6. Delete `lua/tests/utils_spec.lua`

### Step 2: File tailing refactor
7. Add `watcher` config to `opts.lua`
8. Add watcher functions to `utils.lua` (keep old `read_last_line_of_tapey_tape` temporarily)
9. Update `init.lua` to use `start_watching`/`stop_watching`
10. Manual testing with actual plover output
11. Remove old `read_last_line_of_tapey_tape`
12. Add watcher-related tests to `tests/test_utils.lua`

### Step 3: Cleanup
13. Update README.md with `make test` instructions
14. Run `stylua .` on all new/modified files
15. Final `make test`

---

## Critical Files

| File | Action |
|------|--------|
| `lua/plover-tapey-tape/utils.lua` | Major: replace file I/O, add watcher functions |
| `lua/plover-tapey-tape/init.lua` | Major: replace timer loop with fs_event callback |
| `lua/plover-tapey-tape/opts.lua` | Minor: add `watcher` config |
| `tests/test_utils.lua` | New: mini.test suite |
| `scripts/minimal_init.lua` | New: test bootstrap |
| `Makefile` | New: test runner |
| `.gitignore` | Minor: add `deps/` |
| `lua/tests/utils_spec.lua` | Delete |

## Verification

1. `make test` — all 15+ tests pass in headless neovim
2. Manual: open neovim, `require('plover-tapey-tape').setup()`, type steno strokes, verify status line updates and buffer display works
3. Manual: test `toggle`, `stop`, verify fs_event watcher cleans up (no errors on `:quit`)
4. Edge: rename/delete `tapey_tape.txt` while running — verify graceful fallback

---

## Implementation Results

All automated steps completed successfully.

### Phase 1: Test Infrastructure -- DONE
- Migrated 16 tests from plenary/busted to mini.test (native syntax)
- Created `Makefile`, `scripts/minimal_init.lua`, `tests/test_utils.lua`
- Modeled after `neotest-pester` project structure
- Deleted old `lua/tests/utils_spec.lua`
- `make test` passes 16/16

### Phase 2: File Tailing Refactor -- DONE
- Added `watcher` config to `opts.lua`
- Replaced `read_last_line_of_tapey_tape()` (sync io.open every 90ms) with:
  - `resolve_tapey_tape_filepath()` — path resolution with caching
  - `start_watching()` — `vim.uv.new_fs_event` with `fs_poll` fallback
  - `read_new_data()` — async incremental reads tracking byte offset
  - `stop_watching()` — clean handle teardown
  - `extract_last_line()` — pure function for line extraction with partial buffering
- Replaced timer-based polling in `init.lua` with event-driven watcher
- Added 9 new tests for `extract_last_line` and `resolve_tapey_tape_filepath`
- `make test` passes 25/25

### Phase 3: Cleanup -- DONE
- Added Development/Testing section to README.md
- Ran `stylua .` on all files
- Final `make test`: 25/25 pass, 0 failures

### Remaining Manual Verification
- [ ] Test with actual Plover steno output
- [ ] Test `toggle`, `stop`, verify clean shutdown
- [ ] Test file truncation/rotation edge case
