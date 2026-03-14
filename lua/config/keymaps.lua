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

-- Buffer navigation
map("n", "[b", "<cmd>bprev<CR>", vim.tbl_extend("force", opts, { desc = "Prev buffer" }))
map("n", "]b", "<cmd>bnext<CR>", vim.tbl_extend("force", opts, { desc = "Next buffer" }))
