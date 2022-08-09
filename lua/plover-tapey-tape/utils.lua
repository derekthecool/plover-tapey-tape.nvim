M = {}

-- Helpful command to run process and get exit code, stdout, and stderr
-- https://stackoverflow.com/a/42644964
M.execute_command = function(command)
  local tmpfile = os.tmpname()
  local exit = os.execute(command .. ' > ' .. tmpfile .. ' 2> ' .. tmpfile .. '.err')

  local stdout_file = io.open(tmpfile)
  local stdout = stdout_file:read('*all')

  local stderr_file = io.open(tmpfile .. '.err')
  local stderr = stderr_file:read('*all')

  stdout_file:close()
  stderr_file:close()

  return exit, stdout, stderr
end

M.get_tapey_tape_filename = function()
  print('/mnt/c/Users/Derek\\ Lomax/AppData/Local/plover/plover/tapey_tape.txt')
end

return M
