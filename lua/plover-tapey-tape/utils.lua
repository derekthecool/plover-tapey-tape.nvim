local opts = require('plover-tapey-tape.opts')

---Setup function, takes default values from the module plover-tapey-tape.opts
---@param user_opts table|nil
---@return table
local function setup(user_opts)
    if user_opts ~= nil then
        -- TODO: error check widths and heights and send warnings
        for k, v in pairs(user_opts) do
            require('plover-tapey-tape.opts')[k] = v
        end
    end

    local group = vim.api.nvim_create_augroup('plover-tapey-tape', { clear = true })

    -- Create autocommand to stop the updating and avoid shutdown errors
    vim.api.nvim_create_autocmd('VimLeavePre', {
        pattern = { '*' },
        callback = function()
            require('plover-tapey-tape').stop()
        end,
        group = group,
    })

    -- Close neovim when tape buffer is the only remaining buffer
    vim.api.nvim_create_autocmd('BufEnter', {
        nested = true,
        callback = function()
            if #vim.api.nvim_list_wins() == 1 and vim.api.nvim_buf_get_name(0):match('TapeyTape') ~= nil then
                vim.cmd('quit')
            end
        end,
        group = group,
    })

    -- Event to enable autoscroll when inside tape buffer
    vim.api.nvim_create_autocmd('BufEnter', {
        pattern = 'TapeyTape',
        callback = function()
            InsideTapeBuffer = true
        end,
        group = group,
    })

    -- Event to disable autoscroll when not inside tape buffer
    vim.api.nvim_create_autocmd('BufLeave', {
        pattern = 'TapeyTape',
        callback = function()
            InsideTapeBuffer = false
        end,
        group = group,
    })

    require('plover-tapey-tape').start()

    vim.api.nvim_set_hl(0, 'FancyStenoBorder', { fg = '#6c25be', bg = '#39028d' })
    vim.api.nvim_set_hl(0, 'FancyStenoActive', { fg = '#222222', bg = '#22ffff', bold = true, italic = true })
    vim.api.nvim_set_hl(0, 'FancyStenoInactive', { bg = '#000000' })

    -- Return config table
    return (require('plover-tapey-tape.opts'))
end

local function read_last_line_of_tapey_tape()
    local tapey_tape_file = ''

    if opts.filepath == 'auto' then
        tapey_tape_file = require('plover-tapey-tape.utils').get_tapey_tape_filename()
        if require('plover-tapey-tape.utils').file_exists(tapey_tape_file) then
            require('plover-tapey-tape.opts').filepath = tapey_tape_file
        end
    else
        tapey_tape_file = opts.filepath
    end

    if not tapey_tape_file then
        return
    end

    local tapey_tape_file_handle = io.open(tapey_tape_file)

    if not tapey_tape_file_handle then
        return
    end

    -- Go to end of the file and then backwards by an offset
    tapey_tape_file_handle:seek('end', -200)
    local line = ''
    for _ = 1, 10 do
        local current_line = tapey_tape_file_handle:read('l')
        if current_line then
            current_line = current_line
            if current_line ~= nil then
                line = current_line
            end
        else
            break
        end
    end

    if tapey_tape_file_handle then
        tapey_tape_file_handle:close()
    end

    return line
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
        error('In function file_exists, expected argument \'name\' to be a string, got: ' .. type(name))
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
        local windows_filename = os.getenv('LOCALAPPDATA')
        if windows_filename ~= nil then
            windows_filename = windows_filename .. '\\plover\\plover\\' .. tapey_tape_name
        end

        if windows_filename ~= nil and file_exists(windows_filename) then
            return windows_filename
        end
    end

    vim.notify(
        'Could not autodetect the file location of ' .. tapey_tape_name,
        'WARN',
        { title = 'plover-tapey-tape.nvim' }
    )
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
            return maximum_line_length + 10
        end
    end

    -- Return a sensible default if auto detect does not work
    return 50
end

local function scroll_buffer_to_bottom()
    if InsideTapeBuffer then
        return
    end

    local function win_exists(win_number)
        local found = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if win == win_number then
                found = true
            end
        end
        return found
    end

    if Tapey_tape_window_number ~= nil and win_exists(Tapey_tape_window_number) then
        vim.api.nvim_win_set_cursor(
            Tapey_tape_window_number,
            { vim.api.nvim_buf_line_count(Tapey_tape_buffer_number), 0 }
        )
    end
end

