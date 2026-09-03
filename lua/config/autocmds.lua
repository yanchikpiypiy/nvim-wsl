-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank({ timeout = 200 })
    end,
})

-- Safety net for Roslyn "go to definition" into SDK/package sources:
-- decompiled files under %TEMP%\MetadataAsSource can have mixed CRLF/LF that
-- nvim renders as literal ^M. Strip stray CRs for THESE temp buffers only
-- (read-only navigation targets) so they never touch real project files.
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function(args)
        local name = vim.api.nvim_buf_get_name(args.buf)
        if not name:lower():find("metadataassource", 1, true) then return end
        local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
        local changed = false
        for i, l in ipairs(lines) do
            local stripped = l:gsub("\r$", "")
            if stripped ~= l then lines[i] = stripped; changed = true end
        end
        if changed then
            vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, lines)
            vim.bo[args.buf].modified = false
        end
    end,
})

-- Auto-reload buffers when the file changes on disk (e.g. after applying a
-- stash / checking out / pulling in lazygit or the git CLI). `autoread` is on
-- by default, but nvim only *checks* for on-disk changes on certain events, so
-- we nudge it with `:checktime`. Skip command-line/prompt modes where reloading
-- would be disruptive.
local reload_group = vim.api.nvim_create_augroup("AutoReloadOnDiskChange", { clear = true })
-- CursorHold/CursorHoldI are deliberately NOT here. With updatetime=250 they
-- fired a bare `:checktime` -- which re-stats EVERY loaded buffer -- four times
-- a second of idle, and stat is far more expensive on Windows than on Linux.
-- These events cover the cases that actually matter: coming back to the
-- terminal, and returning from lazygit.
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = reload_group,
    callback = function()
        if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
            vim.cmd("checktime")
        end
    end,
})

-- Entering a buffer only needs to re-stat that one buffer, not all of them.
vim.api.nvim_create_autocmd("BufEnter", {
    group = reload_group,
    callback = function(args)
        if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
            pcall(vim.cmd, "checktime " .. args.buf)
        end
    end,
})

-- Notify when a buffer was reloaded because the file changed underneath us.
vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = reload_group,
    callback = function()
        vim.notify("File changed on disk — buffer reloaded", vim.log.levels.INFO)
    end,
})

-- Consistent dismissal: press `q` to close transient / read-only windows.
-- Neovim's built-in help, quickfix, man, checkhealth, LSP-info and notification
-- buffers have NO `q` mapping by default (you'd have to `:q`), while the plugin
-- panels you use already close on `q` (trouble, diffview, neo-tree, harpoon,
-- lazygit). This unifies them so the rule is simply:
--   navigating a panel -> `q`   |   typing in a picker/prompt -> <Esc>
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("CloseWithQ", { clear = true }),
    pattern = {
        "help", "qf", "man", "checkhealth", "lspinfo", "notify",
        "startuptime", "query", "tsplayground", "gitsigns-blame",
        "dbout", "netrw",
    },
    callback = function(args)
        vim.bo[args.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<CR>", {
            buffer = args.buf,
            silent = true,
            nowait = true,
            desc = "Close window",
        })
    end,
})

-- gitsigns `diffthis` (<leader>gd) opens the index version in a scratch diff
-- split whose buffer is named `gitsigns://...`. It's a real (filetyped) buffer,
-- so the CloseWithQ FileType rule above doesn't catch it. Map `q` here too so
-- the diff closes the same way every other panel does.
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("CloseGitDiffWithQ", { clear = true }),
    callback = function(args)
        if vim.api.nvim_buf_get_name(args.buf):match("^gitsigns://") then
            -- Turn diff off everywhere (so the file window leaves diff mode too)
            -- then close this base split — full revert to a single pane.
            vim.keymap.set("n", "q", "<cmd>diffoff!<bar>close<CR>", {
                buffer = args.buf,
                silent = true,
                nowait = true,
                desc = "Close diff",
            })
        end
    end,
})

-- Conceal markdown escape sequences (fixes backslashes in LSP hover)
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.opt_local.conceallevel = 2
    end,
})

-- ===============================
-- LSP activity notifications (via the snacks notifier)
-- ===============================
local lsp_notify_group = vim.api.nvim_create_augroup("LspNotify", { clear = true })

-- Progress toasts: surface what the server is doing (Roslyn/clangd indexing,
-- workspace load, etc.). One toast per operation, updated in place by `id`,
-- so it doesn't spam — it just tells you "still loading" then "done".
vim.api.nvim_create_autocmd("LspProgress", {
    group = lsp_notify_group,
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local val = ev.data.params and ev.data.params.value
        if not client or type(val) ~= "table" then return end

        local id = "lsp_progress_" .. ev.data.client_id .. "_" .. tostring(ev.data.params.token)
        if val.kind == "end" then
            vim.notify(val.title or "Done", vim.log.levels.INFO, {
                id = id, title = client.name, icon = "", timeout = 1500,
            })
        else
            local msg = val.title or ""
            if val.message then msg = msg .. " — " .. val.message end
            if val.percentage then msg = ("%s (%d%%)"):format(msg, val.percentage) end
            vim.notify(msg, vim.log.levels.INFO, {
                id = id, title = client.name, icon = "", timeout = 8000,
            })
        end
    end,
})

-- Attach toast: confirm a language server actually came up for this file.
-- Deduped per client so opening many files in one project shows it just once.
local notified_clients = {}
vim.api.nvim_create_autocmd("LspAttach", {
    group = lsp_notify_group,
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and not notified_clients[client.id] then
            notified_clients[client.id] = true
            vim.notify("Attached: " .. client.name, vim.log.levels.INFO, {
                title = "LSP", icon = "",
            })
        end
    end,
})
