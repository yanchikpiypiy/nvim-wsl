return function()
    local wk = require("which-key")



    -- Register group names using the new API

    wk.add({

        { "<leader>f", group = "File" },

        { "<leader>h", group = "Harpoon" },

        { "<leader>r", group = "LSP" },

        { "<leader>b", group = "Buffer" },

        { "<leader>g", group = "Git" },

        { "<leader>d", group = "Diagnostics" },

    })
end
