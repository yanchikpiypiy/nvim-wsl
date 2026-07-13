return {
    -- Ensure devicons is set up before neo-tree
    {
        "nvim-tree/nvim-web-devicons",
        lazy = true, -- loads on demand as a dependency of neo-tree/lualine/trouble
        config = function()
            require("nvim-web-devicons").setup({ default = true })
        end,
    },

    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "main",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        keys = {
            { "<leader>e",  "<cmd>Neotree toggle<CR>",               desc = "Toggle Explorer" },
            { "<leader>be", "<cmd>Neotree buffers reveal float<CR>", desc = "Buffer Explorer" },
            { "<leader>ge", "<cmd>Neotree float git_status<CR>",     desc = "Git status" },
        },
        config = function()
            -- Use explicit codepoints so the glyphs survive any file encoding issues
            local ico = {
                folder        = vim.fn.nr2char(0xf07b), -- nf-fa-folder
                folder_open   = vim.fn.nr2char(0xf07c), -- nf-fa-folder-open
                folder_empty  = vim.fn.nr2char(0xf114), -- nf-fa-folder-o
                arrow_closed  = vim.fn.nr2char(0xe0b1), --
                arrow_open    = vim.fn.nr2char(0xe0b3), --
                modified      = vim.fn.nr2char(0x25cf), -- ●
                -- git
                added         = vim.fn.nr2char(0xf067), --
                modified_git  = vim.fn.nr2char(0xf040), --
                deleted       = vim.fn.nr2char(0xf00d), --
                renamed       = vim.fn.nr2char(0xf0a9), --
                untracked     = vim.fn.nr2char(0xf128), --
                ignored       = vim.fn.nr2char(0xf070), --
                -- diagnostics
                error         = vim.fn.nr2char(0xf658), --
                warn          = vim.fn.nr2char(0xf071), --
                info          = vim.fn.nr2char(0xf05a), --
                hint          = vim.fn.nr2char(0xf0eb), --
            }

            require("neo-tree").setup({
                close_if_last_window = true,
                popup_border_style   = "rounded",
                enable_git_status    = true,
                enable_diagnostics   = false,

                default_component_configs = {
                    indent = {
                        indent_size        = 2,
                        padding            = 1,
                        with_markers       = true,
                        indent_marker      = "│",
                        last_indent_marker = "└",
                        with_expanders     = false,
                    },
                    icon = {
                        folder_closed = ico.folder,
                        folder_open   = ico.folder_open,
                        folder_empty  = ico.folder_empty,
                    },
                    modified = { symbol = ico.modified },
                    git_status = {
                        symbols = {
                            added     = ico.added,
                            modified  = ico.modified_git,
                            deleted   = ico.deleted,
                            renamed   = ico.renamed,
                            untracked = ico.untracked,
                            ignored   = ico.ignored,
                            unstaged  = "U",
                            staged    = "S",
                            conflict  = "C",
                        },
                    },
                    diagnostics = {
                        symbols = {
                            error = ico.error .. " ",
                            warn  = ico.warn  .. " ",
                            info  = ico.info  .. " ",
                            hint  = ico.hint  .. " ",
                        },
                    },
                },

                window = {
                    position = "left",
                    width    = 35,
                    mappings = {
                        ["<space>"] = "none",
                        ["l"]       = "open",
                        ["h"]       = "close_node",
                        ["H"]       = "toggle_hidden",
                        ["P"]       = { "toggle_preview", config = { use_float = true } },
                    },
                },

                filesystem = {
                    filtered_items = {
                        hide_dotfiles   = false,
                        hide_gitignored = false,
                    },
                    follow_current_file    = { enabled = true },
                    use_libuv_file_watcher = false, -- slow on Windows/WSL, use manual refresh (r) instead
                },
            })
        end,
    },
}
