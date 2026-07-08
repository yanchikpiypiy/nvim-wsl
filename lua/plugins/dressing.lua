-- Prettier vim.ui.input prompts (rename, code-action input, etc.).
-- select is left disabled so snacks.picker (picker.ui_select) keeps handling
-- vim.ui.select menus (avoids two plugins fighting over it).
return {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    config = function()
        require("dressing").setup({
            input = {
                border = "rounded",
                relative = "cursor",
                prefer_width = 40,
                win_options = { winhighlight = "Normal:NormalFloat,NormalNC:NormalFloat,FloatBorder:FloatBorder" },
            },
            select = {
                enabled = false,
            },
        })
    end,
}
