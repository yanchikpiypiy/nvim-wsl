local map = vim.keymap.set
local opts = { silent = true }

map("n", "<Esc>", "<Cmd>noh<CR>", { silent = true })

-- ===============================
-- Diagnostics
-- ===============================
map("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show Diagnostics" }))
-- jump() replaces the removed goto_prev/goto_next; float=true keeps their
-- old behaviour of popping the message on arrival.
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end,
    vim.tbl_extend("force", opts, { desc = "Previous Diagnostic" }))
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end,
    vim.tbl_extend("force", opts, { desc = "Next Diagnostic" }))
map("n", "<leader>xx", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Set Location List" }))

map("n", "<leader>vs", "<cmd>luafile %<CR>", vim.tbl_extend("force", opts, { desc = "Reload current config file" }))

-- Notifications (snacks notifier)
map("n", "<leader>un", function() require("snacks").notifier.show_history() end, vim.tbl_extend("force", opts, { desc = "Notification history" }))
map("n", "<leader>ud", function() require("snacks").notifier.hide() end,          vim.tbl_extend("force", opts, { desc = "Dismiss notifications" }))

-- Inlay hints toggle
map("n", "<leader>lh", function()
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
    vim.notify(enabled and "Inlay hints off" or "Inlay hints on", vim.log.levels.INFO)
end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))

-- Theme picker (live preview while hovering; Esc restores)
map("n", "<leader>ut", function() require("config.theme").pick() end,
    vim.tbl_extend("force", opts, { desc = "Pick theme" }))

-- Palette tuner: pick a symbol kind, hover swatches, <CR> saves into palette.lua
map("n", "<leader>up", function() require("config.palette_tuner").pick() end,
    vim.tbl_extend("force", opts, { desc = "Tune palette colour" }))

-- Buffer navigation
map("n", "[b", "<cmd>bprev<CR>", vim.tbl_extend("force", opts, { desc = "Prev buffer" }))
map("n", "]b", "<cmd>bnext<CR>", vim.tbl_extend("force", opts, { desc = "Next buffer" }))

-- Window resizing
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>",  vim.tbl_extend("force", opts, { desc = "Decrease width" }))
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>",  vim.tbl_extend("force", opts, { desc = "Increase width" }))
map("n", "<C-Up>",    "<cmd>resize +2<CR>",            vim.tbl_extend("force", opts, { desc = "Increase height" }))
map("n", "<C-Down>",  "<cmd>resize -2<CR>",            vim.tbl_extend("force", opts, { desc = "Decrease height" }))

-- ===============================
-- System clipboard (+ register)  --  <leader> = Space
-- ===============================
-- Select text (visual) then <Space>y, or <Space>Y to grab the whole line.
map({ "n", "v" }, "<leader>y", '"+y', vim.tbl_extend("force", opts, { desc = "Yank to system clipboard" }))
map("n",          "<leader>Y", '"+Y', vim.tbl_extend("force", opts, { desc = "Yank line to system clipboard" }))
map({ "n", "v" }, "<leader>p", '"+p', vim.tbl_extend("force", opts, { desc = "Paste from system clipboard" }))
