-- ~/AppData/Local/nvim/lua/plugins/colorscheme.lua
return {
    "sainnhe/everforest",
    config = function()
        vim.g.everforest_background = "medium" -- optional
        vim.cmd.colorscheme("everforest")
    end,
}
