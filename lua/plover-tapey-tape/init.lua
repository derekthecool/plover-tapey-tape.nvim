local utils = require('plover-tapey-tape.utils')

-- TODO
-- Add close function
-- Get autodetection of text file for Linux, windows, and WSL.

local function update()
  -- Using normal file read
  local tapey_tape_file = io.open('/mnt/c/Users/Derek Lomax/AppData/Local/plover/plover/tapey_tape.txt', 'r')
  -- Go to end of the file and then backwards by an offset
  tapey_tape_file:seek('end', -200)
  local line = ''
  for _ = 1, 10 do
    local current_line = tapey_tape_file:read('l')
    if current_line then
      current_line = current_line:match('(|.*|)')
      line = current_line
    else
      break
    end
  end
  tapey_tape_file:close()

  TapeyTape = line
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
      if tapey_tape_window_number ~= nil then
        vim.api.nvim_win_set_cursor(tapey_tape_window_number, { vim.api.nvim_buf_line_count(0), 0 })
      end
      update()
    end)
  )
end

return {
  update = update,
  start = start,
  open = open_tapey_tape,
}
