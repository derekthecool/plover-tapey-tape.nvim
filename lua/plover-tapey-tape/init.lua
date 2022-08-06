-- get all lines from a file, returns an empty
-- list/table if the file does not exist
-- local function lines_from(file)
--   local lines = {}
--   for line in io.lines(file) do
--     lines[#lines + 1] = line
--   end
--   return lines
-- end

-- local f = io.open('/mnt/c/Users/Derek Lomax/AppData/Local/plover/plover/tapey_tape.txt', 'r')
-- local lines = lines_from('/mnt/c/Users/Derek Lomax/AppData/Local/plover/plover/tapey_tape.txt')
local f = io.open('/mnt/c/Users/Derek Lomax/AppData/Local/plover/plover/tapey_tape.txt')
local len = f:seek('end')
f:seek('set', len - 40)
local last_line = f:read('l')
f:close()

TapeyTape = last_line
vim.inspect('In plugin plover-tapey-tape, setting the global variable TapeyTape to: ' .. TapeyTape)
