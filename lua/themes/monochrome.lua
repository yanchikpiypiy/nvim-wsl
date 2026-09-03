-- Hand-rolled theme: greyscale monochrome base + accents + matching UI chrome,
-- plus Roslyn (C#) semantic-token colours in the same palette.
-- Picked up automatically by config/theme.lua (every file in lua/themes/ is a theme).
return {
    name = "Monochrome",
    desc = "greyscale + accents, tuned for C++/C#",
    base = "monochrome",  -- plugin colorscheme (kdheepak/monochrome.nvim) we paint over
    background = "dark",
    highlights = function()
        local c = {
            -- syntax
            members = "#dd8a9c",  -- members / properties (soft red-pink)
            var     = "#eeeeee",  -- plain variables (white)
            func    = "#d8bdf3",  -- free functions (Spinel lavender, leaned pink so it's bright, not blue)
            method  = "#e85c6a",  -- class methods (red-pink)
            keyword = "#9a6dd7",  -- keywords / qualifiers / macros (dark purple)
            type    = "#F9E2AF",  -- types, generics / type parameters (Catppuccin Mocha yellow)
            iface   = "#94e2d5",  -- interfaces (Catppuccin Mocha teal)
            number  = "#d6a06a",  -- numbers / booleans (amber)
            string  = "#d0ccc0",  -- strings (light grey with a hint of yellow)
            comment = "#5e5e5e",  -- comments (dim grey)
            hint    = "#7e8a96",  -- LSP inlay hints (cool grey, own tone)
            -- ui / chrome
            bg      = "#0e0e0e",
            panel   = "#161616",  -- float / picker background
            raised  = "#1d1d1d",  -- prompt / scrollbar
            sel     = "#2a2a2a",  -- selection background
            border  = "#3a3a3a",
            fg      = "#eeeeee",
            dim     = "#6e6e6e",
            accent  = "#e85c6a",  -- selection caret / matching / titles
            -- diagnostics (muted but distinct)
            err     = "#e06c75",
            warn    = "#d6a06a",
            info    = "#8a96a6",
            ok      = "#9ec07c",
            add     = "#7a9a6a",
            chg     = "#8a96a6",
            del     = "#cf6a6a",
        }
        local hl = {
            -- objects' members & properties (transform.position)
            ["@variable.member"] = { fg = c.members },
            ["@property"]        = { fg = c.members },
            ["@field"]           = { fg = c.members },
            -- plain variables
            ["@variable"]  = { fg = c.var },
            ["Identifier"] = { fg = c.var },
            -- free functions vs class methods (now distinct)
            ["@function"]      = { fg = c.func, bold = true },
            ["@function.call"] = { fg = c.func, bold = true },
            ["Function"]       = { fg = c.func, bold = true },
            ["@function.method"]      = { fg = c.method, bold = true },
            ["@function.method.call"] = { fg = c.method, bold = true },
            -- keywords, qualifiers (constexpr), macros
            ["Keyword"]              = { fg = c.keyword },
            ["@keyword"]             = { fg = c.keyword },
            ["@keyword.function"]    = { fg = c.keyword },
            ["@keyword.return"]      = { fg = c.keyword },
            ["@keyword.conditional"] = { fg = c.keyword },
            ["@keyword.repeat"]      = { fg = c.keyword },
            ["@keyword.operator"]    = { fg = c.keyword },
            ["@keyword.modifier"]    = { fg = c.keyword },
            ["@keyword.directive"]   = { fg = c.keyword },
            ["@type.qualifier"]      = { fg = c.keyword },
            ["StorageClass"]         = { fg = c.keyword },
            ["@constant.macro"]      = { fg = c.keyword },
            ["@function.macro"]      = { fg = c.keyword },
            ["Define"]               = { fg = c.keyword },
            ["PreProc"]              = { fg = c.keyword },
            ["Conditional"]          = { fg = c.keyword },
            ["Repeat"]               = { fg = c.keyword },
            ["Statement"]            = { fg = c.keyword },
            -- builtin constants (nullptr, this, NULL) -> keyword purple
            ["@constant.builtin"]    = { fg = c.keyword },
            ["@variable.builtin"]    = { fg = c.keyword },
            -- types
            ["Type"]             = { fg = c.type },
            ["@type"]            = { fg = c.type },
            ["@type.builtin"]    = { fg = c.type },
            ["@type.definition"] = { fg = c.type },
            ["Structure"]        = { fg = c.type },
            -- semantic tokens (clangd for C++, roslyn for C#): same gold for every
            -- kind of type name, generics included. Verify a group with :Inspect.
            ["@lsp.type.class"]         = { fg = c.type },
            ["@lsp.type.struct"]        = { fg = c.type },
            ["@lsp.type.enum"]          = { fg = c.type },
            ["@lsp.type.type"]          = { fg = c.type },
            ["@lsp.type.typeParameter"] = { fg = c.type },
            ["@lsp.type.typeparameter"] = { fg = c.type },
            ["@lsp.type.delegate"]      = { fg = c.type },
            ["@lsp.type.record"]        = { fg = c.type },
            -- namespaces (std::, YanMesh::): muted grey so routing noise recedes.
            -- Without this they inherit Structure's gold via the default @module link.
            ["@module"]             = { fg = "#a6a6a6" },
            ["@namespace"]          = { fg = "#a6a6a6" },
            ["@lsp.type.namespace"] = { fg = "#a6a6a6" },
            -- interfaces: mint, so a contract reads differently from a concrete type
            ["@lsp.type.interface"]     = { fg = c.iface },
            ["@type.interface"]         = { fg = c.iface },
            -- numbers / booleans
            ["Number"]        = { fg = c.number },
            ["@number"]       = { fg = c.number },
            ["Float"]         = { fg = c.number },
            ["@number.float"] = { fg = c.number },
            ["Boolean"]       = { fg = c.number },
            ["@boolean"]      = { fg = c.number },
            -- strings (kill any stray bright-green String)
            ["String"]  = { fg = c.string },
            ["@string"] = { fg = c.string },
            -- comments
            ["Comment"]  = { fg = c.comment, italic = true },
            ["@comment"] = { fg = c.comment, italic = true },
            -- LSP inlay hints (own cool grey; were green via NonText)
            ["LspInlayHint"] = { fg = c.hint, italic = true },

            -- brighter greyscale highlights
            ["CursorLine"] = { bg = "#1d1d1d" },
            ["Visual"]     = { bg = "#3a3a3a" },
            ["Search"]     = { bg = "#6b6b6b", fg = c.bg },
            ["IncSearch"]  = { bg = "#a0a0a0", fg = c.bg },

            -- ---- visibility: matching brackets, TODOs, diagnostic squiggles ----
            ["MatchParen"]     = { bg = "#3a3a3a", bold = true },
            ["Todo"]           = { fg = c.bg, bg = c.warn, bold = true },
            ["@comment.todo"]  = { fg = c.bg, bg = c.warn, bold = true },
            ["@comment.error"] = { fg = c.bg, bg = c.err, bold = true },
            ["DiagnosticUnderlineError"] = { undercurl = true, sp = c.err },
            ["DiagnosticUnderlineWarn"]  = { undercurl = true, sp = c.warn },
            ["DiagnosticUnderlineInfo"]  = { undercurl = true, sp = c.info },
            ["DiagnosticUnderlineHint"]  = { undercurl = true, sp = c.hint },

            -- ---- UI chrome: floats / popups ----
            ["NormalFloat"]  = { fg = c.fg, bg = c.panel },
            ["FloatBorder"]  = { fg = c.border, bg = c.panel },
            ["FloatTitle"]   = { fg = c.accent, bg = c.panel, bold = true },
            ["WinSeparator"] = { fg = c.border },
            -- completion menu (builtin pmenu + blink.cmp)
            ["Pmenu"]      = { fg = c.fg, bg = c.panel },
            ["PmenuSel"]   = { fg = c.fg, bg = c.sel, bold = true },
            ["PmenuSbar"]  = { bg = c.raised },
            ["PmenuThumb"] = { bg = c.border },
            ["PmenuMatch"] = { fg = c.accent, bold = true },
            ["BlinkCmpMenu"]          = { fg = c.fg, bg = c.panel },
            ["BlinkCmpMenuBorder"]    = { fg = c.border, bg = c.panel },
            ["BlinkCmpMenuSelection"] = { bg = c.sel, bold = true },
            ["BlinkCmpLabelMatch"]    = { fg = c.accent, bold = true },
            ["BlinkCmpDoc"]           = { fg = c.fg, bg = c.panel },
            ["BlinkCmpDocBorder"]     = { fg = c.border, bg = c.panel },
            -- inline ghost/suggestion text + non-text glyphs (were olive-green via NonText)
            ["BlinkCmpGhostText"] = { fg = "#6a6a6a", italic = true },
            ["NonText"]           = { fg = "#3a3a3a" },
            ["ComplHint"]         = { fg = "#6a6a6a", italic = true },
            -- ---- snacks.picker ----
            ["SnacksPickerNormal"]        = { fg = c.fg, bg = c.panel },
            ["SnacksPickerBorder"]        = { fg = c.border, bg = c.panel },
            ["SnacksPickerTitle"]         = { fg = c.bg, bg = c.accent, bold = true },
            ["SnacksPickerFooter"]        = { fg = c.dim, bg = c.panel },
            ["SnacksPickerPrompt"]        = { fg = c.accent, bg = c.panel },
            ["SnacksPickerInput"]         = { fg = c.fg, bg = c.raised },
            ["SnacksPickerInputBorder"]   = { fg = c.raised, bg = c.raised },
            ["SnacksPickerInputSearch"]   = { fg = c.accent, bg = c.raised },
            ["SnacksPickerList"]          = { fg = c.fg, bg = c.panel },
            ["SnacksPickerListBorder"]    = { fg = c.border, bg = c.panel },
            ["SnacksPickerPreview"]       = { fg = c.fg, bg = c.panel },
            ["SnacksPickerPreviewBorder"] = { fg = c.border, bg = c.panel },
            ["SnacksPickerPreviewTitle"]  = { fg = c.bg, bg = c.dim, bold = true },
            ["SnacksPickerMatch"]         = { fg = c.accent, bold = true },
            ["SnacksPickerSelected"]      = { fg = c.accent },
            ["SnacksPickerDir"]           = { fg = c.dim },
            ["SnacksPickerCursorLine"]    = { bg = c.sel, bold = true },
            -- ---- diagnostics ----
            ["DiagnosticError"] = { fg = c.err },
            ["DiagnosticWarn"]  = { fg = c.warn },
            ["DiagnosticInfo"]  = { fg = c.info },
            ["DiagnosticHint"]  = { fg = c.hint },
            ["DiagnosticOk"]    = { fg = c.ok },
            -- ---- git signs / diff ----
            ["GitSignsAdd"]    = { fg = c.add },
            ["GitSignsChange"] = { fg = c.chg },
            ["GitSignsDelete"] = { fg = c.del },
            ["DiffAdd"]    = { bg = "#16210f" },
            ["DiffChange"] = { bg = "#1a1a22" },
            ["DiffDelete"] = { bg = "#2a1416" },
            ["DiffText"]   = { bg = "#2a2a3a" },

            -- ---- plugins: neo-tree / which-key / trouble / fidget ----
            ["NeoTreeNormal"]        = { fg = c.fg, bg = c.bg },
            ["NeoTreeNormalNC"]      = { fg = c.fg, bg = c.bg },
            ["NeoTreeFloatBorder"]   = { fg = c.border, bg = c.panel },
            ["NeoTreeTitleBar"]      = { fg = c.bg, bg = c.accent, bold = true },
            ["NeoTreeRootName"]      = { fg = c.accent, bold = true },
            ["NeoTreeDirectoryName"] = { fg = c.fg },
            ["NeoTreeDirectoryIcon"] = { fg = c.func },
            ["NeoTreeIndentMarker"]  = { fg = c.border },
            ["NeoTreeGitAdded"]      = { fg = c.add },
            ["NeoTreeGitModified"]   = { fg = c.chg },
            ["NeoTreeGitDeleted"]    = { fg = c.del },
            ["NeoTreeGitUntracked"]  = { fg = c.dim },
            ["NeoTreeGitConflict"]   = { fg = c.warn },
            ["WhichKey"]          = { fg = c.accent },
            ["WhichKeyGroup"]     = { fg = c.func },
            ["WhichKeyDesc"]      = { fg = c.fg },
            ["WhichKeySeparator"] = { fg = c.dim },
            ["WhichKeyFloat"]     = { bg = c.panel },
            ["WhichKeyBorder"]    = { fg = c.border, bg = c.panel },
            ["TroubleNormal"]     = { fg = c.fg, bg = c.panel },
            ["TroubleText"]       = { fg = c.fg },
            ["TroubleCount"]      = { fg = c.accent, bold = true },
            ["FidgetTitle"]       = { fg = c.accent, bold = true },
            ["FidgetTask"]        = { fg = c.dim },
            -- flash: jump labels + matches (default label was orange)
            ["FlashLabel"]   = { fg = "#0e0e0e", bg = "#e85c6a", bold = true },
            ["FlashMatch"]   = { fg = "#eeeeee", bg = "#3a3a3a" },
            ["FlashCurrent"] = { fg = "#0e0e0e", bg = "#d8bdf3", bold = true },
        }

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
        for group, spec in pairs(hls) do
            hl[group] = spec
        end
        return hl
    end,
}
