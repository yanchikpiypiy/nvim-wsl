-- Auto-highlight other occurrences of the symbol under the cursor.
return {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("illuminate").configure({
            providers = { "lsp", "treesitter", "regex" },
            delay = 120,
            large_file_cutoff = 2000,
        })
    end,
}
