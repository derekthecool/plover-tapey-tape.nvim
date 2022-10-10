local utils = require('plover-tapey-tape.utils')

local function update()
    local line = utils.read_last_line_of_tapey_tape()
    if line ~= nil and line ~= Previous_line then
        Previous_line = line
        local parsed_line = utils.parse_log_line(line)
        utils.update_display(line)
    end
end

local function start()
    TapeyTapeActive = true
    InsideTapeBuffer = false
    -- Starting timer in neovim : https://stackoverflow.com/questions/68598026/running-async-lua-function-in-neovim
    local timer = vim.loop.new_timer()
    timer:start(
        0,
        90,
        vim.schedule_wrap(function()
            if TapeyTapeActive then
                update()
                require('plover-tapey-tape.utils').scroll_buffer_to_bottom()
            end
        end)
    )
end

local function stop()
    TapeyTapeActive = false
    TapeyTape = nil
end

local function toggle()
    if not TapeyTapeActive then
        start()
    end

    if TapeyTapeWindowOpen then
        require('plover-tapey-tape.utils').close_window()
        return
    else
        require('plover-tapey-tape.utils').open_window()
        return
    end
end

return {
    start = start,
    stop = stop,
    toggle = toggle,
    setup = utils.setup,
}
