return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("gitsigns").setup({
            signs = {
                add          = { text = "▎" },
                change       = { text = "▎" },
                delete       = { text = "" },
                topdelete    = { text = "" },
                changedelete = { text = "▎" },
                untracked    = { text = "▎" },
            },
            current_line_blame = false, -- toggle with <leader>gB
            on_attach = function(bufnr)
                local gs  = package.loaded.gitsigns
                local map = vim.keymap.set
                local o   = { buffer = bufnr, silent = true }

                -- Navigate hunks
                map("n", "]c", function()
                    if vim.wo.diff then return "]c" end
                    vim.schedule(gs.next_hunk)
                    return "<Ignore>"
                end, vim.tbl_extend("force", o, { expr = true, desc = "Next hunk" }))

                map("n", "[c", function()
                    if vim.wo.diff then return "[c" end
                    vim.schedule(gs.prev_hunk)
                    return "<Ignore>"
                end, vim.tbl_extend("force", o, { expr = true, desc = "Prev hunk" }))

                -- Hunk actions
                map("n", "<leader>gs",  gs.stage_hunk,                              vim.tbl_extend("force", o, { desc = "Stage hunk" }))
                map("n", "<leader>gS",  gs.stage_buffer,                            vim.tbl_extend("force", o, { desc = "Stage buffer" }))
                map("n", "<leader>gR",  gs.reset_hunk,                              vim.tbl_extend("force", o, { desc = "Reset hunk" }))
                map("n", "<leader>gp",  gs.preview_hunk,                            vim.tbl_extend("force", o, { desc = "Preview hunk" }))
                map("n", "<leader>gb",  function() gs.blame_line({ full = true }) end, vim.tbl_extend("force", o, { desc = "Blame line" }))
                map("n", "<leader>gB",  gs.toggle_current_line_blame,               vim.tbl_extend("force", o, { desc = "Toggle blame" }))
                map("n", "<leader>gd",  gs.diffthis,                                vim.tbl_extend("force", o, { desc = "Diff this" }))

                -- Hunk text object (works with d/y/c + ih)
                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", vim.tbl_extend("force", o, { desc = "Select hunk" }))
            end,
        })
    end,
}
