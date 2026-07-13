-- easy-dotnet.nvim: .NET workflow QoL (build/run/test/secrets/nuget/EF).
-- IMPORTANT: its bundled Roslyn LSP is DISABLED here so it coexists with our
-- tuned roslyn.nvim setup (see lua/plugins/csharp.lua). roslyn.nvim remains the
-- sole source of code intelligence; easy-dotnet only handles tooling/workflow.
return {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "folke/snacks.nvim",
        "mfussenegger/nvim-dap",
    },
    -- Load on C# work or when a :Dotnet command is used.
    ft = { "cs", "fsharp", "razor" },
    cmd = "Dotnet",
    config = function()
        require("easy-dotnet").setup({
            -- Let roslyn.nvim own the language server; don't start a second one.
            lsp = { enabled = false },

            picker = "snacks",

            test_runner = {
                -- C# tests use easy-dotnet's OWN runner (cleaner + more reliable
                -- discovery than routing C# through neotest). neotest handles the
                -- frontend (TS) only. Best-of-both instead of forced unification.
                auto_start_testrunner = true,
                neotest_integration = false,
                viewmode = "float",
                mappings = {
                    -- Runner window (buffer-local, plain keys): open with <leader>ntt
                    run             = { lhs = "r",    desc = "run test" },
                    run_all         = { lhs = "R",    desc = "run all tests" },
                    debug_test      = { lhs = "d",    desc = "debug test" },
                    go_to_file      = { lhs = "gd",   desc = "go to source" },
                    peek_stacktrace = { lhs = "p",    desc = "peek stacktrace" },
                    -- In a C# test source file (nested under <leader>nt = dotnet Test)
                    run_test_from_buffer         = { lhs = "<leader>ntr", desc = "run test at cursor" },
                    debug_test_from_buffer       = { lhs = "<leader>ntd", desc = "debug test at cursor" },
                    run_all_tests_from_buffer    = { lhs = "<leader>nta", desc = "run all tests in file" },
                    peek_stack_trace_from_buffer = { lhs = "<leader>ntp", desc = "peek test output" },
                },
            },

            debugger = {
                engine = "netcoredbg", -- bundled with the plugin
                console = "integratedTerminal",
                auto_register_dap = true, -- registers the dap adapter for :Dotnet debug
            },
        })

        -- dotnet maps under <leader>n ("dotNet"). C# TESTS = <leader>nt (Test),
        -- Debug = <leader>nd. Frontend (TS) tests are neotest under <leader>t.
        local map = vim.keymap.set
        map("n", "<leader>nr",  "<cmd>Dotnet run<cr>",         { desc = "Run project" })
        map("n", "<leader>nb",  "<cmd>Dotnet build<cr>",       { desc = "Build" })
        map("n", "<leader>ntt", "<cmd>Dotnet testrunner<cr>",  { desc = "Open test runner" })
        map("n", "<leader>ndd", "<cmd>Dotnet debug<cr>",       { desc = "Debug project (start)" })
        map("n", "<leader>ns",  "<cmd>Dotnet secrets<cr>",     { desc = "User-secrets" })
        map("n", "<leader>np",  "<cmd>Dotnet add package<cr>", { desc = "Add NuGet package" })

        -- New file, no path typing: use the folder under the cursor in neo-tree,
        -- else the directory of the file you're editing. Always lands inside a
        -- project so you avoid the "no project at this path" error.
        map("n", "<leader>nf", function()
            local dir
            if vim.bo.filetype == "neo-tree" then
                local ok, mgr = pcall(require, "neo-tree.sources.manager")
                local node = ok and mgr.get_state("filesystem").tree:get_node()
                if node then
                    dir = node.type == "directory" and node.path or vim.fs.dirname(node.path)
                end
            end
            if not dir then
                local file = vim.fn.expand("%:p")
                dir = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
            end
            -- create_new_item uses a coroutine-based picker (pick_sync yields),
            -- so it must run inside a coroutine — a direct call from the keymap
            -- errors with "attempt to yield across C-call boundary".
            coroutine.wrap(function()
                require("easy-dotnet.actions.new").create_new_item(dir)
            end)()
        end, { desc = ".NET new file (here)" })

        -- In the runner window, <CR> also opens the test's source (like `gd`).
        -- Buffer-local to that float, so it doesn't touch your global maps.
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "easy-dotnet",
            callback = function(ev)
                vim.keymap.set("n", "<cr>", "gd",
                    { buffer = ev.buf, remap = true, silent = true, desc = "go to source" })
            end,
        })
    end,
}
