-- Everforest, selectable from the theme picker (<leader>ut).
return {
    "sainnhe/everforest",
    lazy = false,
    priority = 1000,
    config = function()
        vim.g.everforest_better_performance = 1
    end,
}
