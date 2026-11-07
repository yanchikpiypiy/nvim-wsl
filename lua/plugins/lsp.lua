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

-- One set of LSP keymaps for every server (roslyn included)
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "copilot" then return end -- attaches everywhere; not a code server
        local sp = require("snacks").picker
        local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
        end
        map("K", vim.lsp.buf.hover, "Hover docs")
        map("gd", sp.lsp_definitions, "Go to definition")
        map("gD", vim.lsp.buf.declaration, "Go to declaration")
        map("gr", sp.lsp_references, "Find references")
        map("gi", sp.lsp_implementations, "Go to implementation")
        map("gy", sp.lsp_type_definitions, "Go to type definition")
        map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("<leader>ls", sp.lsp_symbols, "Document symbols")
        map("<leader>lw", sp.lsp_workspace_symbols, "Workspace symbols")
        map("<leader>li", "<cmd>LspInfo<CR>", "LSP info")
    end,
})

return {
    {
        "williamboman/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall", "MasonLog" },
        event = { "BufReadPre", "BufNewFile" },
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
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                -- These will be auto-installed by Mason on first launch if missing
                ensure_installed = {
                    "lua_ls",   -- Lua
                    "clangd",   -- C / C++
                    "ts_ls",    -- JS / TS / React
                },
                -- CRITICAL: do NOT auto-enable every installed server. Otherwise
                -- mason-lspconfig calls vim.lsp.enable() on ALL installed servers
                -- (omnisharp, vtsls, eslint, fsautocomplete...), so C# files get
                -- BOTH omnisharp AND roslyn attaching (double-indexing = PC lag),
                -- and TS files get ts_ls + vtsls + eslint at once. We enable the
                -- servers we actually want explicitly below (and roslyn.nvim owns
                -- C#), so keep this off.
                automatic_enable = false,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "saghen/blink.cmp",
            "folke/snacks.nvim",
        },
        config = function()
            local capabilities = require("blink.cmp").get_lsp_capabilities(
                vim.lsp.protocol.make_client_capabilities()
            )

            -- Lua
            vim.lsp.config.lua_ls = {
                cmd = { "lua-language-server" },
                root_markers = { ".luarc.json", ".git" },
                capabilities = capabilities,
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
                    -- clangd writes its message trace to stderr, and Neovim
                    -- logs all LSP stderr at ERROR level -- 20k lines and ~7MB
                    -- of lsp.log per session, one synchronous write per RPC
                    -- message. Errors only.
                    "--log=error",
                    "--offset-encoding=utf-16",
                    "--background-index",          -- index whole project for cross-file gr/gd
                    "--background-index-priority=normal", -- default throttles indexing to idle
                                                          -- priority, which crawls on big trees
                    "--pch-storage=memory",        -- preambles are ~18MB each in Blender-sized
                                                   -- headers; RAM beats round-tripping to disk
                    "-j=12",                       -- indexer threads (of 16 cores), leaves headroom
                    "--clang-tidy",                -- live clang-tidy diagnostics
                    "--header-insertion=iwyu",     -- suggest correct headers (include-what-you-use)
                    "--completion-style=detailed", -- show full function signatures in completion
                    "--function-arg-placeholders=false",
                },
                root_markers = { ".clangd", "compile_commands.json", ".git" },
                capabilities = capabilities,
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
            }

            vim.lsp.enable({ "lua_ls", "clangd", "ts_ls" })
            -- Roslyn handles C# — prevent OmniSharp from auto-starting
            vim.lsp.enable("omnisharp", false)
        end,
    },
}
