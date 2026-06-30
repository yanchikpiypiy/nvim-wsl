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
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
        { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,  desc = "Flash Treesitter" },
        { "r", mode = "o",               function() require("flash").remote() end,      desc = "Remote Flash" },
        { "R", mode = { "o", "x" },       function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    },
}
