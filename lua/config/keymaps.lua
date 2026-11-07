local map = vim.keymap.set
local opts = { silent = true }

map("n", "<Esc>", "<Cmd>noh<CR>", { silent = true })

-- Drop Neovim's gr* LSP defaults so `gr` (references) fires without waiting
for _, k in ipairs({ "grn", "gra", "grr", "gri", "grt", "grx" }) do
    pcall(vim.keymap.del, { "n", "x" }, k)
end

-- ===============================
-- Diagnostics
-- ===============================
map("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show Diagnostics" }))

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

-- Copilot completions toggle (blink source; copilot's inline suggestions are off)
map("n", "<leader>uc", function()
    vim.g.copilot_blink = vim.g.copilot_blink == false
    vim.notify(vim.g.copilot_blink and "Copilot completions on" or "Copilot completions off", vim.log.levels.INFO)
end, vim.tbl_extend("force", opts, { desc = "Toggle Copilot completions" }))

-- Theme picker (live preview while hovering; Esc restores)
map("n", "<leader>ut", function() require("config.theme").pick() end,
    vim.tbl_extend("force", opts, { desc = "Pick theme" }))

-- Palette tuner: pick a symbol kind, hover swatches, <CR> saves into palette.lua
map("n", "<leader>up", function() require("config.palette_tuner").pick() end,
    vim.tbl_extend("force", opts, { desc = "Tune palette colour" }))

-- Window resizing
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>",  vim.tbl_extend("force", opts, { desc = "Decrease width" }))
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>",  vim.tbl_extend("force", opts, { desc = "Increase width" }))
map("n", "<C-Up>",    "<cmd>resize +2<CR>",            vim.tbl_extend("force", opts, { desc = "Increase height" }))
map("n", "<C-Down>",  "<cmd>resize -2<CR>",            vim.tbl_extend("force", opts, { desc = "Decrease height" }))
