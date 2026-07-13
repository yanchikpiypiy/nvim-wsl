-- Debugging (DAP). easy-dotnet already auto-registers the netcoredbg adapter
-- (debugger.auto_register_dap = true in dotnet.lua), so this file just adds the
-- controls + a Rider-like UI. Start a session with <leader>nd (project) or `d`
-- in the test runner / a test file; then drive it with the keys below.
return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",          -- required by dap-ui
            "theHamsta/nvim-dap-virtual-text", -- inline variable values
        },
        -- Everything under <leader>nd (Debug), so nothing collides with your
        -- existing maps. Start a session with <leader>ndd (project) or
        -- <leader>ntd / d-in-runner (a test), then drive it with these.
        keys = {
            -- F-keys: fast, standard debugger layout (VS/Rider/VS Code muscle
            -- memory), no collisions with your config.
            { "<F5>",  function() require("dap").continue() end,          desc = "Debug: continue/start" },
            { "<F8>",  function() require("dap").step_out() end,          desc = "Debug: step out" },
            { "<F9>",  function() require("dap").toggle_breakpoint() end, desc = "Debug: breakpoint" },
            { "<F10>", function() require("dap").step_over() end,         desc = "Debug: step over" },
            { "<F11>", function() require("dap").step_into() end,         desc = "Debug: step into" },
            -- Same actions under <leader>nd (discover via which-key: press
            -- <leader>nd and wait for the menu).
            { "<leader>ndc", function() require("dap").continue() end,          desc = "Continue / start" },
            { "<leader>ndb", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
            { "<leader>ndB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Conditional breakpoint" },
            { "<leader>ndo", function() require("dap").step_over() end,         desc = "Step over" },
            { "<leader>ndi", function() require("dap").step_into() end,         desc = "Step into" },
            { "<leader>ndu", function() require("dap").step_out() end,          desc = "Step out" },
            { "<leader>ndr", function() require("dap").run_to_cursor() end,     desc = "Run to cursor" },
            { "<leader>ndq", function() require("dap").terminate() end,         desc = "Terminate session" },
            { "<leader>ndv", function() require("dapui").toggle({ reset = true }) end, desc = "Toggle debug UI" },
            { "<leader>nde", function() require("dapui").eval(nil, { enter = true }) end, mode = { "n", "v" }, desc = "Eval expression" },
            -- Zoom the variables panel into a big centered float (small screens).
            { "<leader>ndz", function() require("dapui").float_element("scopes", { enter = true, width = 130, height = 35 }) end, desc = "Zoom variables (float)" },
            -- Maximize/restore the CURRENT window (any panel: scopes, watches,
            -- repl, call stack, or your code). Focus a panel first with <C-w>w.
            {
                "<leader>ndm",
                function()
                    if vim.t.dap_zoomed then
                        vim.cmd("tabclose")
                    else
                        vim.cmd("tab split")
                        vim.t.dap_zoomed = true
                    end
                end,
                desc = "Maximize / restore panel",
            },
        },
        config = function()
            local dap, dapui = require("dap"), require("dapui")

            dapui.setup({
                -- Bigger Scopes (the variables you read most); drop the docked
                -- Breakpoints panel (you still get <F9> + gutter signs).
                -- Expand/collapse a variable with <CR> inside these windows.
                layouts = {
                    {
                        position = "left",
                        size = 44, -- columns
                        elements = {
                            { id = "scopes", size = 0.55 },
                            { id = "stacks", size = 0.27 },
                            { id = "watches", size = 0.18 },
                        },
                    },
                    {
                        position = "bottom",
                        size = 10, -- rows
                        elements = {
                            { id = "repl", size = 0.5 },
                            { id = "console", size = 0.5 },
                        },
                    },
                },
            })
            require("nvim-dap-virtual-text").setup({})

            -- Auto open/close the panels with the debug session. Open on
            -- event_initialized (once the adapter is ready — avoids empty
            -- windows) and reset=true so the layout snaps back to its initial
            -- sizes/positions every run instead of drifting.
            dap.listeners.after.event_initialized.dapui_config  = function() dapui.open({ reset = true }) end
            dap.listeners.before.event_terminated.dapui_config  = function() dapui.close() end
            dap.listeners.before.event_exited.dapui_config      = function() dapui.close() end

            -- Nicer signs in the gutter.
            vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
            vim.fn.sign_define("DapStopped",    { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual", numhl = "" })
        end,
    },
}
