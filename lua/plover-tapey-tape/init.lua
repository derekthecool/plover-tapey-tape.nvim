local utils = require('plover-tapey-tape.utils')
local tapey_tape_file = utils.get_tapey_tape_filename()

-- TODO
-- Add close function: this will need to close the open buffer and stop the the watching
-- Add autocommand to run the stop function if the buffer is closed without running command
-- Add setup function with config options

local function update()
  -- Using normal file read
  local tapey_tape_filename_in_update = tapey_tape_file
  if not tapey_tape_filename_in_update then
    return
  end
  local tapey_tape_file_in_update = io.open(tapey_tape_filename_in_update)

  -- Go to end of the file and then backwards by an offset
  tapey_tape_file_in_update:seek('end', -200)
  local line = ''
  for _ = 1, 10 do
    local current_line = tapey_tape_file_in_update:read('l')
    if current_line then
      current_line = current_line:match('(|.*|)')
      line = current_line
    else
      break
    end
  end
  if tapey_tape_file_in_update then
    tapey_tape_file_in_update:close()
  end

  TapeyTape = line
end

local function open_tapey_tape()
  local current_window = vim.api.nvim_get_current_win()

  local tapey_tape_file_in_open_tapey_tape = io.open(tapey_tape_file)
  if not tapey_tape_file_in_open_tapey_tape then
    return
  end

  vim.cmd([[split ]] .. tapey_tape_file)
  local height = 3
  tapey_tape_buffer_number = vim.api.nvim_win_get_buf(0)
  tapey_tape_window_number = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(tapey_tape_window_number, height)
  watch_tapey_tape_for_changes(tapey_tape_buffer_number, tapey_tape_file)
  vim.api.nvim_set_current_win(current_window)
end

local w = vim.loop.new_fs_poll()

local function on_change(bufNr, filePath)
  vim.api.nvim_command('checktime ' .. bufNr)
  w:stop()
  watch_tapey_tape_for_changes(bufNr, filePath)
  -- Lua API method to jump to end of file
  if tapey_tape_window_number ~= nil and tapey_tape_buffer_number ~= nil then
    vim.api.nvim_win_set_cursor(
      tapey_tape_window_number,
      { vim.api.nvim_buf_line_count(tapey_tape_buffer_number), 0 }
    )
  end
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

local function stop()
  TapeyTape = nil
end

return {
  start = start,
  stop = stop,
  open = open_tapey_tape,
  setup = utils.setup,
}
