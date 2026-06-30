-- Treesitter textobjects (main branch, to match nvim-treesitter main).
-- Select:  af/if function, ac/ic class, aa/ia argument (in visual + operator-pending)
-- Move:    ]f/[f next/prev function, ]]/[[ next/prev class
return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("nvim-treesitter-textobjects").setup({
            select = { lookahead = true },
            move = { set_jumps = true },
        })

        local select = require("nvim-treesitter-textobjects.select")
        local sel = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
        }
        for key, obj in pairs(sel) do
            vim.keymap.set({ "x", "o" }, key, function()
                select.select_textobject(obj, "textobjects")
            end, { desc = "Select " .. obj })
        end

        local move = require("nvim-treesitter-textobjects.move")
        vim.keymap.set({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function" })
        vim.keymap.set({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Prev function" })
        vim.keymap.set({ "n", "x", "o" }, "]]", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class" })
        vim.keymap.set({ "n", "x", "o" }, "[[", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Prev class" })
    end,
}
