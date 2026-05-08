return {
    -- Snippets engine
    {
        "L3MON4D3/LuaSnip",
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
        end,
    },

    -- Autopairs (works independently of blink)
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({ check_ts = true })
        end,
    },

    -- Copilot source for blink
    { "giuxtaposition/blink-cmp-copilot" },

    -- Completion
    {
        "saghen/blink.cmp",
        dependencies = {
            "L3MON4D3/LuaSnip",
            "giuxtaposition/blink-cmp-copilot",
        },
        version = "*",
        opts = {
            keymap = {
                preset = "none",
                ["<C-x>"]     = { "show", "fallback" },
                ["<C-e>"]     = { "cancel", "fallback" },
                ["<CR>"]      = { "accept", "fallback" },
                ["<Tab>"]     = { "select_next", "snippet_forward", "fallback" },
                ["<S-Tab>"]   = { "select_prev", "snippet_backward", "fallback" },
            },

            appearance = {
                nerd_font_variant = "mono",
                kind_icons = {
                    Text          = "󰉿",
                    Method        = "󰆧",
                    Function      = "󰊕",
                    Constructor   = "",
                    Field         = "󰜢",
                    Variable      = "󰀫",
                    Class         = "󰠱",
                    Interface     = "",
                    Module        = "",
                    Property      = "󰜢",
                    Unit          = "󰑭",
                    Value         = "󰎠",
                    Enum          = "",
                    Keyword       = "󰌋",
                    Snippet       = "",
                    Color         = "󰏘",
                    File          = "󰈙",
                    Reference     = "󰈇",
                    Folder        = "󰉋",
                    EnumMember    = "",
                    Constant      = "󰏿",
                    Struct        = "󰙅",
                    Event         = "",
                    Operator      = "󰆕",
                    TypeParameter = "",
                },
            },

            sources = {
                default = { "lsp", "path", "copilot", "snippets", "buffer" },
                providers = {
                    lsp = {
                        score_offset = 10,
                    },
                    copilot = {
                        name         = "copilot",
                        module       = "blink-cmp-copilot",
                        score_offset = 100,
                        async        = true,
                    },
                    snippets = {
                        score_offset = 50,
                        opts = { friendly_snippets = true },
                    },
                    buffer = {
                        score_offset = -10,
                        opts = {
                            -- only show buffer completions from visible buffers
                            get_bufnrs = function()
                                return vim.tbl_filter(function(b)
                                    return vim.bo[b].buftype == ""
                                end, vim.api.nvim_list_bufs())
                            end,
                        },
                    },
                },
            },

            snippets = { preset = "luasnip" },

            completion = {
                ghost_text = {
                    enabled = true,
                },
                list = {
                    selection = {
                        preselect   = true,
                        auto_insert = false,
                    },
                },
                menu = {
                    border = "rounded",
                    draw = {
                        treesitter = { "lsp" },
                        columns = {
                            { "kind_icon",  gap = 1 },
                            { "label",      "label_description", gap = 2 },
                            { "kind" },
                        },
                    },
                },
                documentation = {
                    auto_show          = true,
                    auto_show_delay_ms = 100,
                    window = {
                        border      = "rounded",
                        min_width   = 20,
                        max_width   = 80,
                        max_height  = 20,
                        winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder",
                    },
                },
            },

            signature = {
                enabled = true,
                window  = { border = "rounded" },
            },
        },
    },
}
