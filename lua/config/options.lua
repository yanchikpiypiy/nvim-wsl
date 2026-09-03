local opt = vim.opt

-- Semantic tokens win over treesitter (Roslyn is more accurate for C#)
vim.hl.priorities.semantic_tokens = 125

opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true
opt.signcolumn = "yes"
opt.termguicolors = true
-- Prefer LF, but auto-detect and consume CRLF (dos) so SDK/decompiled
-- metadata sources don't render every line ending as a literal ^M.
opt.fileformats = { "unix", "dos" }
opt.updatetime = 250
opt.timeoutlen = 300
-- System clipboard: auto-sync every yank to the + register.
-- Explicit <leader>y/Y/p maps also live in keymaps.lua as a fallback.
opt.clipboard = "unnamedplus"
-- Under WSL the provider is win32yank, which pays a slow detection cost on
-- first use; warm it up off the startup path so that cost isn't taken
-- mid-edit. Native Wayland/X11 providers are fast and warming them just makes
-- wl-paste print "Nothing is copied" on an empty clipboard at every launch.
if vim.fn.has("wsl") == 1 then
    vim.schedule(function()
        pcall(vim.fn.getreg, "+")
    end)
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- Diagnostic configuration
vim.diagnostic.config({
    virtual_text = {
        spacing = 4,
        prefix = "●",
        source = true,
        severity = { min = vim.diagnostic.severity.ERROR },
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "✘",
            [vim.diagnostic.severity.WARN]  = "▲",
            [vim.diagnostic.severity.HINT]  = "⚑",
            [vim.diagnostic.severity.INFO]  = "»",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
            [vim.diagnostic.severity.WARN]  = "DiagnosticSignWarn",
            [vim.diagnostic.severity.HINT]  = "DiagnosticSignHint",
            [vim.diagnostic.severity.INFO]  = "DiagnosticSignInfo",
        },
    },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
        header = "",
        prefix = "",
    },
})

-- Autosave on leaving insert mode, debounced per buffer. Each write fires a
-- didSave, which makes Roslyn reanalyse the project and gitsigns re-diff the
-- file, so dipping in and out of insert mode used to queue a full round of that
-- every time. Coalescing to one write after a pause keeps the autosave without
-- the churn.
local AUTOSAVE_DEBOUNCE_MS = 1500
local autosave_timers = {}

local function cancel_autosave(bufnr)
    local timer = autosave_timers[bufnr]
    if timer then
        timer:stop()
        timer:close()
        autosave_timers[bufnr] = nil
    end
end

vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function(args)
        local bufnr = args.buf
        local bo = vim.bo[bufnr]
        -- skip special / readonly / non-modifiable / unnamed buffers (avoids E45)
        if bo.buftype ~= "" or bo.readonly or not bo.modifiable then return end
        if vim.api.nvim_buf_get_name(bufnr) == "" then return end

        cancel_autosave(bufnr)
        local timer = vim.uv.new_timer()
        autosave_timers[bufnr] = timer
        timer:start(AUTOSAVE_DEBOUNCE_MS, 0, vim.schedule_wrap(function()
            cancel_autosave(bufnr)
            if not vim.api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].modified then return end
            -- Skip format-on-save for this auto-write (prettier on every
            -- InsertLeave is what made the frontend feel laggy). Explicit :w
            -- and <leader>f still format.
            vim.b[bufnr].skip_format_on_save = true
            -- The timer can fire after you have moved to another buffer, so the
            -- write has to be aimed at the buffer that scheduled it.
            vim.api.nvim_buf_call(bufnr, function()
                pcall(vim.cmd, "silent write")
            end)
            vim.b[bufnr].skip_format_on_save = false
        end))
    end,
})

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    callback = function(args) cancel_autosave(args.buf) end,
})
