return {
    "sainnhe/everforest",
    priority = 1000,
    config = function()
        vim.g.everforest_background = "medium"
        vim.g.everforest_better_performance = 1
        -- vim.cmd.colorscheme("everforest")  -- disabled: custom monochrome is active; this stays as a fallback
    end,
}
