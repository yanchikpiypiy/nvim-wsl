local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    require("lsp"),
    require("treesitter"),
    require("theme"),
    require("cmpp"),
    require("formatter"),
    require("file-explorer"),
    require("harpoon-config"),

    {
        "ibhagwan/fzf-lua",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("fzf-lua").setup({})
        end,
    },

    {
        "kdheepak/lazygit.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            vim.keymap.set("n", "<leader>gg", ":LazyGit<CR>", { silent = true, desc = "Open LazyGit" })
        end,
    },

    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix",
        },
        config = function()
            require("whichkey-config")()
        end,
    },

    {
        "echasnovski/mini.icons",
        event = "VeryLazy",
        config = function()
            require("mini.icons").setup()
        end,
    },
    -- Terminal inside Neovim
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = function()
            require("toggleterm").setup({
                size = 20,
                open_mapping = [[<c-\>]],
                direction = "float",
                float_opts = { border = "curved" },
            })
        end,
    },

    -- LSP status/progress
    {
        "j-hui/fidget.nvim",
        tag = "legacy",
        config = function()
            require("fidget").setup {}
        end,
    },
    {
        "rafamadriz/friendly-snippets",
        dependencies = { "L3MON4D3/LuaSnip" },
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
        end,
    }

})
