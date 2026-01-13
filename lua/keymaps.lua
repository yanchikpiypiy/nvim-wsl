local map = vim.keymap.set
local opts = { silent = true }
vim.keymap.set("n", "<Esc>", "<Cmd>noh<CR>", { silent = true })
-- ===============================
-- FZF-Lua
-- ===============================
map("n", "<leader>fs", "<cmd>FzfLua files<CR>", vim.tbl_extend("force", opts, { desc = "Find Files" }))
map("n", "<leader>fg", "<cmd>FzfLua live_grep<CR>", vim.tbl_extend("force", opts, { desc = "Live Grep" }))
map("n", "<leader>fb", "<cmd>FzfLua buffers<CR>", vim.tbl_extend("force", opts, { desc = "List Buffers" }))
map("n", "<leader>fc",
    function()
        require("fzf-lua").files({
            cwd = vim.fn.stdpath("config"),
            actions = {
                ["default"] = require("fzf-lua.actions").file_tabedit,
            },
        })
    end,
    vim.tbl_extend("force", opts, { desc = "Find config file (tab)" })
)
map("n", "<leader>cq",
    "<cmd>tabclose<CR>",
    vim.tbl_extend("force", opts, { desc = "Close config tab" })
)
-- ===============================
-- File Explorer
-- ===============================
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", vim.tbl_extend("force", opts, { desc = "Toggle File Explorer" }))

-- ===============================
-- Harpoon (lazy-loaded)
-- ===============================
map("n", "<leader>a", function()
    require("harpoon").list():add()
end, vim.tbl_extend("force", opts, { desc = "Add File to Harpoon" }))

map("n", "<leader>h", function()
    local harpoon = require("harpoon")
    harpoon.ui:toggle_quick_menu(harpoon:list())
end, vim.tbl_extend("force", opts, { desc = "Toggle Harpoon Menu" }))

map("n", "<leader>1", function()
    require("harpoon").list():select(0)
end, vim.tbl_extend("force", opts, { desc = "Go to Harpoon File 1" }))

map("n", "<leader>2", function()
    require("harpoon").list():select(1)
end, vim.tbl_extend("force", opts, { desc = "Go to Harpoon File 2" }))

map("n", "<leader>3", function()
    require("harpoon").list():select(2)
end, vim.tbl_extend("force", opts, { desc = "Go to Harpoon File 3" }))

map("n", "<leader>4", function()
    require("harpoon").list():select(3)
end, vim.tbl_extend("force", opts, { desc = "Go to Harpoon File 4" }))

-- ===============================
-- LSP keymaps
-- ===============================
-- ===============================
-- Diagnostics
-- ===============================
map("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show Diagnostics" }))
map("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Previous Diagnostic" }))
map("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next Diagnostic" }))
map("n", "<leader>xx", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Set Location List" }))


map("n", "<leader>vs",
    "<cmd>luafile %<CR>",
    vim.tbl_extend("force", opts, { desc = "Reload current config file" })
)
