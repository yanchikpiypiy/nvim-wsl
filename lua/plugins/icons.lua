return {
    {
        "nvim-tree/nvim-web-devicons",
        lazy = true, -- loaded on demand by oil/lualine/trouble/snacks
        config = function()
            require("nvim-web-devicons").setup({ default = true })
        end,
    },
}
