-- Shared syntax palette -- the SINGLE SOURCE OF TRUTH for the Monochrome theme.
--
-- Both highlighting engines read from here (see lua/themes/monochrome.lua):
--   * treesitter groups (C++, everything else)
--   * Roslyn semantic tokens (C#)
-- so a buffer looks the same no matter which engine is driving it.
-- Names are by SYMBOL KIND (not by hue), so the mapping stays meaningful
-- if you re-tint later.
return {
    type      = "#F9E2AF", -- types: class, struct, enum, record, delegate, generics (gold)
    interface = "#94e2d5", -- interfaces: a contract reads differently from a concrete type (teal)
    method    = "#e85c6a", -- methods, extension methods, operator overloads (red)
    func      = "#d8bdf3", -- static methods & free functions (lavender)
    import    = "#9a6dd7", -- #include / preprocessor directives (purple, with the keywords)
    member    = "#dd8a9c", -- properties, fields, events (rose pink)
    constant  = "#d6a06a", -- constants, enum members, numbers/booleans (amber)
    variable  = "#eeeeee", -- variables, parameters, locals (white)
    keyword   = "#9a6dd7", -- keywords, control flow, preprocessor (purple)
    string    = "#d0ccc0", -- strings (light grey with a hint of yellow)
    comment   = "#5e5e5e", -- comments (dim grey)
    namespace = "#a6a6a6", -- namespaces: std::, YanMesh:: (recede, grey)
}
