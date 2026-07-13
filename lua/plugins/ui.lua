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
                { "<leader>n", group = "dotNet" },
                { "<leader>nt", group = "Test (C#)" },
                { "<leader>nd", group = "Debug" },
                { "<leader>j", group = "package.json" },
            })
        end,
    },

    -- Floating terminal
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        keys = { [[<c-\>]] },
        cmd = "ToggleTerm",
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
        event = "LspAttach", -- only shows LSP progress; no need before an LSP attaches
        config = function()
            require("fidget").setup({})
        end,
    },
}
