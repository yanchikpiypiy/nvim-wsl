-- Gruvbox dark hard with the hue assignment from the Rust screenshot:
-- purple keywords, aqua functions, red macros, yellow types, ORANGE comments.
-- That orange comment is the one thing stock gruvbox does not do (it greys
-- them out), and it is the whole reason this theme exists separately.
--
-- Differs from gruvbox-distinct, which keeps Monochrome's warm accents
-- (orange keywords, red methods, rose members) on the same background.
-- Edit `c` below, then :ThemeReload.
return {
    name = "Gruvbox Classic",
    desc = "purple keywords, orange comments",
    base = "gruvbox",
    background = "dark",
    setup = function() require("gruvbox").setup({ contrast = "hard" }) end,
    highlights = function()
        -- Every value here is gruvbox's own canonical hex. The screenshot was
        -- video-compressed, so its sampled colours land a few percent off each
        -- of these; snapping to the real palette is closer than the samples.
        local c = {
            -- Keywords split three ways. C# repeats `public static readonly` on
            -- nearly every line, and one purple for all of it measured at 25% of
            -- the coloured glyphs in a buffer -- so modifiers recede to grey and
            -- declarations pop, leaving purple for control flow you want to spot.
            modifier  = "#928374",  -- grey     public static private readonly async override
            keyword   = "#d3869b",  -- purple   control flow, return, new, is, null, switch, await
            declare   = "#fb4934",  -- red      class struct interface enum record, #if/#define
            import    = "#928374",  -- grey     `using` -- recedes with the namespace path after it
            -- Types split by origin so a builtin reads differently from yours.
            type      = "#fabd2f",  -- yellow   CurrencyCode, HashSet, RegionInfo, T
            builtin   = "#d79921",  -- dk gold  string, int, bool, void, var
            func      = "#8ec07c",  -- aqua     methods and free functions
            member    = "#dd8a9c",  -- rose     properties, fields, events
            constant  = "#83a598",  -- blue     numbers, booleans, enum members
            string    = "#b8bb26",  -- green    "text", <vector>
            variable  = "#ebdbb2",  -- fg1      locals, params, operators, punctuation
            namespace = "#a89984",  -- grey     System.Globalization, std::
            comment   = "#fe8019",  -- orange   the signature of this theme
        }

        local hl = require("config.gruvbox_chrome").build({
            white  = c.variable,
            change = c.type,
        })

        local syntax = {
            -- Roslyn collapses every keyword into one `keyword` token and wins
            -- at priority 125, so the granular treesitter captures below never
            -- showed. Transparent here, coloured by treesitter instead.
            ["@lsp.type.keyword"]        = {},
            ["@lsp.type.controlKeyword"] = {},
            ["@lsp.type.modifier"]       = { fg = c.modifier },
            ["Keyword"]               = { fg = c.keyword },
            ["@keyword"]              = { fg = c.keyword },
            ["@keyword.function"]     = { fg = c.keyword },
            ["@keyword.return"]       = { fg = c.keyword },
            ["@keyword.conditional"]  = { fg = c.keyword },
            ["@keyword.repeat"]       = { fg = c.keyword },
            ["@keyword.exception"]    = { fg = c.keyword },
            ["@keyword.operator"]     = { fg = c.keyword },
            ["@keyword.coroutine"]    = { fg = c.keyword },
            ["Statement"]             = { fg = c.keyword },
            ["Conditional"]           = { fg = c.keyword },
            ["Repeat"]                = { fg = c.keyword },
            -- modifiers: the noisy half of C#
            ["@keyword.modifier"]     = { fg = c.modifier },
            ["@type.qualifier"]       = { fg = c.modifier },
            ["StorageClass"]          = { fg = c.modifier },
            -- declaration words: class / struct / interface / enum / record
            ["@keyword.type"]         = { fg = c.declare },
            ["Structure"]             = { fg = c.declare },
            -- `using` recedes with the namespace path it introduces
            ["@keyword.import"]       = { fg = c.import },
            -- types: `str` sampled yellow in the shot, so builtins and user
            -- types share one colour here
            ["Type"]                    = { fg = c.type },
            ["@type"]                   = { fg = c.type },
            ["@type.builtin"]           = { fg = c.builtin },
            ["@type.definition"]        = { fg = c.type },
            ["@constructor"]            = { fg = c.type },
            ["@lsp.type.class"]         = { fg = c.type },
            ["@lsp.type.struct"]        = { fg = c.type },
            ["@lsp.type.enum"]          = { fg = c.type },
            ["@lsp.type.type"]          = { fg = c.type },
            ["@lsp.type.interface"]     = { fg = c.type },
            ["@lsp.type.typeParameter"] = { fg = c.type },
            -- functions and methods, one colour
            ["Function"]              = { fg = c.func },
            ["@function"]             = { fg = c.func },
            ["@function.call"]        = { fg = c.func },
            ["@function.method"]      = { fg = c.func },
            ["@function.method.call"] = { fg = c.func },
            ["@lsp.type.function"]    = { fg = c.func },
            ["@lsp.type.method"]      = { fg = c.func },
            -- macros / preprocessor
            ["PreProc"]            = { fg = c.declare },
            ["Include"]            = { fg = c.declare },
            ["Define"]             = { fg = c.declare },
            ["Macro"]              = { fg = c.declare },
            ["@keyword.directive"] = { fg = c.declare },
            ["@function.macro"]    = { fg = c.declare },
            ["@constant.macro"]    = { fg = c.declare },
            ["@lsp.type.macro"]    = { fg = c.declare },
            -- variables vs members
            ["Identifier"]          = { fg = c.variable },
            ["@variable"]           = { fg = c.variable },
            ["@variable.parameter"] = { fg = c.variable },
            -- Roslyn tags anything it has not resolved YET as `variable`, and
            -- semantic tokens outrank treesitter (125 vs 100). Colouring these
            -- paints most of a C# buffer flat and hides treesitter's correct
            -- method/type colours, so leave them transparent and let treesitter
            -- show through. Same rule as themes/monochrome.lua. `parameter` is
            -- a reliable classification, so that one keeps its colour.
            ["@lsp.type.variable"]  = {},
            ["@lsp.type.local"]     = {},
            ["@lsp.type.parameter"] = { fg = c.variable },
            ["@variable.member"]    = { fg = c.member },
            ["@property"]           = { fg = c.member },
            ["@field"]              = { fg = c.member },
            ["@lsp.type.property"]  = { fg = c.member },
            -- constants
            ["Constant"]             = { fg = c.constant },
            ["Number"]               = { fg = c.constant },
            ["Float"]                = { fg = c.constant },
            ["Boolean"]              = { fg = c.constant },
            ["@constant"]            = { fg = c.constant },
            ["@constant.builtin"]    = { fg = c.constant },
            ["@number"]              = { fg = c.constant },
            ["@number.float"]        = { fg = c.constant },
            ["@boolean"]             = { fg = c.constant },
            ["@variable.builtin"]    = { fg = c.constant },
            ["@lsp.type.enumMember"] = { fg = c.constant },
            -- namespaces
            ["@module"]             = { fg = c.namespace },
            ["@namespace"]          = { fg = c.namespace },
            ["@lsp.type.namespace"] = { fg = c.namespace },
            -- strings
            ["String"]  = { fg = c.string },
            ["@string"] = { fg = c.string },
            -- operators / punctuation stay plain, never a keyword colour
            ["Operator"]               = { fg = c.variable },
            ["Delimiter"]              = { fg = c.variable },
            ["@operator"]              = { fg = c.variable },
            ["@punctuation.bracket"]   = { fg = c.variable },
            ["@punctuation.delimiter"] = { fg = c.variable },
            -- comments: orange, and NOT italic -- the screenshot draws them upright
            ["Comment"]  = { fg = c.comment },
            ["@comment"] = { fg = c.comment },
        }

        return vim.tbl_extend("force", hl, syntax)
    end,
}
