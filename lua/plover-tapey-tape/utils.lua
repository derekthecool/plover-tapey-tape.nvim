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
  local f = io.open(name, 'r')
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

--- Function to autodetect the location of the file tapey_tape.txt. Supported on
--- windows, mac, Linux and WSL.
---@return string|nil
local function get_tapey_tape_filename()
  local tapey_tape_name = 'tapey_tape.txt'

  -- Check for known locations on window, mac, Linux and WSL Linux
  if vim.fn.has('linux') then
    local LinuxFileName = os.getenv('HOME') .. '/.config/plover/' .. tapey_tape_name
    if file_exists(LinuxFileName) then
      return LinuxFileName
    elseif vim.fn.has('wsl') then
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

  if vim.fn.has('mac') then
    local mac_filename = os.getenv('HOME')
    if mac_filename ~= nil then
      mac_filename = mac_filename .. '/Library/Application Support/plover/' .. tapey_tape_name
    end
    if file_exists(mac_filename) then
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

return {
  execute_command = execute_command,
  get_tapey_tape_filename = get_tapey_tape_filename,
}
