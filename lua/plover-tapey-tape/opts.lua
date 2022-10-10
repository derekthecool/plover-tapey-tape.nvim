--- Returns default settings, can be modified later.
--- Example from leap.nvim plugin: https://github.com/ggandor/leap.nvim/blob/518389452cfb65d0493c134c58675cdeddbeb371/lua/leap/opts.lua
---@return table
return {
    filepath = 'auto',
    open_method = 'vsplit',
    vertical_split_height = 9,
    horizontal_split_width = 54,
    steno_capture = '|(.-)|',
    suggestion_notifications = {
        enabled = true,
    },
    status_line_setup = {
        enabled = true,
        additional_filter = '(|.-|)',
    },
}
