-- Shared syntax palette -- the SINGLE SOURCE OF TRUTH for highlight colors.
--
-- Both highlighting engines read from here:
--   * treesitter scheme  -> lua/plugins/monochrome.lua
--   * C# Roslyn LSP scheme -> lua/config/options.lua
-- so the editor uses ONE consistent color logic no matter which engine is
-- driving a given buffer. Change a color once here and it updates everywhere.
--
-- Names are by SYMBOL KIND (not by hue), so the mapping stays meaningful even
-- if you re-tint later.
return {
    type      = "#62c8ff", -- types: class, interface, struct, enum, record, delegate (neon light blue)
    method    = "#e85c6a", -- methods, extension methods, operator overloads (red)
    func      = "#d8bdf3", -- static methods & free functions (lavender)
    member    = "#dd8a9c", -- properties, fields, events (rose pink)
    constant  = "#d8c987", -- constants, enum members, numbers/booleans (soft muted yellow-gold, not orange)
    variable  = "#eeeeee", -- variables, parameters, locals (white)
    keyword   = "#9a6dd7", -- keywords, control flow, preprocessor (purple)
    string    = "#d3c9e0", -- strings (muted lilac-grey; brighter, faint purple lean to match scheme)
    comment   = "#5e5e5e", -- comments (dim grey)
    namespace = "#a6a6a6", -- namespaces (recede, grey)
}
