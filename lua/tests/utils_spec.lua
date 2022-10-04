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
        local util = require('plover-tapey-tape.utils')
        local output = util.execute_command('ls /')

        assert.are.equal(0, output.exit)
        assert.are.equal(0, #output.stderr)
        assert.are.equal('home', output.stdout:match('(home)'))
    end)

    it('execute_command test should fail and have shell error', function()
        local util = require('plover-tapey-tape.utils')
        local output = util.execute_command('ls /fakefile')

        assert.are.not_same(0, output.exit)
        assert.are.not_same(0, #output.stderr)
        assert.are.equal(0, #output.stdout)
    end)

    it('file_exists should be found', function()
        local util = require('plover-tapey-tape.utils')
        local exists = util.file_exists(os.getenv('HOME') .. '/.config/nvim/README.md')
        assert.are.same(true, exists)
    end)

    it('file_exists should not be found', function()
        local util = require('plover-tapey-tape.utils')
        local exists = util.file_exists('hi')
        assert.are.same(false, exists)
    end)

    it('get_tapey_tape_filename should find log file', function()
        local util = require('plover-tapey-tape.utils')
        local tapey_tape_file = util.get_tapey_tape_filename()
        assert.are.not_same(nil, tapey_tape_file)
        assert.are.same('string', type(tapey_tape_file))
    end)
end)