local function open_window()
    TapeyTapeWindowOpen = true

    local utils = require('plover-tapey-tape.utils')

    local buffer_name = 'TapeyTape'

    local buffer_exists = false
    for _, value in pairs(vim.fn.getbufinfo()) do
        local name_adjust = value.name:match(buffer_name)

        if name_adjust ~= nil then
            buffer_exists = true
        end
    end

    if not buffer_exists then
        Tapey_tape_buffer_number = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(Tapey_tape_buffer_number, buffer_name)
    end

    local open_method = opts.open_method

    -- TODO: make more DRY
    if open_method == 'vsplit' then
        vim.api.nvim_cmd({ cmd = 'split', args = { buffer_name }, mods = { vertical = true } }, {})
        Tapey_tape_window_number = vim.api.nvim_get_current_win()
        local width = utils.detect_tapey_tape_line_width()
        vim.api.nvim_win_set_width(Tapey_tape_window_number, width)
        -- Go back to opened buffer that command was run from
        vim.api.nvim_cmd({ cmd = 'normal', args = { 'h' } }, {})
    elseif open_method == 'split' then
        vim.api.nvim_cmd({ cmd = 'split', args = { buffer_name }, mods = { vertical = false } }, {})
        Tapey_tape_window_number = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_height(Tapey_tape_window_number, opts.vertical_split_height)
        -- Go back to opened buffer that command was run from
        vim.api.nvim_cmd({ cmd = 'normal', args = { 'k' } }, {})
    end

    -- Set window options
    if Tapey_tape_window_number ~= nil then
        vim.api.nvim_win_set_option(Tapey_tape_window_number, 'number', false)
        vim.api.nvim_win_set_option(Tapey_tape_window_number, 'relativenumber', false)
        vim.api.nvim_win_set_option(Tapey_tape_window_number, 'signcolumn', 'auto')
    end
end

local function close_window()
    TapeyTapeWindowOpen = false
    vim.api.nvim_buf_delete(Tapey_tape_buffer_number, { force = true })
    Tapey_tape_buffer_number = nil
    Tapey_tape_window_number = nil
end

local function update_display(line)
    -- Get filter and always escape '%' for status line
    if opts.status_line_setup.enabled then
        local filter = opts.status_line_setup.additional_filter or '(|.-|)'
        local newTapeyTapeLine = (line:gsub('%%', '%%%%')):match(filter)
        TapeyTape = newTapeyTapeLine
    end

    local utils = require('plover-tapey-tape.utils')
    local parsed_log_line = utils.parse_log_line(line)

    if opts.suggestion_notifications.enabled then
        if parsed_log_line.suggestions ~= nil then
            local suggestion_text = ''
            for item, suggestion in ipairs(parsed_log_line.suggestions) do
                if item == 1 then
                    suggestion_text = suggestion
                else
                    suggestion_text = (suggestion_text or '') .. '\n' .. suggestion
                end
            end
            vim.notify(suggestion_text, vim.log.levels.INFO, { title = 'plover-tapey-tape.nvim suggestions' })
        end
    end

    -- TODO move to config item
    local trim_timestamp = true
    if trim_timestamp == true then
        -- Clear the timestamp out
        -- +++++ |       R      R        | {MODE:RESET}{^\n}{^} 2023-02-13 09:22:02.569
        parsed_log_line.line = parsed_log_line.line:gsub('%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d.%d%d%d', '')
    end

    if Tapey_tape_window_number ~= nil and Tapey_tape_buffer_number ~= nil then
        if vim.api.nvim_buf_line_count(Tapey_tape_buffer_number) < 8 then
            vim.api.nvim_buf_set_lines(Tapey_tape_buffer_number, -1, -1, false, { '', '', '', '', '', '', '', '' })
        end
        vim.api.nvim_buf_set_lines(Tapey_tape_buffer_number, -1, -1, false, { parsed_log_line.line })
        utils.draw_steno_keyboard_extmark(parsed_log_line)
    end
end

local function set_tapey_tape_extmark(row, col, text, highlight)
    local namespace = vim.api.nvim_create_namespace('TapeyTape')
    vim.api.nvim_buf_set_extmark(Tapey_tape_buffer_number, namespace, row, 0, {
        virt_text_win_col = col,
        virt_text_pos = 'overlay',
        virt_text = { { text, highlight } },
    })
end

