return {
    -- Key binding hints
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix",
        },
        config = function()
            local wk = require("which-key")
            wk.add({
                { "<leader>f", group = "File" },
                { "<leader>r", group = "Refactor" },
                { "<leader>l", group = "LSP" },
                { "<leader>b", group = "Buffer" },
                { "<leader>g", group = "Git" },
                { "<leader>d", group = "Diagnostics" },
                { "<leader>c", group = "Config" },
                { "<leader>x", group = "Trouble" },
            })
        end,
    },

    -- Floating terminal
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = function()
            require("toggleterm").setup({
                size = 20,
                open_mapping = [[<c-\>]],
                direction = "float",
                float_opts = { border = "curved" },
            })
        end,
    },

    -- LSP progress indicator
    {
        "j-hui/fidget.nvim",
        config = function()
            require("fidget").setup({})
        end,
    },
}
