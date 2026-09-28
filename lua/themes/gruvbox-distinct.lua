-- Hand-rolled theme: gruvbox dark hard background + chrome, with Monochrome's warm
-- accents on top (gold types, red methods, rose members) and one orange for
-- keywords + preprocessor. Edit `c` below, then :ThemeReload.
return {
    name = "Gruvbox Distinct",
    desc = "gruvbox hard background, Monochrome's warm accents",
    base = "gruvbox",
    background = "dark",
    setup = function() require("gruvbox").setup({ contrast = "hard" }) end,
    highlights = function()
        local g = require("gruvbox").palette
        -- Warm set: Monochrome's accents for the things that matter (types, methods,
        -- members, functions, text), one orange for all the structural words.
        local c = {
            keyword   = "#fe8019",  -- orange      return, if, const, struct, class, template
            preproc   = "#fe8019",  -- orange      #include, #define, macro names (same as keywords on purpose)
            -- Monochrome's gold (#F9E2AF) is near-white on this warmer background, so a
            -- deeper gold keeps types apart from plain text. Swap back if you prefer.
            builtin   = "#ecd27f",  -- gold        int, void, bool, auto  (same as user types on purpose)
            type      = "#ecd27f",  -- gold        Mesh, HalfEdge, std::vector, T
            string    = "#a9b665",  -- olive       "text", <vector>
            func      = "#8ec07c",  -- aqua-green  free functions (gruvbox's own; warm-leaning green)
            method    = "#e85c6a",  -- red         class methods                    (Monochrome)
            member    = "#dd8a9c",  -- rose        fields / properties              (Monochrome)
            constant  = "#d6a06a",  -- amber       numbers, booleans, nullptr, enum members (Monochrome)
            namespace = "#a6a6a6",  -- grey        std::, yanmesh::                 (Monochrome)
            variable  = "#eeeeee",  -- white       locals, parameters, operators, punctuation (Monochrome)
            comment   = g.gray,     -- gruvbox grey
        }
        -- git / UI accents (fg-only; the status letter never gets a block behind it)
        local ui = {
            add = g.bright_green, change = "#d6a06a", delete = g.bright_red,
            dim = g.light4, white = c.variable,
        }
        local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg

        return {
            -- UI text white like the code text (gruvbox's cream reads orange next to it)
            ["Normal"]   = { fg = ui.white, bg = normal_bg },
            ["NormalNC"] = { fg = ui.white, bg = normal_bg },
            -- git status words: fg only. gruvbox.nvim links diffAdded -> DiffAdd (a line
            -- background), which is what put a green block behind diffview's "A".
            ["diffAdded"]   = { fg = ui.add },
            ["diffRemoved"] = { fg = ui.delete },
            ["diffChanged"] = { fg = ui.change },
            ["Added"]       = { fg = ui.add },
            ["Removed"]     = { fg = ui.delete },
            ["Changed"]     = { fg = ui.change },
            -- gutter: gruvbox paints the sign column a lighter grey; keep it on the editor bg
            ["SignColumn"]   = { bg = normal_bg },
            ["FoldColumn"]   = { fg = g.gray, bg = normal_bg },
            ["CursorLineNr"] = { fg = g.bright_yellow, bg = normal_bg, bold = true },
            ["DiagnosticSignError"] = { fg = g.bright_red },
            ["DiagnosticSignWarn"]  = { fg = g.bright_yellow },
            ["DiagnosticSignHint"]  = { fg = g.bright_aqua },
            ["DiagnosticSignInfo"]  = { fg = g.bright_blue },
            ["DiagnosticSignOk"]    = { fg = g.bright_green },
            ["GitSignsAdd"]    = { fg = ui.add },
            ["GitSignsChange"] = { fg = ui.change },
            ["GitSignsDelete"] = { fg = ui.delete },
            -- diff bodies: subtle tints on the dark bg instead of gruvbox's saturated
            -- slabs (olive / red / dark-on-yellow). Same idea as Monochrome's diff colours.
            ["DiffAdd"]    = { bg = "#283322" },
            ["DiffDelete"] = { bg = "#3b2426" },
            ["DiffChange"] = { bg = "#2c2b24" },
            ["DiffText"]   = { bg = "#4a4323" },
            ["DiffviewDiffAddAsDelete"] = { bg = "#3b2426" },  -- diffview copies DiffDelete at load; pin it
            -- diffview file panel
            ["DiffviewStatusAdded"]       = { fg = ui.add },
            ["DiffviewStatusUntracked"]   = { fg = ui.add },
            ["DiffviewStatusCopied"]      = { fg = ui.add },
            ["DiffviewStatusModified"]    = { fg = ui.change },
            ["DiffviewStatusRenamed"]     = { fg = ui.change },
            ["DiffviewStatusTypeChanged"] = { fg = ui.change },
            ["DiffviewStatusUnmerged"]    = { fg = ui.change },
            ["DiffviewStatusDeleted"]     = { fg = ui.delete },
            ["DiffviewStatusBroken"]      = { fg = ui.delete },
            ["DiffviewStatusUnknown"]     = { fg = ui.delete },
            ["DiffviewStatusIgnored"]     = { fg = ui.dim },
            ["DiffviewFilePanelFileName"] = { fg = ui.white },
            ["DiffviewFilePanelCounter"]  = { fg = ui.dim, bold = true },
            ["DiffviewFilePanelInsertions"] = { fg = ui.add },
            ["DiffviewFilePanelDeletions"]  = { fg = ui.delete },
            -- snacks pickers (files, git status)
            ["SnacksPickerFile"]               = { fg = ui.white },
            ["SnacksPickerGitStatusAdded"]     = { fg = ui.add },
            ["SnacksPickerGitStatusStaged"]    = { fg = ui.add },
            ["SnacksPickerGitStatusModified"]  = { fg = ui.change },
            ["SnacksPickerGitStatusRenamed"]   = { fg = ui.change },
            ["SnacksPickerGitStatusDeleted"]   = { fg = ui.delete },
            ["SnacksPickerGitStatusUntracked"] = { fg = ui.dim },
            ["SnacksPickerGitStatusIgnored"]   = { fg = g.dark4 },
            -- neo-tree
            ["Directory"]            = { fg = ui.white, bold = true },  -- gruvbox: green bold
            ["NeoTreeFileName"]      = { fg = ui.white },
            ["NeoTreeDirectoryName"] = { fg = ui.white, bold = true },
            ["NeoTreeDirectoryIcon"] = { fg = ui.dim },
            ["NeoTreeRootName"]      = { fg = ui.white, bold = true },
            ["NeoTreeDotfile"]       = { fg = ui.dim },
            ["NeoTreeHiddenByName"]  = { fg = ui.dim },
            ["NeoTreeIndentMarker"]  = { fg = g.dark3 },
            ["SnacksPickerDir"]      = { fg = ui.dim },
            ["SnacksPickerDirectory"] = { fg = ui.white, bold = true },
            ["NeoTreeGitAdded"]      = { fg = ui.add },
            ["NeoTreeGitStaged"]     = { fg = ui.add },
            ["NeoTreeGitModified"]   = { fg = ui.change },
            ["NeoTreeGitDeleted"]    = { fg = ui.delete },
            ["NeoTreeGitConflict"]   = { fg = ui.delete },
            ["NeoTreeGitUntracked"]  = { fg = ui.dim },

            -- keywords (struct/class/enum/typename are keywords, not types)
            ["Keyword"]              = { fg = c.keyword },
            ["@keyword"]             = { fg = c.keyword },
            ["@keyword.type"]        = { fg = c.keyword },
            ["@keyword.modifier"]    = { fg = c.keyword },
            -- clangd tags const/override/virtual/static as "modifier" semantic tokens and
            -- gruvbox.nvim sends those to the Type colour; keep them with the keywords.
            ["@type.qualifier"]      = { fg = c.keyword },
            ["@lsp.type.modifier"]   = { fg = c.keyword },
            ["Structure"]            = { fg = c.keyword },
            ["StorageClass"]         = { fg = c.keyword },
            -- builtin types vs user types
            ["@type.builtin"]        = { fg = c.builtin },
            ["Type"]                 = { fg = c.type },
            ["@type"]                = { fg = c.type },
            ["@type.definition"]     = { fg = c.type },
            ["@lsp.type.class"]      = { fg = c.type },
            ["@lsp.type.struct"]     = { fg = c.type },
            ["@lsp.type.enum"]       = { fg = c.type },
            ["@lsp.type.type"]       = { fg = c.type },
            ["@lsp.type.typeParameter"] = { fg = c.type },
            ["@lsp.type.interface"]  = { fg = c.type },
            -- free functions vs methods
            ["Function"]                = { fg = c.func },
            ["@function"]               = { fg = c.func },
            ["@function.call"]          = { fg = c.func },
            ["@lsp.type.function"]      = { fg = c.func },
            ["@function.method"]        = { fg = c.method },
            ["@function.method.call"]   = { fg = c.method },
            ["@lsp.type.method"]        = { fg = c.method },
            ["@constructor"]            = { fg = c.type },
            -- members vs plain variables
            ["Identifier"]              = { fg = c.variable },
            ["@variable"]               = { fg = c.variable },
            ["@variable.parameter"]     = { fg = c.variable },
            ["@lsp.type.variable"]      = { fg = c.variable },
            ["@lsp.type.parameter"]     = { fg = c.variable },
            ["@variable.member"]        = { fg = c.member },
            ["@property"]               = { fg = c.member },
            ["@field"]                  = { fg = c.member },
            ["@lsp.type.property"]      = { fg = c.member },
            -- constants, numbers, booleans, nullptr/this, enum members
            ["Constant"]                = { fg = c.constant },
            ["Number"]                  = { fg = c.constant },
            ["Float"]                   = { fg = c.constant },
            ["Boolean"]                 = { fg = c.constant },
            ["@constant"]               = { fg = c.constant },
            ["@constant.builtin"]       = { fg = c.constant },
            ["@number"]                 = { fg = c.constant },
            ["@number.float"]           = { fg = c.constant },
            ["@boolean"]                = { fg = c.constant },
            ["@variable.builtin"]       = { fg = c.constant },
            ["@lsp.type.enumMember"]    = { fg = c.constant },
            -- preprocessor and macros
            ["PreProc"]                 = { fg = c.preproc },
            ["Include"]                 = { fg = c.preproc },
            ["Define"]                  = { fg = c.preproc },
            ["Macro"]                   = { fg = c.preproc },
            ["@keyword.import"]         = { fg = c.preproc },
            ["@keyword.directive"]      = { fg = c.preproc },
            ["@constant.macro"]         = { fg = c.preproc },
            ["@function.macro"]         = { fg = c.preproc },
            ["@lsp.type.macro"]         = { fg = c.preproc },
            -- namespaces
            ["@module"]                 = { fg = c.namespace },
            ["@namespace"]              = { fg = c.namespace },
            ["@lsp.type.namespace"]     = { fg = c.namespace },
            -- strings
            ["String"]                  = { fg = c.string },
            ["@string"]                 = { fg = c.string },
            -- operators / punctuation: plain, never orange
            ["Operator"]                = { fg = c.variable },
            ["Delimiter"]               = { fg = c.variable },
            ["@operator"]               = { fg = c.variable },
            ["@punctuation.bracket"]    = { fg = c.variable },
            ["@punctuation.delimiter"]  = { fg = c.variable },
            -- comments
            ["Comment"]                 = { fg = c.comment, italic = true },
            ["@comment"]                = { fg = c.comment, italic = true },
        }
    end,
}
