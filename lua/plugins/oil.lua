-- Folder as an editable buffer; :w applies renames/deletes/new files (see README)
return {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    keys = {
        { "-", "<cmd>Oil<CR>", desc = "Open parent folder (oil)" },
        { "<leader>e", "<cmd>Oil<CR>", desc = "Explorer (oil)" },
    },
    opts = {
        view_options = { show_hidden = true },
        skip_confirm_for_simple_edits = true,
        keymaps = { ["q"] = { "actions.close", mode = "n" } }, -- match the q-closes-panels rule
    },
}
