-- Highlight + search TODO / FIXME / HACK / NOTE / WARN comments.
-- Colors inherit our (muted) Diagnostic groups, so they match the scheme.
return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        local todo = require("todo-comments")
        todo.setup()
        vim.keymap.set("n", "]t", function() todo.jump_next() end, { desc = "Next todo comment" })
        vim.keymap.set("n", "[t", function() todo.jump_prev() end, { desc = "Prev todo comment" })
        vim.keymap.set("n", "<leader>xt", "<cmd>TodoTrouble<CR>", { desc = "Todos (Trouble)" })
        vim.keymap.set("n", "<leader>ft", "<cmd>TodoQuickFix<CR>", { desc = "Find todos (quickfix)" })
    end,
}
