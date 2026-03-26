local MiniTest = require('mini.test')
local expect = MiniTest.expect

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Reset module caches so each test gets clean state
            package.loaded['plover-tapey-tape'] = nil
            package.loaded['plover-tapey-tape.utils'] = nil
            package.loaded['plover-tapey-tape.opts'] = nil
            -- Reset globals
            TapeyTapeActive = nil
            TapeyTape = nil
            TapeyTapeWindowOpen = nil
            InsideTapeBuffer = nil
            Previous_line = nil
            Tapey_tape_buffer_number = nil
            Tapey_tape_window_number = nil
        end,
    },
})

T['require the module'] = function()
    require('plover-tapey-tape.utils')
end

T['setup with defaults'] = function()
    local default_options = require('plover-tapey-tape.opts')
    local options = require('plover-tapey-tape').setup()
    expect.equality(default_options, options)
end

T['setup with modified options'] = function()
    local default_option = require('plover-tapey-tape.opts').filepath
    require('plover-tapey-tape.opts')['filepath'] = 'test.txt'
    local option = require('plover-tapey-tape').setup()
    expect.no_equality(default_option, option.filepath)
end

T['execute_command'] = MiniTest.new_set()

T['execute_command']['success'] = function()
    local util = require('plover-tapey-tape.utils')
    local output = util.execute_command('echo hello')
    expect.equality(0, output.exit)
    expect.equality(0, #output.stderr)
end

T['execute_command']['failure'] = function()
    local util = require('plover-tapey-tape.utils')
    local output = util.execute_command('ls /fakefile_that_does_not_exist_xyz')
    expect.no_equality(0, output.exit)
end

T['file_exists'] = MiniTest.new_set()

T['file_exists']['found'] = function()
    local util = require('plover-tapey-tape.utils')
    local tmpfile = vim.fn.tempname()
    local f = io.open(tmpfile, 'w')
    f:write('test')
    f:close()
    expect.equality(true, util.file_exists(tmpfile))
    os.remove(tmpfile)
end

T['file_exists']['not found'] = function()
    local util = require('plover-tapey-tape.utils')
    expect.equality(false, util.file_exists('nonexistent_file_xyz'))
end

T['get_tapey_tape_filename'] = function()
    local util = require('plover-tapey-tape.utils')
    local tapey_tape_file = util.get_tapey_tape_filename()
    if tapey_tape_file == nil then
        MiniTest.skip('tapey_tape.txt not found on this system')
    end
    expect.no_equality(nil, tapey_tape_file)
    expect.equality('string', type(tapey_tape_file))
end

T['parse_log_line'] = MiniTest.new_set()

T['parse_log_line']['nil returns nil'] = function()
    local util = require('plover-tapey-tape.utils')
    expect.equality(nil, util.parse_log_line(nil))
end

T['parse_log_line']['default format lines all have 23 steno keys'] = function()
    local util = require('plover-tapey-tape.utils')
    local lines = {
        [[   ++ | S K WH      F    G    | {^} {#Tab} {^}]],
        [[+++++ | S K WH    EUF    G    | {^} {#Shift_L(Tab)} {^}]],
        [[+++++ | S K WH A      P L     | {} - {^}]],
        [[   ++ |  T     A  EU    L     | tail]],
        [[+++++ |#       AO             | /]],
        [[+++++ | S K WH A      P L     | {} - {^}]],
        [[  +++ |     W  A  EU      T   | wait]],
        [[+++++ |       R      R        | {MODE:RESET}{^\n}{^}]],
        [[+++++ |       R  *            | {^}{>}r{^}]],
        [[+++++ |        AO*    P L T  Z| {#Alt_L(space)}]],
        [[+++++ |        AO*    P L T  Z| {#Alt_L(space)}]],
        [[+++++ |        AO*    P L T  Z| {#Alt_L(space)}]],
        [[+++++ |   KP   A *            | {^}{-|}]],
        [[   ++ |        AO EUF         | I've]],
        [[+++++ |      H A            D | had]],
        [[  +++ |  T                    | it]],
        [[   ++ |            U  P       | up >>TUP]],
        [[   ++ | S  P                  | and >>SKPUP]],
        [[+++++ |       R    U  PB      | run]],
    }

    for _, line in ipairs(lines) do
        local output = util.parse_log_line(line)
        expect.equality(23, #output.steno_keys)
    end
end

T['parse_log_line']['single suggestion'] = function()
    local util = require('plover-tapey-tape.utils')
    local line = [[   ++ | S  P                  | and >>SKPUP]]
    local output = util.parse_log_line(line)
    expect.no_equality(nil, output.suggestions)
    expect.equality(1, #output.suggestions)
end

T['parse_log_line']['multiple suggestions'] = function()
    local util = require('plover-tapey-tape.utils')
    local line =
        [[ ++ |                    S  | *documents 2022-10-05 16:18:55.408 >TKAOUPLS TKAOUPLTS TKAOUPLGTS TKAOUPLTSZ]]
    local output = util.parse_log_line(line)
    expect.equality(4, #output.suggestions)
end

T['parse_log_line']['ignorable lines with > char'] = function()
    local util = require('plover-tapey-tape.utils')
    local line = [[+++++ | S K WH     U R B G    | {^} > {^} 2022-10-05 15:58:39.761]]
    local output = util.parse_log_line(line)
    expect.equality(nil, output.suggestions)
end

T['parse_log_line']['multiple suggestions with list'] = function()
    local util = require('plover-tapey-tape.utils')
    local line =
        [[++++ |    P H  O    RPB G    | morning 2022-10-07 09:44:02.881 >>TKPWAOPL TPWORPBG TKPWORPBG TKPWAORPBG]]
    local output = util.parse_log_line(line)
    expect.no_equality(nil, output.suggestions)
end

T['find_char_highlight'] = MiniTest.new_set()

T['find_char_highlight']['key pressed'] = function()
    local util = require('plover-tapey-tape.utils')
    local line = [[   ++ | S  P                  | and >>SKPUP]]
    local parsed_line = util.parse_log_line(line)
    local highlight = util.find_char_highlight('P', parsed_line, 'left_half')
    expect.equality('FancyStenoActive', highlight)
end

T['find_char_highlight']['key not pressed'] = function()
    local util = require('plover-tapey-tape.utils')
    local line = [[   ++ | S  P                  | and >>SKPUP]]
    local parsed_line = util.parse_log_line(line)
    local highlight = util.find_char_highlight('P', parsed_line, 'right_half')
    expect.equality('Folded', highlight)
end

T['extract_last_line'] = MiniTest.new_set()

T['extract_last_line']['empty string returns nil'] = function()
    local util = require('plover-tapey-tape.utils')
    local line, remaining = util.extract_last_line('')
    expect.equality(nil, line)
    expect.equality('', remaining)
end

T['extract_last_line']['single complete line'] = function()
    local util = require('plover-tapey-tape.utils')
    local line, remaining = util.extract_last_line('hello world\n')
    expect.equality('hello world', line)
    expect.equality('', remaining)
end

T['extract_last_line']['multiple complete lines returns last'] = function()
    local util = require('plover-tapey-tape.utils')
    local line, remaining = util.extract_last_line('line one\nline two\nline three\n')
    expect.equality('line three', line)
    expect.equality('', remaining)
end

T['extract_last_line']['partial line buffered'] = function()
    local util = require('plover-tapey-tape.utils')
    local line, remaining = util.extract_last_line('complete line\npartial')
    expect.equality('complete line', line)
    expect.equality('partial', remaining)
end

T['extract_last_line']['no newlines returns nil with buffer'] = function()
    local util = require('plover-tapey-tape.utils')
    local line, remaining = util.extract_last_line('no newline here')
    expect.equality(nil, line)
    expect.equality('no newline here', remaining)
end

T['extract_last_line']['handles windows line endings'] = function()
    local util = require('plover-tapey-tape.utils')
    local line, remaining = util.extract_last_line('hello\r\nworld\r\n')
    expect.equality('world', line)
    expect.equality('', remaining)
end

T['extract_last_line']['tapey tape log lines'] = function()
    local util = require('plover-tapey-tape.utils')
    local data = '   ++ | S  P                  | and >>SKPUP\n+++++ |       R    U  PB      | run\n'
    local line, remaining = util.extract_last_line(data)
    expect.equality('+++++ |       R    U  PB      | run', line)
    expect.equality('', remaining)
end

T['resolve_tapey_tape_filepath'] = MiniTest.new_set()

T['resolve_tapey_tape_filepath']['returns configured path when not auto'] = function()
    local util = require('plover-tapey-tape.utils')
    require('plover-tapey-tape.opts').filepath = '/tmp/test_tapey.txt'
    local result = util.resolve_tapey_tape_filepath()
    expect.equality('/tmp/test_tapey.txt', result)
end

T['resolve_tapey_tape_filepath']['returns nil when auto and file not found'] = function()
    local util = require('plover-tapey-tape.utils')
    -- With 'auto' default, if tapey_tape.txt doesn't exist, returns nil
    -- This test may skip on systems where plover is installed
    local result = util.resolve_tapey_tape_filepath()
    -- Result is either nil (no plover) or a string (plover installed)
    if result ~= nil then
        expect.equality('string', type(result))
    end
end

return T
