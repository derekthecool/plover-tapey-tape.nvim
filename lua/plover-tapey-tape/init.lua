-- get all lines from a file, returns an empty
-- list/table if the file does not exist
local function lines_from(file)
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

-- local f = io.open('/mnt/c/Users/Derek Lomax/AppData/Local/plover/plover/tapey_tape.txt', 'r')
local lines = lines_from('/mnt/c/Users/Derek Lomax/AppData/Local/plover/plover/tapey_tape.txt')

TapeyTape = lines[#lines]
vim.inspect('In plugin plover-tapey-tape, setting the global variable TapeyTape to: ' .. TapeyTape)
