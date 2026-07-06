-- Strip CommonMark backslash escapes from Roslyn hover docs (e.g. v1\.0 → v1.0)
vim.lsp.buf.hover = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local winnr = vim.api.nvim_get_current_win()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    local offset_encoding = clients[1] and clients[1].offset_encoding or "utf-16"
    local params = vim.lsp.util.make_position_params(winnr, offset_encoding)
    vim.lsp.buf_request(bufnr, "textDocument/hover", params, function(err, result, ctx, config)
        if result and result.contents then
            local val = type(result.contents) == "table" and result.contents.value or result.contents
            if type(val) == "string" then
                val = val:gsub("\\([%p])", "%1")
                val = val:gsub("&nbsp;", " ")
                val = val:gsub("&lt;", "<")
                val = val:gsub("&gt;", ">")
                val = val:gsub("&amp;", "&")
                val = val:gsub("&quot;", '"')
                val = val:gsub("&apos;", "'")
                if type(result.contents) == "table" then result.contents.value = val
                else result.contents = val end
            end
        end
        config = config or {}
        config.border = "rounded"
        vim.lsp.handlers.hover(err, result, ctx, config)
    end)
end

-- Deduplicate diagnostics (Roslyn sends same diagnostic per project context)
local orig_diagnostic_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    if result and result.diagnostics then
        local seen, deduped = {}, {}
        for _, d in ipairs(result.diagnostics) do
            local key = d.range.start.line .. ":" .. d.range.start.character .. ":" .. d.message
            if not seen[key] then
                seen[key] = true
                table.insert(deduped, d)
            end
        end
        result.diagnostics = deduped
    end
    orig_diagnostic_handler(err, result, ctx, config)
end


return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup({
                registries = {
                    "github:mason-org/mason-registry",
                    "github:Crashdummyy/mason-registry",
                },
            })
        end,
    },
    {
        -- Bridges Mason and lspconfig: ensures servers are installed before they start
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                -- These will be auto-installed by Mason on first launch if missing
                ensure_installed = {
                    "lua_ls",   -- Lua
                    "clangd",   -- C / C++
                    "ts_ls",    -- JS / TS / React
                },
                automatic_installation = true,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "saghen/blink.cmp",
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            local capabilities = require("blink.cmp").get_lsp_capabilities(
                vim.lsp.protocol.make_client_capabilities()
            )
            capabilities.offsetEncoding = { "utf-16" }

            local on_attach = function(client, bufnr)
                local map = vim.keymap.set
                local o = { buffer = bufnr, silent = true }
                local tb = require("telescope.builtin")

                -- Navigation (all via telescope for consistent preview)
                map("n", "K",  vim.lsp.buf.hover, vim.tbl_extend("force", o, { desc = "Hover docs" }))
                map("n", "gd", tb.lsp_definitions,          vim.tbl_extend("force", o, { desc = "Go to definition" }))
                map("n", "gD", vim.lsp.buf.declaration,     vim.tbl_extend("force", o, { desc = "Go to declaration" }))
                map("n", "gr", tb.lsp_references,           vim.tbl_extend("force", o, { desc = "Find references" }))
                map("n", "gi", tb.lsp_implementations,      vim.tbl_extend("force", o, { desc = "Go to implementation" }))
                map("n", "gy", tb.lsp_type_definitions,     vim.tbl_extend("force", o, { desc = "Go to type definition" }))

                -- Refactoring
                map("n", "<leader>rn", vim.lsp.buf.rename,       vim.tbl_extend("force", o, { desc = "Rename symbol" }))
                map("n", "<leader>ca", vim.lsp.buf.code_action,  vim.tbl_extend("force", o, { desc = "Code action" }))

                -- LSP navigation group (<leader>l)
                map("n", "<leader>ls", tb.lsp_document_symbols,         vim.tbl_extend("force", o, { desc = "Document symbols" }))
                map("n", "<leader>lw", tb.lsp_dynamic_workspace_symbols, vim.tbl_extend("force", o, { desc = "Workspace symbols" }))
                map("n", "<leader>li", "<cmd>LspInfo<CR>",               vim.tbl_extend("force", o, { desc = "LSP info" }))

                -- Inlay hints (Neovim 0.10+): disabled by default, toggle on with <leader>lh
                if vim.lsp.inlay_hint and client.supports_method("textDocument/inlayHint") then
                    map("n", "<leader>lh", function()
                        vim.lsp.inlay_hint.enable(
                            not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
                            { bufnr = bufnr }
                        )
                    end, vim.tbl_extend("force", o, { desc = "Toggle inlay hints" }))
                end
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
                        -- lazydev.nvim handles workspace library — don't set it here
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                    },
                },
            }

            -- C / C++
            -- For project-wide references (gr), clangd needs a compile_commands.json.
            -- Generate it with: cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build
            -- or bear: bear -- make
            vim.lsp.config.clangd = {
                cmd = {
                    "clangd",
                    "--offset-encoding=utf-16",
                    "--background-index",          -- index whole project for cross-file gr/gd
                    "--clang-tidy",                -- live clang-tidy diagnostics
                    "--header-insertion=iwyu",     -- suggest correct headers (include-what-you-use)
                    "--completion-style=detailed", -- show full function signatures in completion
                    "--function-arg-placeholders=false",
                },
                root_markers = { ".clangd", "compile_commands.json", ".git" },
                capabilities = capabilities,
                on_attach = on_attach,
                -- Full-document sync: avoids a Neovim incremental-sync core bug
                -- (vim/lsp/sync.lua:136 assertion in compute_diff with clangd).
                flags = { allow_incremental_sync = false },
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

            vim.lsp.enable({ "lua_ls", "clangd", "ts_ls" })
            -- Roslyn handles C# — prevent OmniSharp from auto-starting
            vim.lsp.enable("omnisharp", false)
        end,
    },
}
