return {
    "seblyng/roslyn.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim", "saghen/blink.cmp" },
    config = function()
        local capabilities = require("blink.cmp").get_lsp_capabilities(
            vim.lsp.protocol.make_client_capabilities()
        )

        -- roslyn.nvim's default cmd expects `Microsoft.CodeAnalysis.LanguageServer`
        -- on PATH. Our server is the Mason `roslyn` package, so launch its dll
        -- directly with dotnet. Launching the dll (not Mason's roslyn.cmd shim)
        -- is robust on Windows, where libuv can't exec a .cmd directly.
        local roslyn_dll = vim.fs.joinpath(
            vim.fn.stdpath("data"), "mason", "packages", "roslyn", "libexec",
            "Microsoft.CodeAnalysis.LanguageServer.dll"
        )
        local roslyn_cmd = vim.uv.fs_stat(roslyn_dll)
            and {
                "dotnet", roslyn_dll,
                "--logLevel=Information",
                "--extensionLogDirectory=" .. vim.fn.stdpath("log"),
                "--stdio",
            }
            or nil -- fall back to roslyn.nvim's default if the dll isn't there

        vim.lsp.config("roslyn", {
            cmd = roslyn_cmd,
            capabilities = capabilities,
            settings = {
                ["csharp|inlay_hints"] = {
                    csharp_enable_inlay_hints_for_implicit_object_creation              = true,
                    csharp_enable_inlay_hints_for_implicit_variable_types               = true,
                    csharp_enable_inlay_hints_for_lambda_parameter_types                = true,
                    csharp_enable_inlay_hints_for_types                                 = true,
                    dotnet_enable_inlay_hints_for_parameters                            = true,
                    dotnet_enable_inlay_hints_for_object_creation_parameters            = true,
                    dotnet_enable_inlay_hints_for_other_parameters                      = true,
                    dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
                    dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
                },
                ["csharp|completion"] = {
                    dotnet_show_completion_items_from_unimported_namespaces = true,
                    dotnet_show_name_completion_suggestions                 = true,
                },
                ["csharp|code_lens"] = {
                    dotnet_enable_references_code_lens = true,
                },
            },
        })

        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client or client.name ~= "roslyn" then return end

                local map = vim.keymap.set
                local o   = { buffer = args.buf, silent = true }
                local sp = require("snacks").picker

                -- Drop Neovim's default gr* LSP maps so `gr` isn't a prefix
                -- (otherwise `gr` waits for a second key before firing).
                for _, k in ipairs({ "grn", "gra", "grr", "gri", "grt" }) do
                    pcall(vim.keymap.del, "n", k)
                end

                map("n", "gd", sp.lsp_definitions,                vim.tbl_extend("force", o, { desc = "Go to definition" }))
                map("n", "gr", sp.lsp_references,                 vim.tbl_extend("force", o, { desc = "Find references" }))
                map("n", "gi", sp.lsp_implementations,            vim.tbl_extend("force", o, { desc = "Go to implementation" }))
                map("n", "gy", sp.lsp_type_definitions,           vim.tbl_extend("force", o, { desc = "Go to type definition" }))
                map("n", "<leader>rn", vim.lsp.buf.rename,        vim.tbl_extend("force", o, { desc = "Rename symbol" }))
                map("n", "<leader>ca", vim.lsp.buf.code_action,   vim.tbl_extend("force", o, { desc = "Code action" }))
                map("n", "<leader>ls", sp.lsp_symbols,            vim.tbl_extend("force", o, { desc = "Document symbols" }))
                map("n", "<leader>lw", sp.lsp_workspace_symbols,
                    vim.tbl_extend("force", o, { desc = "Workspace symbols" }))
                map("n", "<leader>li", "<cmd>LspInfo<CR>",        vim.tbl_extend("force", o, { desc = "LSP info" }))

                -- Inlay hints disabled by default; toggle on with <leader>lh
            end,
        })

        require("roslyn").setup({
            broad_search = true,
            choose_target = function(targets)
                for _, target in ipairs(targets) do
                    if target:match("%.sln$") then
                        return target
                    end
                end
                return targets[1]
            end,
            lock_target = true,
        })
    end,
}
