return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local ts = require("nvim-treesitter")
        ts.install({ "javascript", "typescript", "tsx", "html", "css", "lua", "vim", "c_sharp" })
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "*",
            callback = function(event)
                local ok = pcall(vim.treesitter.start, event.buf)
                if not ok then
                    return
                end
            end,
        })
    end,
}
