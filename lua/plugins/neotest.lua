-- neotest: in-editor test runner for the FRONTEND (Vitest / React / TS).
-- C# tests use easy-dotnet's own runner (see dotnet.lua) — its native runner
-- is cleaner and discovers .NET tests more reliably than the neotest adapter.
-- Keys under <leader>t (Test) don't touch the C# side (<leader>nt).
return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "marilari88/neotest-vitest",
    },
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    keys = {
        { "<leader>tt", function() require("neotest").run.run() end,                        desc = "Run nearest test" },
        { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end,       desc = "Run file tests" },
        { "<leader>tl", function() require("neotest").run.run_last() end,                    desc = "Run last test" },
        { "<leader>ts", function() require("neotest").summary.toggle() end,                  desc = "Toggle summary tree" },
        { "<leader>to", function() require("neotest").output.open({ enter = true }) end,     desc = "Show test output" },
        { "<leader>tO", function() require("neotest").output_panel.toggle() end,             desc = "Toggle output panel" },
        { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end,  desc = "Watch file tests" },
        { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end,     desc = "Debug nearest test" },
        { "<leader>tS", function() require("neotest").run.stop() end,                        desc = "Stop test run" },
    },
    config = function()
        require("neotest").setup({
            adapters = {
                require("neotest-vitest"),
            },
        })
    end,
}
