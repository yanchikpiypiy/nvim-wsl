-- Proper Neovim config dev environment for lua_ls:
-- handles the workspace library lazily so lua_ls doesn't index everything on startup
return {
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                -- Load luvit types when vim.uv is used
                { path = "luvit-meta/library", words = { "vim%.uv" } },
            },
        },
    },
    -- Type definitions for vim.uv (libuv bindings)
    { "Bilal2453/luvit-meta", lazy = true },
}
