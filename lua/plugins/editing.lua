return {
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
