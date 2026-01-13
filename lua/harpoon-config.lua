return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },

    keys = {
        {
            "<leader>a",
            function()
                require("harpoon"):list():add()
            end,
            desc = "Harpoon add file",
        },
        {
            "<leader>h",
            function()
                local harpoon = require("harpoon")
                harpoon.ui:toggle_quick_menu(harpoon:list())
            end,
            desc = "Harpoon menu",
        },
        {
            "<leader>1",
            function()
                require("harpoon"):list():select(1)
            end,
        },
        {
            "<leader>2",
            function()
                require("harpoon"):list():select(2)
            end,
        },
    },
}
