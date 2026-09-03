return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup()

        -- main branch: `ensure_installed` is gone; install parsers explicitly.
        -- (Compiling these requires the `tree-sitter` CLI on PATH.)
        -- Run it AFTER startup (VeryLazy) so parser checks/compiles don't sit on
        -- the launch hot path. Already-installed parsers are skipped.
        vim.api.nvim_create_autocmd("User", {
            pattern = "VeryLazy",
            once = true,
            callback = function()
                require("nvim-treesitter").install({
                    "c", "cpp",
                    "javascript", "typescript", "tsx", "html", "css",
                    "lua", "vim", "vimdoc",
                    "c_sharp", "markdown", "markdown_inline",
                })
            end,
        })

        -- main branch: highlighting is NOT auto-enabled. Start it per buffer
        -- whenever a parser exists for the file's language. This also makes
        -- the picker's preview use treesitter highlights.
        -- Generated sources in cris-erm-tfs run well past this
        -- (ReviewResources.Designer.cs is 680KB, MigrationCommandHandler.cs
        -- 424KB); parsing one on top of Roslyn semantic tokens is what makes
        -- opening it feel like a hang. Over the limit, the buffer just gets no
        -- treesitter highlighting.
        local MAX_TS_BYTES = 256 * 1024
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                local name = vim.api.nvim_buf_get_name(args.buf)
                local stat = name ~= "" and vim.uv.fs_stat(name) or nil
                if stat and stat.size > MAX_TS_BYTES then return end
                local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
                if lang and pcall(vim.treesitter.language.add, lang) then
                    pcall(vim.treesitter.start, args.buf, lang)
                end
            end,
        })
    end,
}
