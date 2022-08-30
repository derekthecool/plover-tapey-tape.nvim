---Setup function, takes default values from the module plover-tapey-tape.opts
---@param user_opts table|nil
---@return table
local function setup(user_opts)
  if user_opts ~= nil then
    for k, v in pairs(user_opts) do
      require('plover-tapey-tape.opts')[k] = v
    end
  end

  require('plover-tapey-tape').start()

  -- Return config table
  return (require('plover-tapey-tape.opts'))
end

-- Helpful command to run process and get exit code, stdout, and stderr
-- https://stackoverflow.com/a/42644964
---@param command string
---@return table { exit: number, stdout: string|nil, stderr: string|nil }
local function execute_command(command)
  local tmpfile = os.tmpname()
  local exit = os.execute(command .. ' > ' .. tmpfile .. ' 2> ' .. tmpfile .. '.err')

  local stdout_file = io.open(tmpfile)
  local stdout = ''
  if stdout_file then
    stdout = stdout_file:read('*all')
    stdout_file:close()
  end

  local stderr_file = io.open(tmpfile .. '.err')
  local stderr = ''
  if stderr_file then
    stderr = stderr_file:read('*all')
    stderr_file:close()
  end

  return {
    exit = exit,
    stdout = stdout,
    stderr = stderr,
  }
end

--- Function to check if a file exists - from stackoverflow: https://stackoverflow.com/a/4991602
--- @return boolean
local function file_exists(name)
  if type(name) == 'string' then
    local f = io.open(name, 'r')
    if f ~= nil then
      io.close(f)
      return true
    else
      return false
    end
  else
    -- Return false if type is not a string
    error("If function file_exists, expected argument 'name' to be a string, got: "  .. type(name))
    return false
  end
end

--- Function to autodetect the location of the file tapey_tape.txt. Supported on
--- windows, mac, Linux and WSL.
local function get_tapey_tape_filename()
  local tapey_tape_name = 'tapey_tape.txt'

  -- Check for known locations on window, mac, Linux and WSL Linux
  if vim.fn.has('linux') then
    local home = os.getenv('HOME')
    if home ~= nil then
      local LinuxFileName = home .. '/.config/plover/' .. tapey_tape_name
      if LinuxFileName ~= nil and file_exists(LinuxFileName) then
        return LinuxFileName
      end

      if vim.fn.has('wsl') then
        local output = execute_command([[powershell.exe -noprofile -command '$env:LOCALAPPDATA']])
        if output.exit == 0 and output.stdout ~= nil then
          output.stdout, _ = string.gsub(output.stdout, '\r\n', '')

          -- Create the file path and do necessary conversions
          local wsl_filename = output.stdout .. '/plover/plover/' .. tapey_tape_name
          wsl_filename = wsl_filename:gsub('C:', '/mnt/c')
          wsl_filename = wsl_filename:gsub('\\', '/')
          if wsl_filename ~= nil and file_exists(wsl_filename) then
            return wsl_filename
          end
        end
      end
    end
  end

  if vim.fn.has('mac') then
    local mac_filename = os.getenv('HOME')
    if mac_filename ~= nil then
      mac_filename = mac_filename .. '/Library/Application Support/plover/' .. tapey_tape_name
    end
    if mac_filename ~= nil and file_exists(mac_filename) then
      return mac_filename
    end
  end

  if vim.fn.has('win32') or vim.fn.has('win64') then
    -- TODO: do not can cat the value of os.getenv
    local windows_filename = os.getenv('LOCALAPPDATA')
    if windows_filename ~= nil then
      windows_filename = windows_filename .. '\\plover\\plover\\' .. tapey_tape_name
    end

    if windows_filename ~= nil and file_exists(windows_filename) then
      return windows_filename
    end
  end

  vim.notify('Could not autodetect the file location of ' .. tapey_tape_name, 'WARN')
  return nil
end

local function detect_tapey_tape_line_width()
  local filename = get_tapey_tape_filename()
  if filename ~= nil then
    if file_exists(filename) then
      local file = io.open(filename)
      local maximum_line_length = 0
      for _ = 1, 100 do
        local line = file:read('l')
        if #line > maximum_line_length then
          maximum_line_length = #line
        end
      end

      file:close()
      return maximum_line_length
    end
  end

  -- Return a sensible default if auto detect does not work
  return 50
end

local function block_auto_change_directory(mode)
  if type(mode) == string then
    if mode == 'start' then
      -- Handle vim-rooter
      if vim.g.loaded_rooter ~= nil then
        vim.g.rooter_manual_only = 1
        vim.cmd([[RooterToggle]])
      end

      -- Make sure autochdir is off
      vim.go.autochdir = false
    elseif mode == 'stop' then
      -- TODO: reset vim rooter and autochdir if needed
      if vim.g.loaded_rooter ~= nil then
        vim.g.rooter_manual_only = 0
        vim.cmd([[Rooter]])
      end
    end
  end
end

return {
  setup = setup,
  execute_command = execute_command,
  get_tapey_tape_filename = get_tapey_tape_filename,
  detect_tapey_tape_line_width = detect_tapey_tape_line_width,
  block_auto_change_directory = block_auto_change_directory,
}
