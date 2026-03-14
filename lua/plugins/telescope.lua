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
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")

            telescope.setup({
                defaults = {
                    prompt_prefix = "  ",
                    selection_caret = " ",
                    path_display = { "truncate" },
                    layout_strategy = "horizontal",
                    layout_config = {
                        horizontal = {
                            preview_width = 0.55,
                            results_width = 0.45,
                        },
                        width = 0.9,
                        height = 0.85,
                    },
                    file_ignore_patterns = { "node_modules", ".git/", "build/", "%.o$", "%.a$", "%.out$" },
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
                    -- Clean LSP pickers: no inline code preview cluttering the list
                    lsp_references      = { show_line = false, fname_width = 60 },
                    lsp_definitions     = { show_line = false, fname_width = 60 },
                    lsp_implementations = { show_line = false, fname_width = 60 },
                    lsp_type_definitions = { show_line = false, fname_width = 60 },
                    lsp_document_symbols = { symbol_width = 50 },
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
