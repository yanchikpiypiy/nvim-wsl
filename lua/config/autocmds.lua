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

-- Conceal markdown escape sequences (fixes backslashes in LSP hover)
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.opt_local.conceallevel = 2
    end,
})
