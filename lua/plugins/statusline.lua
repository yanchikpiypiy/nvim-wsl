return {
    -- Bottom statusline
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme                = "auto",
                    component_separators = { left = "", right = "" },
                    section_separators   = { left = "", right = "" },
                    globalstatus         = true,  -- single statusline across all splits
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = {
                        "branch", "diff", "diagnostics",
                        -- Local-review badge (config/review.lua). Bright so it's
                        -- obvious you're diffing against a review base, not editing.
                        {
                            function()
                                local ok, r = pcall(require, "config.review")
                                return (ok and r.status()) or ""
                            end,
                            cond = function()
                                local ok, r = pcall(require, "config.review")
                                return ok and r.is_active()
                            end,
                            color = { fg = "#1a1a1a", bg = "#e5c07b", gui = "bold" },
                        },
                    },
                    lualine_c = { { "filename", path = 1 } },  -- path = 1: relative path
                    lualine_x = { "encoding", "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            })
        end,
    },

}
