local util = require('plover-tapey-tape.utils')

describe('tapey-tape-util tests --', function()
    it('Require the module', function()
        require('plover-tapey-tape.utils')
    end)

    it('Setup testing with defaults should be equal', function()
        local default_options = require('plover-tapey-tape.opts')
        local options = require('plover-tapey-tape').setup()
        assert.are.same(default_options, options)
    end)

    it('Setup testing with defaults should be different', function()
        local default_option = require('plover-tapey-tape.opts').filepath
        require('plover-tapey-tape.opts')['filepath'] = 'test.txt'
        local option = require('plover-tapey-tape').setup()
        assert.are.not_same(default_option, option.filepath)
    end)

    it('execute_command test should match expected', function()
        local output = util.execute_command('ls /')

        assert.are.equal(0, output.exit)
        assert.are.equal(0, #output.stderr)
        assert.are.equal('home', output.stdout:match('(home)'))
    end)

    it('execute_command test should fail and have shell error', function()
        local output = util.execute_command('ls /fakefile')

        assert.are.not_same(0, output.exit)
        assert.are.not_same(0, #output.stderr)
        assert.are.equal(0, #output.stdout)
    end)

    it('file_exists should be found', function()
        local exists = util.file_exists(os.getenv('HOME') .. '/.config/nvim/README.md')
        assert.are.same(true, exists)
    end)

    it('file_exists should not be found', function()
        local exists = util.file_exists('hi')
        assert.are.same(false, exists)
    end)

    it('get_tapey_tape_filename should find log file', function()
        local tapey_tape_file = util.get_tapey_tape_filename()
        assert.are.not_same(nil, tapey_tape_file)
        assert.are.same('string', type(tapey_tape_file))
    end)

    it('parse_log_line nil, should return nil', function()
        local output = util.parse_log_line(nil)
        assert.are.same(nil, output)
    end)

    it('parse_log_line parse lines with default tapey-tape config', function()
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

        local default_options = require('plover-tapey-tape.opts')
        for index, line in ipairs(lines) do
            local output = util.parse_log_line(line)
            print(vim.inspect(output))
            assert.are.same(23, #output.steno_keys)
        end
    end)

    it('parse_log_line capture single suggestion', function()
        local line = [[   ++ | S  P                  | and >>SKPUP]]
        local output = util.parse_log_line(line)
        print(vim.inspect(output))
        assert.are.not_same(nil, output.suggestions)
        assert.are.same(1, #output.suggestions)
    end)

    it('parse_log_line capture multiple suggestions', function()
        local line =
            [[ ++ |                    S  | *documents 2022-10-05 16:18:55.408 >TKAOUPLS TKAOUPLTS TKAOUPLGTS TKAOUPLTSZ]]
        local output = util.parse_log_line(line)
        print(vim.inspect(output))
        assert.are.same(4, #output.suggestions)
    end)

    it('parse_log_line capture ignorable lines with a > char', function()
        local lines = {
            [[+++++ | S K WH     U R B G    | {^} > {^} 2022-10-05 15:58:39.761]],
        }

        for _, line in ipairs(lines) do
            local output = util.parse_log_line(line)
            print(vim.inspect(output))
            assert.are.same(nil, output.suggestions)
        end
    end)

    it('parse_log_line capture multiple suggestions with a list', function()
        local lines = {
            [[++++ |    P H  O    RPB G    | morning 2022-10-07 09:44:02.881 >>TKPWAOPL TPWORPBG TKPWORPBG TKPWAORPBG]],
        }

        for _, line in ipairs(lines) do
            local output = util.parse_log_line(line)
            print(vim.inspect(output))
            assert.are.not_same(nil, output.suggestions)
        end
    end)

    it('find_char_highlight highlight for key pressed', function()
        local line = [[   ++ | S  P                  | and >>SKPUP]]
        local parsed_line = util.parse_log_line(line)
        local highlight = util.find_char_highlight('P', parsed_line, 'left_half')

        -- Check to make sure the key is highlighted in the way that means it was pressed
        assert.are.same('FancyStenoActive', highlight)
    end)

    it('find_char_highlight highlight for key not pressed', function()
        local line = [[   ++ | S  P                  | and >>SKPUP]]
        local parsed_line = util.parse_log_line(line)
        local highlight = util.find_char_highlight('P', parsed_line, 'right_half')

        -- Check to make sure the key is highlighted in the way that means it was pressed
        assert.are.same('Folded', highlight)
    end)

    --
end)
