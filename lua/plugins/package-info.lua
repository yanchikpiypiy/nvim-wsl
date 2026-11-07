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
        local function set_maps(buf)
            local function map(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc }) end
            map("<leader>ju", pi.update,         "Package: update under cursor")
            map("<leader>jd", pi.delete,         "Package: delete under cursor")
            map("<leader>ji", pi.install,        "Package: install new")
            map("<leader>jc", pi.change_version, "Package: change version")
            map("<leader>jt", pi.toggle,         "Package: toggle version display")
        end
        -- Only in package.json buffers, not every json file
        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = "package.json",
            callback = function(args) set_maps(args.buf) end,
        })
        if vim.fs.basename(vim.api.nvim_buf_get_name(0)) == "package.json" then set_maps(0) end
    end,
}
