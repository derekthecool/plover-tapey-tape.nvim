-- TODO
-- Add close function
-- Get autodetection of text file for Linux, windows, and WSL.
local function update()
  -- Using popen
  local handle = io.popen('tail -n1 /mnt/c/Users/Derek\\ Lomax/AppData/Local/plover/plover/tapey_tape.txt')
  local result = handle:read('*l')
  handle:close()
  result = result:match('(|.*|)')
  TapeyTape = result
  -- vim.inspect('In plugin plover-tapey-tape, setting the global variable TapeyTape to: ' .. TapeyTape)
end

local function open_tapey_tape()
  local current_window = vim.api.nvim_get_current_win()
  local filename = '/mnt/c/Users/Derek\\ Lomax/AppData/Local/plover/plover/tapey_tape.txt'
  vim.cmd([[split ]] .. filename)
  local height = 3
  tapey_tape_buffer_number = vim.api.nvim_win_get_buf(0)
  tapey_tape_window_number = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(tapey_tape_window_number, height)
  watch_tapey_tape_for_changes(tapey_tape_buffer_number, filename)
  vim.api.nvim_set_current_win(current_window)
end

local w = vim.loop.new_fs_poll()

local function on_change(bufNr, filePath)
  vim.api.nvim_command('checktime ' .. bufNr)
  w:stop()
  watch_tapey_tape_for_changes(bufNr, filePath)
  -- Lua API method to jump to end of file
  vim.api.nvim_win_set_cursor(tapey_tape_window_number, { vim.api.nvim_buf_line_count(tapey_tape_buffer_number), 0 })
end

function watch_tapey_tape_for_changes(bufNr, filePath)
  w:start(
    filePath,
    1000,
    vim.schedule_wrap(function(...)
      on_change(bufNr, filePath)
    end)
  )
end

local function start()
  -- Starting timer in neovim : https://stackoverflow.com/questions/68598026/running-async-lua-function-in-neovim
  local timer = vim.loop.new_timer()
  timer:start(
    0,
    30,
    vim.schedule_wrap(function()
      update()
      vim.api.nvim_win_set_cursor(tapey_tape_window_number, { vim.api.nvim_buf_line_count(0), 0 })
    end)
  )
end

return {
  update = update,
  start = start,
  open = open_tapey_tape,
}
