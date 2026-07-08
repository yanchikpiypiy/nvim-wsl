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
-- System clipboard: auto-sync every yank to the + register.
-- On Windows-native nvim this uses the OS clipboard directly (no warm-up
-- needed). Under WSL it goes through win32yank; the vim.schedule below warms
-- the provider so the first yank doesn't pay the detection cost mid-edit.
-- Explicit <leader>y/Y/p maps also live in keymaps.lua as a fallback.
opt.clipboard = "unnamedplus"
vim.schedule(function()
    pcall(vim.fn.getreg, "+")
end)

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
        local grey   = "#a6a6a6"  -- namespaces (recede)
        local sage    = "#7fc9b0"  -- types (C#-only accent: bright teal-green, bold)
        local red    = "#e85c6a"  -- methods
        local lav     = "#d8bdf3"  -- functions
        local pink    = "#dd8a9c"  -- properties / fields
        local amber  = "#d6a06a"  -- constants / enum members
        local white  = "#eeeeee"  -- variables / parameters
        local purple  = "#9a6dd7"  -- keywords / control flow / preprocessor
        local strgrey = "#d4d4d4"  -- strings
        local comment = "#5e5e5e"  -- comments / excluded code / xml doc

        local hls = {
            -- Types
            ["@lsp.type.namespace.cs"]           = { fg = grey },
            ["@lsp.type.type.cs"]                = { fg = sage, bold = true },
            ["@lsp.type.class.cs"]               = { fg = sage, bold = true },
            ["@lsp.type.interface.cs"]           = { fg = sage, bold = true },
            ["@lsp.type.struct.cs"]              = { fg = sage, bold = true },
            ["@lsp.type.enum.cs"]                = { fg = sage, bold = true },
            ["@lsp.type.delegate.cs"]            = { fg = sage, bold = true },
            ["@lsp.type.typeParameter.cs"]       = { fg = sage, bold = true },
            ["@lsp.type.recordClass.cs"]         = { fg = sage, bold = true },
            ["@lsp.type.recordStruct.cs"]        = { fg = sage, bold = true },
            -- Members
            ["@lsp.type.method.cs"]              = { fg = red },
            ["@lsp.type.extensionMethod.cs"]     = { fg = red },
            ["@lsp.type.function.cs"]            = { fg = lav },
            ["@lsp.type.operatorOverloaded.cs"]  = { fg = red },
            -- Static methods are the closest C# analog to C++ free functions,
            -- so paint them lavender (typemod wins over the plain method token).
            -- italic kept to match the static-modifier convention below.
            ["@lsp.typemod.method.static.cs"]    = { fg = lav, italic = true },
            ["@lsp.type.property.cs"]            = { fg = pink },
            ["@lsp.type.field.cs"]               = { fg = pink },
            ["@lsp.type.event.cs"]               = { fg = pink },
            ["@lsp.type.enumMember.cs"]          = { fg = amber },
            ["@lsp.type.constant.cs"]            = { fg = amber },
            -- Variables
            ["@lsp.type.variable.cs"]            = { fg = white },
            ["@lsp.type.parameter.cs"]           = { fg = white, italic = true },
            ["@lsp.type.local.cs"]               = { fg = white },
            -- Keywords / control flow / preprocessor (Roslyn classifies these
            -- separately; they have no Neovim default link, so set explicitly)
            ["@lsp.type.keyword.cs"]             = { fg = purple },
            ["@lsp.type.controlKeyword.cs"]      = { fg = purple },
            ["@lsp.type.preprocessorKeyword.cs"] = { fg = purple },
            -- Strings (verbatim @"..." + escape chars \n \t {{ pop in amber)
            ["@lsp.type.string.cs"]              = { fg = strgrey },
            ["@lsp.type.stringVerbatim.cs"]      = { fg = strgrey },
            ["@lsp.type.stringEscapeCharacter.cs"] = { fg = amber },
            -- Comments / excluded (#if false) code / XML doc comments
            ["@lsp.type.comment.cs"]                     = { fg = comment, italic = true },
            ["@lsp.type.excludedCode.cs"]                = { fg = comment },
            ["@lsp.type.xmlDocCommentText.cs"]           = { fg = comment, italic = true },
            ["@lsp.type.xmlDocCommentDelimiter.cs"]      = { fg = comment, italic = true },
            ["@lsp.type.xmlDocCommentComment.cs"]        = { fg = comment, italic = true },
            ["@lsp.type.xmlDocCommentName.cs"]           = { fg = grey,    italic = true },
            ["@lsp.type.xmlDocCommentAttributeName.cs"]  = { fg = grey,    italic = true },
            ["@lsp.type.xmlDocCommentAttributeValue.cs"] = { fg = comment, italic = true },
            ["@lsp.type.xmlDocCommentAttributeQuotes.cs"]= { fg = comment, italic = true },
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
