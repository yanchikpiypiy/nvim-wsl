return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>",              desc = "Diagnostics" },
        { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics" },
        { "<leader>xs", "<cmd>Trouble symbols toggle<CR>",                  desc = "Symbols" },
        { "<leader>xr", "<cmd>Trouble lsp_references toggle<CR>",           desc = "LSP references" },
        { "<leader>xq", "<cmd>Trouble qflist toggle<CR>",                   desc = "Quickfix list" },
    },
    config = function()
        require("trouble").setup({
            modes = {
                diagnostics = { auto_close = true, focus = true },
            },
        })
    end,
}
