-- Full-window git diff + file history viewer (complements lazygit/gitsigns).
-- Lazy-loaded on the keys/commands below, so it costs nothing at startup.
return {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
        { "<leader>gv", "<cmd>DiffviewOpen<CR>",          desc = "Diffview open" },
        { "<leader>gV", "<cmd>DiffviewClose<CR>",         desc = "Diffview close" },
        { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
        { "<leader>gH", "<cmd>DiffviewFileHistory<CR>",   desc = "File history (all files / repo)" },
    },
    config = function()
        require("diffview").setup({
            -- file history opens several windows; `q` closes the WHOLE view at once
            keymaps = {
                view               = { { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } } },
                file_panel         = { { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } } },
                file_history_panel = { { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } } },
            },
        })
    end,
}
