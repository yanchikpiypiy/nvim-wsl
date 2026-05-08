local map = vim.keymap.set
local opts = { silent = true }

map("n", "<Esc>", "<Cmd>noh<CR>", { silent = true })

-- ===============================
-- Diagnostics
-- ===============================
map("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show Diagnostics" }))
map("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Previous Diagnostic" }))
map("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next Diagnostic" }))
map("n", "<leader>xx", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Set Location List" }))

map("n", "<leader>vs", "<cmd>luafile %<CR>", vim.tbl_extend("force", opts, { desc = "Reload current config file" }))

-- Inlay hints toggle
map("n", "<leader>lh", function()
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
    vim.notify(enabled and "Inlay hints off" or "Inlay hints on", vim.log.levels.INFO)
end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))

-- Buffer navigation
map("n", "[b", "<cmd>bprev<CR>", vim.tbl_extend("force", opts, { desc = "Prev buffer" }))
map("n", "]b", "<cmd>bnext<CR>", vim.tbl_extend("force", opts, { desc = "Next buffer" }))

-- Window resizing
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>",  vim.tbl_extend("force", opts, { desc = "Decrease width" }))
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>",  vim.tbl_extend("force", opts, { desc = "Increase width" }))
map("n", "<C-Up>",    "<cmd>resize +2<CR>",            vim.tbl_extend("force", opts, { desc = "Increase height" }))
map("n", "<C-Down>",  "<cmd>resize -2<CR>",            vim.tbl_extend("force", opts, { desc = "Decrease height" }))
