return {
    "seblj/roslyn.nvim",
    ft = "cs",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        local on_attach = function(client, bufnr)
            local map = vim.keymap.set
            local o   = { buffer = bufnr, silent = true }
            local tb  = require("telescope.builtin")

            map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", o, { desc = "Hover docs" }))
            map("n", "gd", tb.lsp_definitions, vim.tbl_extend("force", o, { desc = "Go to definition" }))
            map("n", "gr", tb.lsp_references, vim.tbl_extend("force", o, { desc = "Find references" }))
            map("n", "gi", tb.lsp_implementations, vim.tbl_extend("force", o, { desc = "Go to implementation" }))
            map("n", "gy", tb.lsp_type_definitions, vim.tbl_extend("force", o, { desc = "Go to type definition" }))

            map("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", o, { desc = "Rename symbol" }))
            map("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", o, { desc = "Code action" }))

            map("n", "<leader>ls", tb.lsp_document_symbols, vim.tbl_extend("force", o, { desc = "Document symbols" }))
            map("n", "<leader>lw", tb.lsp_dynamic_workspace_symbols,
                vim.tbl_extend("force", o, { desc = "Workspace symbols" }))
            map("n", "<leader>li", "<cmd>LspInfo<CR>", vim.tbl_extend("force", o, { desc = "LSP info" }))

            -- Inlay hints: enable on attach, toggle with <leader>lh
            if vim.lsp.inlay_hint and client.supports_method("textDocument/inlayHint") then
                vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                map("n", "<leader>lh", function()
                    vim.lsp.inlay_hint.enable(
                        not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
                        { bufnr = bufnr }
                    )
                end, vim.tbl_extend("force", o, { desc = "Toggle inlay hints" }))
            end
        end

        require("roslyn").setup({
            config = {
                capabilities = capabilities,
                on_attach    = on_attach,
                settings     = {
                    ["csharp|inlay_hints"] = {
                        csharp_enable_inlay_hints_for_implicit_object_creation              = true,
                        csharp_enable_inlay_hints_for_implicit_variable_types               = true,
                        csharp_enable_inlay_hints_for_lambda_parameter_types                = true,
                        csharp_enable_inlay_hints_for_types                                 = true,
                        dotnet_enable_inlay_hints_for_parameters                            = true,
                        dotnet_enable_inlay_hints_for_object_creation_parameters            = true,
                        dotnet_enable_inlay_hints_for_other_parameters                      = true,
                        -- suppress noise
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
            },
        })
    end,
}
