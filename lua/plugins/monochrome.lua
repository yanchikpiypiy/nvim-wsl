return {
    "kdheepak/monochrome.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        vim.o.background = "dark"

        -- Custom layer: greyscale monochrome base + accents + matching UI chrome.
        -- One declarative table (group -> spec), applied whenever monochrome is selected.
        vim.api.nvim_create_autocmd("ColorScheme", {
            pattern = "monochrome",
            callback = function()
                local c = {
                    -- syntax
                    members = "#dd8a9c",  -- members / properties (soft red-pink)
                    var     = "#eeeeee",  -- plain variables (white)
                    func    = "#d8bdf3",  -- free functions (Spinel lavender, leaned pink so it's bright, not blue)
                    method  = "#e85c6a",  -- class methods (red-pink)
                    keyword = "#9a6dd7",  -- keywords / qualifiers / macros (dark purple)
                    type    = "#a6a6a6",  -- types (light grey)
                    number  = "#d6a06a",  -- numbers / booleans (amber)
                    string  = "#d4d4d4",  -- strings (light grey)
                    comment = "#5e5e5e",  -- comments (dim grey)
                    hint    = "#7e8a96",  -- LSP inlay hints (cool grey, own tone)
                    -- ui / chrome
                    bg      = "#0e0e0e",
                    panel   = "#161616",  -- float / telescope background
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
                    -- ---- Telescope ----
                    ["TelescopeNormal"]         = { fg = c.fg, bg = c.panel },
                    ["TelescopeBorder"]         = { fg = c.border, bg = c.panel },
                    ["TelescopePromptNormal"]   = { fg = c.fg, bg = c.raised },
                    ["TelescopePromptBorder"]   = { fg = c.raised, bg = c.raised },
                    ["TelescopePromptPrefix"]   = { fg = c.accent, bg = c.raised },
                    ["TelescopePromptTitle"]    = { fg = c.bg, bg = c.accent, bold = true },
                    ["TelescopeResultsTitle"]   = { fg = c.panel, bg = c.panel },
                    ["TelescopePreviewTitle"]   = { fg = c.bg, bg = c.dim, bold = true },
                    ["TelescopeSelection"]      = { bg = c.sel, bold = true },
                    ["TelescopeSelectionCaret"] = { fg = c.accent, bg = c.sel },
                    ["TelescopeMatching"]       = { fg = c.accent, bold = true },
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
                for group, spec in pairs(hl) do
                    vim.api.nvim_set_hl(0, group, spec)
                end
            end,
        })

        vim.cmd.colorscheme("monochrome")  -- :colorscheme everforest to switch back
    end,
}
