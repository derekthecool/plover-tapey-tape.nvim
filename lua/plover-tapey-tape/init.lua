local utils = require('plover-tapey-tape.utils')

local function start()
    TapeyTapeActive = true
    InsideTapeBuffer = false

    local filepath = utils.resolve_tapey_tape_filepath()
    if filepath then
        utils.start_watching(filepath, function(line)
            if line ~= nil and line ~= Previous_line then
                Previous_line = line
                utils.update_display(line)
                utils.scroll_buffer_to_bottom()
            end
        end)
    end
end

local function stop()
    TapeyTapeActive = false
    TapeyTape = nil
    utils.stop_watching()
    if TapeyTapeWindowOpen then
        utils.close_window()
    end
end

local function toggle()
    if not TapeyTapeActive then
        start()
    end

    if TapeyTapeWindowOpen then
        utils.close_window()
        return
    else
        utils.open_window()
        return
    end
end

return {
    start = start,
    stop = stop,
    toggle = toggle,
    setup = utils.setup,
}
