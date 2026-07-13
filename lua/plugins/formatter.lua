return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>f",
            function()
                require("conform").format({ async = true, lsp_fallback = true })
            end,
            mode = "",
            desc = "Format buffer",
        },
    },
    opts = {
        formatters_by_ft = {
            lua                = { "stylua" },
            cpp                = { "clang-format" },
            c                  = { "clang-format" },
            javascript         = { "prettier" },
            javascriptreact    = { "prettier" },
            typescript         = { "prettier" },
            typescriptreact    = { "prettier" },
        },
        format_on_save = function(bufnr)
            -- Auto-writes (InsertLeave) set this to avoid running prettier on
            -- every insert-leave (the frontend-lag culprit). Explicit :w formats.
            if vim.b[bufnr].skip_format_on_save then return nil end
            return { timeout_ms = 500, lsp_fallback = true }
        end,
    },
}
