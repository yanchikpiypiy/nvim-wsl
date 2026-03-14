return {
    -- gcc = toggle line comment, gc + motion, gc in visual
    {
        "numToStr/Comment.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("Comment").setup()
        end,
    },

    -- Surround: ys<motion><char>  cs<old><new>  ds<char>
    -- Examples: ysiw"  cs"'  ds(  yss)
    {
        "kylechui/nvim-surround",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("nvim-surround").setup()
        end,
    },
}
