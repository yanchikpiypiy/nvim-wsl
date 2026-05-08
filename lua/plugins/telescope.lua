return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "nvim-telescope/telescope-ui-select.nvim",
        },
        cmd = "Telescope",
        keys = {
            -- Files
            { "<leader>fs", function() require("telescope.builtin").find_files() end,  desc = "Find files" },
            { "<leader>fg", function() require("telescope.builtin").live_grep() end,   desc = "Live grep" },
            { "<leader>fb", function() require("telescope.builtin").buffers() end,     desc = "Buffers" },

            -- Config
            {
                "<leader>fc",
                function()
                    require("telescope.builtin").find_files({
                        cwd = vim.fn.stdpath("config"),
                        prompt_title = "Nvim Config",
                    })
                end,
                desc = "Find config file",
            },

            -- Git pickers
            { "<leader>gf", function() require("telescope.builtin").git_files() end,                          desc = "Git files (tracked)" },
            { "<leader>gt", function() require("telescope.builtin").git_status() end,                         desc = "Git status (changed files)" },
            { "<leader>gc", function() require("telescope.builtin").git_commits() end,                        desc = "Git commits (log)" },
            { "<leader>gC", function() require("telescope.builtin").git_bcommits() end,                       desc = "Git commits (this buffer)" },
            { "<leader>gl", function() require("telescope.builtin").git_branches() end,                       desc = "Git branches" },
            { "<leader>gz", function() require("telescope.builtin").git_stash() end,                          desc = "Git stash" },
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")

            telescope.setup({
                defaults = {
                    prompt_prefix = "  ",
                    selection_caret = " ",
                    path_display = function(_, path)
                        local parts = {}
                        for part in path:gmatch("[^/\\]+") do
                            table.insert(parts, part)
                        end
                        local n = #parts
                        if n <= 3 then return path end
                        return table.concat({ parts[n-2], parts[n-1], parts[n] }, "/")
                    end,
                    layout_strategy = "horizontal",
                    layout_config = {
                        horizontal = {
                            preview_width = 0.45,
                            results_width = 0.55,
                        },
                        width = 0.9,
                        height = 0.85,
                    },
                    file_ignore_patterns = {
                        "node_modules", ".git/", "build/",
                        "%.o$", "%.a$", "%.out$",
                        "bin/", "obj/", "%.dll$", "%.exe$", "%.pdb$",
                        "%.min%.js$", "%.map$",
                    },
                    mappings = {
                        i = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                            -- Send all results to quickfix and open it
                            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                            -- Send selected entries to quickfix
                            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                            ["<esc>"] = actions.close,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        find_command = {
                            "fd", "--type", "f", "--strip-cwd-prefix", "--hidden",
                            "--exclude", ".git",
                            "--exclude", "bin",
                            "--exclude", "obj",
                            "--exclude", "build",
                            "--exclude", "node_modules",
                            "--exclude", "*.exe",
                            "--exclude", "*.dll",
                            "--exclude", "*.pdb",
                        },
                    },
                    live_grep = {
                        additional_args = { "--hidden", "--glob", "!.git" },
                    },
                    -- LSP
                    lsp_references       = { show_line = false, fname_width = 60 },
                    lsp_definitions      = { show_line = false, fname_width = 60 },
                    lsp_implementations  = { show_line = false, fname_width = 60 },
                    lsp_type_definitions = { show_line = false, fname_width = 60 },
                    lsp_document_symbols = { symbol_width = 50 },
                    -- Git
                    git_commits  = { mappings = { i = { ["<CR>"] = "select_default" } } },
                    git_bcommits = { mappings = { i = { ["<CR>"] = "select_default" } } },
                    git_branches = { mappings = { i = { ["<CR>"] = "git_checkout" } } },
                    git_status   = { git_icons = { added = "+", changed = "~", deleted = "-",
                                                   renamed = "→", untracked = "?", copied = "c" } },
                },
                extensions = {
                    ["ui-select"] = {
                        -- Code actions appear as a small centered dropdown
                        require("telescope.themes").get_dropdown({
                            winblend = 10,
                            width = 0.5,
                            previewer = false,
                        }),
                    },
                },
            })

            telescope.load_extension("fzf")
            telescope.load_extension("ui-select")
        end,
    },
}
