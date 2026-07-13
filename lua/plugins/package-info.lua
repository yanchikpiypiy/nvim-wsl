-- package-info.nvim: shows npm dependency versions inline in package.json,
-- flags outdated packages, and can install/update/delete deps.
-- (The npm equivalent of :Dotnet outdated.)
return {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    ft = "json", -- only does anything in package.json
    config = function()
        require("package-info").setup()
        -- Actions under <leader>j (package.Json) so they don't clash.
        local pi = require("package-info")
        local map = vim.keymap.set
        map("n", "<leader>ju", pi.update,          { desc = "Package: update under cursor" })
        map("n", "<leader>jd", pi.delete,          { desc = "Package: delete under cursor" })
        map("n", "<leader>ji", pi.install,         { desc = "Package: install new" })
        map("n", "<leader>jc", pi.change_version,  { desc = "Package: change version" })
        map("n", "<leader>jt", pi.toggle,          { desc = "Package: toggle version display" })
    end,
}
