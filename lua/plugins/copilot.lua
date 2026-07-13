return {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter", -- only consumed by blink completion; keep off startup
    config = function()
        require("copilot").setup({
            suggestion = { enabled = false },
            panel = { enabled = false },
        })
    end,
}