---Function to determine what highlight the steno key should receive
---@param char string should be a single character in length
---@param parsed_steno_table table
---@param steno_keyboard_side string
---@return string
local function find_char_highlight(char, parsed_steno_table, steno_keyboard_side)
    local highlight = ''
    if char:match('[%+%-%| ]') then
        highlight = 'Title'
    else
        local steno_key_has_been_pressed = false
        for k, v in ipairs(parsed_steno_table.steno) do
            if v == char then
                if v:match('([STPR])') ~= nil and k < 10 and steno_keyboard_side == 'left_half' then
                    steno_key_has_been_pressed = true
                    break
                elseif v:match('([STPR])') ~= nil and k > 10 and steno_keyboard_side == 'right_half' then
                    steno_key_has_been_pressed = true
                    break
                elseif v:match('([^STPR])') ~= nil then
                    steno_key_has_been_pressed = true
                    break
                end
            end
        end

        if steno_key_has_been_pressed then
            highlight = 'FancyStenoActive'
        else
            highlight = 'Folded'
        end
    end

    return highlight
end

local function draw_steno_keyboard_extmark(parsed_steno_table)
    -- Clear old lines first
    local namespace = vim.api.nvim_create_namespace('TapeyTape')
    vim.api.nvim_buf_clear_namespace(Tapey_tape_buffer_number, namespace, 0, -1)

    local steno_keyboard_layout = require('plover-tapey-tape.steno-keyboard-layout')
    local left_half = 'left_half'
    local right_half = 'right_half'

    local lines_in_file = vim.api.nvim_buf_line_count(Tapey_tape_buffer_number) + 1 -- 0 based
    local window_height = vim.api.nvim_win_get_height(Tapey_tape_window_number)
    local window_width = vim.api.nvim_win_get_width(Tapey_tape_window_number)
    local center_width = math.ceil((window_width / 2) - #steno_keyboard_layout.left_half[1] - 1)

    local start_column = center_width
    local start_row = math.floor(lines_in_file - window_height)
    if start_row <= 0 then
        start_row = 0
    end
    local current_row = start_row
    for steno_row = 1, 3 do
        set_tapey_tape_extmark(current_row, start_column, steno_keyboard_layout.row_border[steno_row], 'Title')

        current_row = current_row + 1

        for column, steno_key in ipairs(steno_keyboard_layout[left_half][steno_row]) do
            local highlight_for_key = find_char_highlight(steno_key, parsed_steno_table, left_half)
            set_tapey_tape_extmark(current_row, start_column + column - 1, steno_key, highlight_for_key)
        end

        for column, steno_key in ipairs(steno_keyboard_layout[right_half][steno_row]) do
            local highlight_for_key = find_char_highlight(steno_key, parsed_steno_table, right_half)
            local right_side_column_offset = #steno_keyboard_layout.left_half[1]
            set_tapey_tape_extmark(
                current_row,
                start_column + column + right_side_column_offset - 1,
                steno_key,
                highlight_for_key
            )
        end

        current_row = current_row + 1
    end

    -- Draw last row border
    set_tapey_tape_extmark(
        current_row,
        start_column,
        steno_keyboard_layout.row_border[#steno_keyboard_layout.row_border],
        'Title'
    )
end

local function parse_log_line(line)
    if line == nil then
        return nil
    end

    local parsed_line = {}
    parsed_line.line = line
    parsed_line.steno_keys = line:match(opts.steno_capture)
    if parsed_line.steno_keys ~= nil then
        if #parsed_line.steno_keys ~= 23 then
            vim.notify_once(
                'Steno keys could not be matched, length is not equal to 23 for steno string',
                vim.log.levels.INFO,
                { title = 'plover-tapey-tape.nvim' }
            )
        end
        parsed_line.steno = {}
        for match in parsed_line.steno_keys:gmatch('.') do
            table.insert(parsed_line.steno, match)
        end

        local suggestion_match = line:match(' >+([A-Z0-9 ]+)%s?$')
        if suggestion_match ~= nil then
            parsed_line.suggestions = {}
            for suggestion in suggestion_match:gmatch('%w+') do
                table.insert(parsed_line.suggestions, suggestion)
            end
        end
    end

    return parsed_line
end

return {
    setup = setup,
    read_last_line_of_tapey_tape = read_last_line_of_tapey_tape,
    execute_command = execute_command,
    get_tapey_tape_filename = get_tapey_tape_filename,
    detect_tapey_tape_line_width = detect_tapey_tape_line_width,
    file_exists = file_exists,
    scroll_buffer_to_bottom = scroll_buffer_to_bottom,
    open_window = open_window,
    close_window = close_window,
    update_display = update_display,
    parse_log_line = parse_log_line,
    draw_steno_keyboard_extmark = draw_steno_keyboard_extmark,
    find_char_highlight = find_char_highlight,
}
