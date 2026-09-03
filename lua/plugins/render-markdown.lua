-- Pretty in-buffer markdown: tables, headings, bullets, code blocks, and it
-- conceals the raw [text](url) link noise. Applied to markdown AND octo buffers
-- so PR/issue comments — especially the codecov coverage TABLE — render as a
-- real bordered table with clean link text instead of a wall of giant URLs.
--
-- KEY: octo buffers are filetype `octo`, not `markdown`, so the markdown
-- treesitter parser never attaches and render-markdown has nothing to parse
-- (this is why it looked broken before). We register the markdown parser for
-- the `octo` filetype so it renders there too.
--
-- NOTE: this renders MARKDOWN. Raw HTML that GitHub allows in comments
-- (<div>, <img>, <picture>) can't be prettified by any markdown renderer and
-- stays as-is — but the codecov table is markdown, so it cleans up nicely.
return {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown", "octo" },
    config = function()
        pcall(vim.treesitter.language.register, "markdown", "octo")
        require("render-markdown").setup({
            file_types = { "markdown", "octo" },
            -- keep it rendered even on the cursor line (default un-hides markup
            -- there, which looks worse in read-only PR comments)
            anti_conceal = { enabled = false },
        })
    end,
}
