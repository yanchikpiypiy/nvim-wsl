return {
    "zbirenbaum/copilot.lua",
    lazy = false,
    config = function()
        require("copilot").setup({
            suggestion = { enabled = false },
            panel = { enabled = false },
        })
    end,
}
