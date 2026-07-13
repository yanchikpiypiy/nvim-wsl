-- Jump anywhere on screen: press s, type 2 chars, press the label.
-- (Takes over `s`/`S`; native `s` = substitute char is still `cl`.)
return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
        -- don't dim ("shadow") the whole buffer while flashing
        highlight = { backdrop = false },
        modes = {
            -- f / t / F / T have their own backdrop — turn it off too
            char = { highlight = { backdrop = false } },
        },
    },
    keys = {
        -- Normal + visual only (NOT operator-pending): in op-pending, `s` would
        -- hijack nvim-surround's ds/cs/ys after a slight pause. Flash jump still
        -- works from normal mode; use it then operate, or `r`/`R` below for
        -- flash-as-motion.
        { "s", mode = { "n", "x" }, function() require("flash").jump() end,       desc = "Flash" },
        { "S", mode = { "n", "x" }, function() require("flash").treesitter() end,  desc = "Flash Treesitter" },
        { "r", mode = "o",               function() require("flash").remote() end,      desc = "Remote Flash" },
        { "R", mode = { "o", "x" },       function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    },
}
