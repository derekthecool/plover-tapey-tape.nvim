local utils = require('plover-tapey-tape.utils')
local tapey_tape_file = utils.get_tapey_tape_filename()

local function update()
    local tapey_tape_filename_in_update = tapey_tape_file
    if not tapey_tape_filename_in_update then
        return
    end
    local tapey_tape_file_in_update = io.open(tapey_tape_filename_in_update)

    if not tapey_tape_file_in_update then
        return
    end

    -- Go to end of the file and then backwards by an offset
    tapey_tape_file_in_update:seek('end', -200)
    local line = ''
    for _ = 1, 10 do
        local current_line = tapey_tape_file_in_update:read('l')
        if current_line then
            current_line = current_line
            if current_line ~= nil then
                line = current_line
            end
        else
            break
        end
    end

    if tapey_tape_file_in_update then
        tapey_tape_file_in_update:close()
    end

    if line ~= Previous_line then
        Previous_line = line

        local config = require('plover-tapey-tape.opts')

        -- Get filter and always escape '%' for status line
        if config.status_line_setup.enabled then
            local filter = config.status_line_setup.additional_filter or '(|.-|)'
            local newTapeyTapeLine = (line:gsub('%%', '%%%%')):match(filter)
            TapeyTape = newTapeyTapeLine
        end

        if Tapey_tape_buffer_number ~= nil then
            vim.api.nvim_buf_set_lines(Tapey_tape_buffer_number, -1, -1, false, { line })
        end
    end
end

local function start()
    TapeyTapeActive = true
    -- Starting timer in neovim : https://stackoverflow.com/questions/68598026/running-async-lua-function-in-neovim
    local timer = vim.loop.new_timer()
    timer:start(
        0,
        90,
        vim.schedule_wrap(function()
            if TapeyTapeActive then
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
                update()
            end
        end)
    )
end

local function stop()
    TapeyTapeActive = false
    TapeyTape = nil
end

local function open_tapey_tape(open_method)
    if not TapeyTapeActive then
        start()
    end
    local opts = require('plover-tapey-tape.opts')

    if not open_method then
        open_method = 'split'
    end

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

    -- TODO: return to buffer user was in before opening tape buffer
    if open_method == 'split' then
        vim.cmd([[sbuffer ]] .. buffer_name)
        Tapey_tape_window_number = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_height(Tapey_tape_window_number, opts.vertical_split_height)
    elseif open_method == 'vsplit' then
        vim.cmd([[vertical sbuffer ]] .. buffer_name)
        Tapey_tape_window_number = vim.api.nvim_get_current_win()
        local width = utils.detect_tapey_tape_line_width()
        vim.api.nvim_win_set_width(Tapey_tape_window_number, width)
    end

    -- Set window options
    vim.api.nvim_win_set_option(Tapey_tape_window_number, 'number', false)
    vim.api.nvim_win_set_option(Tapey_tape_window_number, 'relativenumber', false)
    vim.api.nvim_win_set_option(Tapey_tape_window_number, 'signcolumn', 'auto')
end

return {
    start = start,
    stop = stop,
    open = open_tapey_tape,
    setup = utils.setup,
}
