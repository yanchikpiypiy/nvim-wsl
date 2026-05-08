return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup({
            ensure_installed = { "javascript", "typescript", "tsx", "html", "css", "lua", "vim", "c_sharp", "markdown", "markdown_inline" },
        })
    end,
}
