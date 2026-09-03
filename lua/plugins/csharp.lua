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
                "--logLevel=Warning",
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
                    -- Off: this is a find-all-references per declaration per
                    -- document. Against ERM.sln (46 projects, ~4.7k files) it's
                    -- the most expensive Roslyn toggle there is -- Visual
                    -- Studio keeps it opt-in for the same reason.
                    dotnet_enable_references_code_lens = false,
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

                -- Enforce the "off by default" that the settings block
                -- above only describes: inlay hints are the heaviest
                -- per-keystroke request after CodeLens, and the log showed them
                -- being requested against misc-file buffers where they cannot
                -- resolve at all. <leader>lh still enables them for the buffer
                -- you are in.
                vim.lsp.inlay_hint.enable(false, { bufnr = args.buf })

                -- Roslyn cold-start quirk: before its semantic model is ready it
                -- tags every identifier generically as `variable`, so on the
                -- FIRST buffer it attaches to, method/type calls come back as
                -- @lsp.type.variable.cs (white) and -- at priority 125 -- beat
                -- treesitter's correct @function.method.call.c_sharp (100). Once
                -- warm (later buffers, or a manual re-enter) Roslyn returns the
                -- real `method`/`type` classification. So we just need to
                -- re-request tokens once it's warm. projectInitializationComplete
                -- means the project LOADED, but the per-document semantic model
                -- can lag a little, so re-request a couple of times after it to
                -- reliably land on the refined classification. Wrap once per
                -- client, preserving roslyn.nvim's own handler, and run the
                -- staggered refresh only on the first init-complete.
                if not client.semantic_refresh_hooked then
                    client.semantic_refresh_hooked = true
                    local method = "workspace/projectInitializationComplete"
                    local prev = client.handlers[method]
                    local refreshed = false
                    client.handlers[method] = function(err, res, ctx, cfg)
                        if prev then pcall(prev, err, res, ctx, cfg) end
                        if refreshed then return end
                        refreshed = true
                        for _, ms in ipairs({ 1000, 4000, 9000 }) do
                            vim.defer_fn(function()
                                for buf in pairs(client.attached_buffers) do
                                    if vim.api.nvim_buf_is_valid(buf) then
                                        pcall(vim.lsp.semantic_tokens.force_refresh, buf)
                                    end
                                end
                            end, ms)
                        end
                    end
                end
            end,
        })

        -- C:\Cris is a plain folder holding ~10 sibling repos, each its own
        -- git root and solution, so both of these have to be off.
        --
        -- lock_target: roslyn.nvim's root_dir short-circuits to
        -- vim.g.roslyn_nvim_selected_solution whenever it's set (see the
        -- plugin's lsp/roslyn.lua), so the FIRST solution opened in a session
        -- captured every C# buffer afterwards -- including files from the other
        -- nine repos, which that solution doesn't contain. Roslyn then falls
        -- back to a throwaway %TEMP%\roslyn-canonical-misc project with
        -- unresolved dependencies: no semantic model, so tokens, hints and
        -- completion all did the work and returned nothing usable.
        --
        -- broad_search: walks the whole git root, and the plugin's ignored_dirs
        -- is only obj/bin/.git -- node_modules is NOT excluded, which is 8.4k
        -- subdirs in cris-erm and 10.7k in cris-preaward-app, re-enumerated on
        -- every root resolution. Upward search finds the right .sln for these
        -- repos anyway. The exceptions are the two Aspire hosts that sit
        -- outside their solution's directory (cris-erm/local/AppHost and
        -- cris-preaward-app/local/AppHost, both referenced as ../local/...);
        -- reach those with `:Roslyn target`.
        require("roslyn").setup({
            broad_search = false,
            lock_target = false,
            -- Only consulted when SEVERAL solutions contain this file's csproj
            -- (cris-erm-tfs ships ERM.sln with 46 projects and unit-tests.sln
            -- with 5, and the test projects are in both). Pick the widest one
            -- so cross-project navigation resolves, instead of whichever the
            -- directory walk happened to return first.
            choose_target = function(targets)
                local sln_api = require("roslyn.sln.api")
                local best, best_count
                for _, target in ipairs(targets) do
                    local ok, projects = pcall(sln_api.projects, target)
                    local count = ok and #projects or 0
                    if not best_count or count > best_count then
                        best, best_count = target, count
                    end
                end
                return best or targets[1]
            end,
        })
    end,
}
