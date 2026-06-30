local opt = vim.opt

-- Semantic tokens win over treesitter (Roslyn is more accurate for C#)
vim.highlight.priorities.semantic_tokens = 125

opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.fileformats = { "unix" }
opt.updatetime = 250
opt.timeoutlen = 300

vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- Diagnostic configuration
vim.diagnostic.config({
    virtual_text = {
        spacing = 4,
        prefix = "●",
        source = "always",
        severity = { min = vim.diagnostic.severity.ERROR },
    },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
    },
})

vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local bo = vim.bo[bufnr]
        -- skip special / readonly / non-modifiable / unnamed buffers (avoids E45)
        if bo.buftype ~= "" or bo.readonly or not bo.modifiable then return end
        if vim.api.nvim_buf_get_name(bufnr) == "" then return end
        if bo.modified then
            pcall(vim.cmd, "silent write")
        end
    end,
})

-- Roslyn (C#) semantic token colors, matched to the monochrome scheme.
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        -- Monochrome palette
        local grey   = "#a6a6a6"  -- types
        local red    = "#e85c6a"  -- methods
        local lav     = "#d8bdf3"  -- functions
        local pink    = "#dd8a9c"  -- properties / fields
        local amber  = "#d6a06a"  -- constants / enum members
        local white  = "#eeeeee"  -- variables / parameters

        local hls = {
            -- Types
            ["@lsp.type.namespace.cs"]           = { fg = grey },
            ["@lsp.type.type.cs"]                = { fg = grey },
            ["@lsp.type.class.cs"]               = { fg = grey },
            ["@lsp.type.interface.cs"]           = { fg = grey },
            ["@lsp.type.struct.cs"]              = { fg = grey },
            ["@lsp.type.enum.cs"]                = { fg = grey },
            ["@lsp.type.delegate.cs"]            = { fg = grey },
            ["@lsp.type.typeParameter.cs"]       = { fg = grey },
            ["@lsp.type.recordClass.cs"]         = { fg = grey },
            ["@lsp.type.recordStruct.cs"]        = { fg = grey },
            -- Members
            ["@lsp.type.method.cs"]              = { fg = red },
            ["@lsp.type.extensionMethod.cs"]     = { fg = red },
            ["@lsp.type.function.cs"]            = { fg = lav },
            ["@lsp.type.operatorOverloaded.cs"]  = { fg = red },
            ["@lsp.type.property.cs"]            = { fg = pink },
            ["@lsp.type.field.cs"]               = { fg = pink },
            ["@lsp.type.event.cs"]               = { fg = pink },
            ["@lsp.type.enumMember.cs"]          = { fg = amber },
            ["@lsp.type.constant.cs"]            = { fg = amber },
            -- Variables
            ["@lsp.type.variable.cs"]            = { fg = white },
            ["@lsp.type.parameter.cs"]           = { fg = white, italic = true },
            ["@lsp.type.local.cs"]               = { fg = white },
            -- Modifiers (style only, don't change color)
            ["@lsp.mod.static.cs"]               = { italic = true },
            ["@lsp.mod.readonly.cs"]             = { italic = true },
            ["@lsp.mod.deprecated.cs"]           = { strikethrough = true },
        }
        for group, hl in pairs(hls) do
            vim.api.nvim_set_hl(0, group, hl)
        end
    end,
})

vim.cmd("doautocmd ColorScheme")

local signs = { Error = "✘", Warn = "▲", Hint = "⚑", Info = "»" }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
