-- 🔹 Bordered hover & signature help (K)
vim.lsp.buf.hover = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local winnr = vim.api.nvim_get_current_win()

    -- Get client to determine offset encoding
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    local offset_encoding = clients[1] and clients[1].offset_encoding or 'utf-16'

    local params = vim.lsp.util.make_position_params(winnr, offset_encoding)

    vim.lsp.buf_request(bufnr, "textDocument/hover", params, function(err, result, ctx, config)
        config = config or {}
        config.border = "rounded"
        vim.lsp.handlers.hover(err, result, ctx, config)
    end)
end

return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            capabilities.offsetEncoding = { "utf-16" }
            local on_attach = function(_, bufnr)
                local map = vim.keymap.set
                local opts = { buffer = bufnr, silent = true }
                map("n", "K", vim.lsp.buf.hover, opts)
                map("n", "gd", vim.lsp.buf.definition, opts)
                map("n", "gr", vim.lsp.buf.references, opts)
                map("n", "<leader>rn", vim.lsp.buf.rename, opts)
                map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
            end

            -- Lua
            vim.lsp.config.lua_ls = {
                cmd = { "lua-language-server" },
                root_markers = { ".luarc.json", ".git" },
                capabilities = capabilities,
                on_attach = on_attach,
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = { globals = { "vim" } },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                    },
                },
            }

            -- C / C++
            vim.lsp.config.clangd = {
                cmd = { "clangd", "--offset-encoding=utf-16" }, -- Add the flag here!
                root_markers = { ".clangd", "compile_commands.json", ".git" },
                capabilities = capabilities,
                on_attach = on_attach,
            }
            -- C#
            vim.lsp.config.omnisharp = {
                cmd = {
                    vim.fn.stdpath("data") .. "/mason/bin/OmniSharp",
                    "--languageserver",
                    "--hostPID",
                    tostring(vim.fn.getpid()),
                },
                root_markers = { "*.sln", "*.csproj", ".git" },
                capabilities = capabilities,
                on_attach = on_attach,
            }

            -- JS / TS / React
            vim.lsp.config.ts_ls = {
                cmd = { "typescript-language-server", "--stdio" },
                root_markers = { "package.json", "tsconfig.json", ".git" },
                filetypes = {
                    "javascript",
                    "javascriptreact",
                    "typescript",
                    "typescriptreact",
                },
                capabilities = capabilities,
                on_attach = on_attach,
            }

            -- Enable all configured LSP servers
            vim.lsp.enable({ "lua_ls", "clangd", "omnisharp", "ts_ls" })
        end,
    },
}
