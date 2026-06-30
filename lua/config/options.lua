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
        if vim.bo[bufnr].buftype ~= "" then return end
        if vim.bo[bufnr].modified then
            vim.cmd("silent write")
        end
    end,
})

-- Roslyn semantic token highlights (everforest doesn't define these)
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        -- Everforest palette
        local yellow  = "#dbbc7f"
        local green   = "#a7c080"
        local blue    = "#7fbbb3"
        local purple  = "#d699b6"
        local red     = "#e67e80"
        local orange  = "#e69875"
        local aqua    = "#83c092"
        local fg      = "#d3c6aa"

        local hls = {
            -- Types
            ["@lsp.type.namespace.cs"]           = { fg = aqua },
            ["@lsp.type.type.cs"]                = { fg = yellow },
            ["@lsp.type.class.cs"]               = { fg = yellow },
            ["@lsp.type.interface.cs"]           = { fg = yellow },
            ["@lsp.type.struct.cs"]              = { fg = yellow },
            ["@lsp.type.enum.cs"]                = { fg = yellow },
            ["@lsp.type.delegate.cs"]            = { fg = yellow },
            ["@lsp.type.typeParameter.cs"]       = { fg = yellow },
            ["@lsp.type.recordClass.cs"]         = { fg = yellow },
            ["@lsp.type.recordStruct.cs"]        = { fg = yellow },
            -- Members
            ["@lsp.type.method.cs"]              = { fg = green },
            ["@lsp.type.extensionMethod.cs"]     = { fg = green },
            ["@lsp.type.function.cs"]            = { fg = green },
            ["@lsp.type.operatorOverloaded.cs"]  = { fg = green },
            ["@lsp.type.property.cs"]            = { fg = blue },
            ["@lsp.type.field.cs"]               = { fg = blue },
            ["@lsp.type.event.cs"]               = { fg = blue },
            ["@lsp.type.enumMember.cs"]          = { fg = purple },
            ["@lsp.type.constant.cs"]            = { fg = purple },
            -- Variables
            ["@lsp.type.variable.cs"]            = { fg = fg },
            ["@lsp.type.parameter.cs"]           = { fg = orange },
            ["@lsp.type.local.cs"]               = { fg = fg },
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
