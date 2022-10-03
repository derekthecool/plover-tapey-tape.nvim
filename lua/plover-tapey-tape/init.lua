local utils = require('plover-tapey-tape.utils')
local tapey_tape_file = utils.get_tapey_tape_filename()

-- TODO
-- Add close function: this will need to close the open buffer and stop the the watching
-- Add autocommand to run the stop function if the buffer is closed without running command
-- Add fix for cwd issues. it should not change to Plover directory (only affects those with a plugin like I'm using of vim rooter.
-- Add way to make file updates not show that the file is being written

local function update()
    -- Using normal file read
    local tapey_tape_filename_in_update = tapey_tape_file
    if not tapey_tape_filename_in_update then
        return
    end
    local tapey_tape_file_in_update = io.open(tapey_tape_filename_in_update)

    -- Go to end of the file and then backwards by an offset
    tapey_tape_file_in_update:seek('end', -200)
    local line = ''
    for _ = 1, 10 do
        local current_line = tapey_tape_file_in_update:read('l')
        if current_line then
            current_line = current_line:match('(|.*|%[.*%])')
            line = current_line
        else
            break
        end
    end
    if tapey_tape_file_in_update then
        tapey_tape_file_in_update:close()
    end

    if line ~= previous_line then
        previous_line = line
        -- if TapeyTape ~= newTapeyTapeLine then
        local newTapeyTapeLine = (line:gsub('%%', '%%%%')):match('(|.*|)')
        TapeyTape = newTapeyTapeLine

        if tapey_tape_buffer_number ~= nil then
            vim.api.nvim_buf_set_lines(tapey_tape_buffer_number, -1, -1, false, { TapeyTape })
            -- vim.api.nvim_win_set_cursor(
            --     tapey_tape_window_number,
            --     { vim.api.nvim_buf_line_count(tapey_tape_buffer_number), 0 }
            -- )
        end
    end
end

local function open_tapey_tape(open_method)
    local opts = require('plover-tapey-tape.opts')

    if not open_method then
        open_method = 'split'
    end

    local buffer_name = 'TapeyTape'

    local buffer_exists = false
    for key, value in pairs(vim.fn.getbufinfo()) do
        if value == buffer_name then
            buffer_exists = true
        end
    end

    if not buffer_exists then
        tapey_tape_buffer_number = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(tapey_tape_buffer_number, buffer_name)
    end

    if open_method == 'split' then
        vim.cmd([[sbuffer ]] .. buffer_name)
        vim.api.nvim_win_set_height(tapey_tape_window_number, opts.vertical_split_height)
    elseif open_method == 'vsplit' then
        vim.cmd([[vertical sbuffer ]] .. buffer_name)
        local width = utils.detect_tapey_tape_line_width()
        -- vim.api.nvim_win_set_width(tapey_tape_window_number, width)
        -- V(width)
    end

    tapey_tape_window_number = vim.api.nvim_get_current_win()
    --[[ -- Save current CWD so auto root plugins don't mess it up
  utils.block_auto_change_directory('start')

  utils.block_auto_change_directory('stop')

  watch_tapey_tape_for_changes(tapey_tape_buffer_number, tapey_tape_file)
  vim.api.nvim_set_current_win(current_window) ]]
end

local function start()
    -- Starting timer in neovim : https://stackoverflow.com/questions/68598026/running-async-lua-function-in-neovim
    local timer = vim.loop.new_timer()
    timer:start(
        0,
        90,
        vim.schedule_wrap(function()
            local function win_exists(win_number)
                local found = false
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    if win == win_number then
                        found = true
                    end
                end
                return found
            end

            if tapey_tape_window_number ~= nil and win_exists(tapey_tape_window_number) then
                vim.api.nvim_win_set_cursor(
                    tapey_tape_window_number,
                    { vim.api.nvim_buf_line_count(tapey_tape_buffer_number), 0 }
                )
            end
            update()
        end)
    )
end

local function stop()
    TapeyTape = nil
end

return {
    start = start,
    stop = stop,
    open = open_tapey_tape,
    setup = utils.setup,
}
