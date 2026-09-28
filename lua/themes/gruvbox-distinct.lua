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
        -- Editor furniture is shared with the other gruvbox themes; only the
        -- syntax groups below are what makes this theme distinct.
        local chrome = require("config.gruvbox_chrome").build({
            white  = c.variable,
            change = c.constant,
        })

        local syntax = {
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
            -- See themes/monochrome.lua: Roslyn's unresolved-yet `variable`
            -- tokens beat treesitter at priority 125, flattening C# buffers.
            ["@lsp.type.variable"]      = {},
            ["@lsp.type.local"]         = {},
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

        return vim.tbl_extend("force", chrome, syntax)
    end,
}
