--- Returns default settings, can be modified later.
--- Example from leap.nvim plugin: https://github.com/ggandor/leap.nvim/blob/518389452cfb65d0493c134c58675cdeddbeb371/lua/leap/opts.lua
---@return table
return {
    filepath = 'auto',
    vertical_split_height = 3,
    horizontal_split_width = 54,
    suggestion_notifications = {
        enabled = true,
        match_function = function(text)
            local suggestions = {}
            for matches in text:gmatch('>+%w') do
            end
            return suggestions
        end,
    },
    status_line_setup = {
        enabled = true,
        additional_filter = '(|.-|)',
    },
}
