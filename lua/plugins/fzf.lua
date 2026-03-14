return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>fs", "<cmd>FzfLua files<CR>", desc = "Find Files" },
        { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Live Grep" },
        { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "List Buffers" },
        { "<leader>cq", "<cmd>tabclose<CR>", desc = "Close config tab" },
    },
    config = function()
        require("fzf-lua").setup({})
    end,
}
