return {
    "seblyng/roslyn.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim", "saghen/blink.cmp" },
    config = function()
        local capabilities = require("blink.cmp").get_lsp_capabilities(
            vim.lsp.protocol.make_client_capabilities()
        )

        vim.lsp.config("roslyn", {
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
                local tb = require("telescope.builtin")

                map("n", "gd", tb.lsp_definitions,                vim.tbl_extend("force", o, { desc = "Go to definition" }))
                map("n", "gr", tb.lsp_references,                 vim.tbl_extend("force", o, { desc = "Find references" }))
                map("n", "gi", tb.lsp_implementations,            vim.tbl_extend("force", o, { desc = "Go to implementation" }))
                map("n", "gy", tb.lsp_type_definitions,           vim.tbl_extend("force", o, { desc = "Go to type definition" }))
                map("n", "<leader>rn", vim.lsp.buf.rename,        vim.tbl_extend("force", o, { desc = "Rename symbol" }))
                map("n", "<leader>ca", vim.lsp.buf.code_action,   vim.tbl_extend("force", o, { desc = "Code action" }))
                map("n", "<leader>ls", tb.lsp_document_symbols,   vim.tbl_extend("force", o, { desc = "Document symbols" }))
                map("n", "<leader>lw", tb.lsp_dynamic_workspace_symbols,
                    vim.tbl_extend("force", o, { desc = "Workspace symbols" }))
                map("n", "<leader>li", "<cmd>LspInfo<CR>",        vim.tbl_extend("force", o, { desc = "LSP info" }))

                if client.supports_method("textDocument/inlayHint") then
                    vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
                end
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
