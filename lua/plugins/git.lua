return {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>gg", "<cmd>LazyGit<CR>", desc = "Open LazyGit" },
    },
    config = function()
        -- When lazygit (running in its float) opens a file via `e`
        -- (nvim --server $NVIM --remote-tab ...), the file lands in this
        -- session but the float stays drawn on top. Close the float as soon
        -- as a real file buffer is entered so we land on the new tab.
        vim.api.nvim_create_autocmd("BufWinEnter", {
            callback = function(args)
                if vim.bo[args.buf].buftype ~= "" then
                    return
                end
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == "lazygit" then
                        pcall(vim.api.nvim_win_close, win, true)
                    end
                end
            end,
        })
    end,
}
