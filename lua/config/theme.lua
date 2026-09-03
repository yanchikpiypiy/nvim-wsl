-- Theme switcher.
--   Plugin themes : declared in M.plugins below (a colorscheme name + optional setup).
--   Custom themes : one file per theme in lua/themes/, auto-discovered. Each returns
--                   { name, desc, base?, setup?, background?, highlights = fn -> {group = spec} }.
--                   `base` is a plugin colorscheme to start from (omit it to paint on
--                   Neovim's defaults); `setup` runs before it loads (plugin options).
--   <leader>ut  picker with live preview      :Theme <id>  switch directly
local M = {}

M.plugins = {
    {
        id = "gruvbox-hard",
        name = "Gruvbox Dark Hard",
        desc = "default",
        setup = function() require("gruvbox").setup({ contrast = "hard" }) end,
        colorscheme = "gruvbox",
    },
    {
        id = "gruvbox-medium",
        name = "Gruvbox Dark Medium",
        desc = "softer background",
        setup = function() require("gruvbox").setup({ contrast = "" }) end,
        colorscheme = "gruvbox",
    },
    {
        id = "everforest",
        name = "Everforest Medium",
        desc = "green, low contrast",
        setup = function() vim.g.everforest_background = "medium" end,
        colorscheme = "everforest",
    },
    {
        id = "everforest-soft",
        name = "Everforest Soft",
        desc = "lighter background",
        setup = function() vim.g.everforest_background = "soft" end,
        colorscheme = "everforest",
    },
}

M.default = "gruvbox-hard"
M.current = nil

local state_file = vim.fs.joinpath(vim.fn.stdpath("state"), "theme")

local function custom_themes()
    local list = {}
    for _, file in ipairs(vim.api.nvim_get_runtime_file("lua/themes/*.lua", true)) do
        local id = vim.fn.fnamemodify(file, ":t:r")
        local ok, spec = pcall(require, "themes." .. id)
        if ok and type(spec) == "table" then
            list[#list + 1] = {
                id = id,
                name = spec.name or id,
                desc = spec.desc or "",
                kind = "custom",
                spec = spec,
            }
        else
            vim.notify("themes/" .. id .. ".lua failed to load: " .. tostring(spec), vim.log.levels.WARN)
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- Plugin presets first, then the hand-rolled ones.
function M.presets()
    local list = {}
    for _, p in ipairs(M.plugins) do
        list[#list + 1] = { id = p.id, name = p.name, desc = p.desc, kind = "plugin", spec = p }
    end
    vim.list_extend(list, custom_themes())
    return list
end

local function find(id)
    for _, p in ipairs(M.presets()) do
        if p.id == id then return p end
    end
end

local function apply_plugin(p)
    vim.o.background = "dark"
    if p.setup then p.setup() end
    vim.cmd.colorscheme(p.colorscheme)
end

local function apply_custom(id, spec)
    vim.o.background = spec.background or "dark"
    if spec.setup then spec.setup() end
    if spec.base then
        vim.cmd.colorscheme(spec.base)
    else
        vim.cmd.highlight("clear")
        vim.cmd.syntax("reset")
    end
    local hl = type(spec.highlights) == "function" and spec.highlights() or spec.highlights or {}
    for group, def in pairs(hl) do
        vim.api.nvim_set_hl(0, group, def)
    end
    vim.g.colors_name = id
end

function M.apply(id)
    local preset = find(id)
    if not preset then
        vim.notify("Unknown theme: " .. tostring(id), vim.log.levels.ERROR)
        return false
    end
    local ok, err = pcall(function()
        if preset.kind == "plugin" then
            apply_plugin(preset.spec)
        else
            apply_custom(id, preset.spec)
        end
    end)
    if not ok then
        vim.notify("Theme '" .. id .. "' failed: " .. tostring(err), vim.log.levels.ERROR)
        return false
    end
    M.current = id
    return true
end

function M.save(id)
    vim.fn.writefile({ id }, state_file)
end

function M.saved()
    if vim.fn.filereadable(state_file) == 0 then return nil end
    local lines = vim.fn.readfile(state_file)
    return lines[1] ~= "" and lines[1] or nil
end

-- Called once at startup, after all plugins are on the runtimepath.
function M.restore()
    local id = M.saved() or M.default
    if not M.apply(id) and id ~= M.default then
        M.apply(M.default)
    end
end

function M.set(id)
    if M.apply(id) then
        M.save(id)
        vim.notify("Theme: " .. find(id).name, vim.log.levels.INFO)
    end
end

-- Re-read a custom theme file after editing it (or just :Theme <id> again).
function M.reload(id)
    package.loaded["themes." .. id] = nil
    M.apply(id)
end

local sample_cpp = {
    "#pragma once",
    "#include <vector>",
    "#include <string_view>",
    "",
    "namespace yanmesh {",
    "",
    "static constexpr uint32_t kInvalid = 0xFFFFFFFF;",
    "",
    "// Half-edge: every edge knows its twin, its successor and its face.",
    "struct HalfEdge {",
    "    uint32_t twin = kInvalid;",
    "    uint32_t next = kInvalid;",
    "    uint32_t face = kInvalid;",
    "};",
    "",
    "class Mesh {",
    "public:",
    "    explicit Mesh(std::string_view name) : name_(name) {}",
    "",
    "    [[nodiscard]] bool isBoundary(uint32_t he) const {",
    "        return halfEdges_[he].twin == kInvalid;",
    "    }",
    "",
    "    void splitEdge(uint32_t he, float t = 0.5f);",
    "",
    "private:",
    "    std::string name_ = \"unnamed\";",
    "    std::vector<HalfEdge> halfEdges_;",
    "};",
    "",
    "template <typename T>",
    "T lerp(const T& a, const T& b, float t) {",
    "    return a + (b - a) * t;  // TODO: clamp t",
    "}",
    "",
    "} // namespace yanmesh",
}

local kind_hl = { plugin = "DiagnosticInfo", custom = "DiagnosticOk" }

function M.pick()
    local before = M.current or M.default
    local confirmed = false

    local presets = M.presets()
    local name_width = 0
    for _, p in ipairs(presets) do name_width = math.max(name_width, #p.name) end

    local items = {}
    for i, p in ipairs(presets) do
        items[i] = { idx = i, text = p.kind .. " " .. p.name .. " " .. p.desc, preset = p }
    end

    Snacks.picker.pick({
        source = "themes",
        title = " Theme ",
        items = items,
        layout = { preset = "vertical" },
        format = function(item)
            local p = item.preset
            local align = Snacks.picker.util.align
            return {
                { p.id == before and "● " or "  ", "SnacksPickerSpecial" },
                { align(p.kind, 7), kind_hl[p.kind] },
                { align(p.name, name_width + 2), "SnacksPickerLabel" },
                { p.desc, "SnacksPickerComment" },
            }
        end,
        preview = function(ctx)
            local p = ctx.item.preset
            ctx.preview:reset()
            ctx.preview:set_title(p.name .. "  [" .. p.kind .. "]")
            ctx.preview:set_lines(sample_cpp)
            ctx.preview:highlight({ lang = "cpp" })
        end,
        -- hovering an entry recolours the whole editor right away
        on_change = function(_, item)
            if item and item.preset.id ~= M.current then
                vim.schedule(function() M.apply(item.preset.id) end)
            end
        end,
        confirm = function(picker, item)
            confirmed = true
            picker:close()
            if item then vim.schedule(function() M.set(item.preset.id) end) end
        end,
        -- Esc / q: put the previous theme back
        on_close = function()
            if not confirmed and M.current ~= before then
                vim.schedule(function() M.apply(before) end)
            end
        end,
    })
end

vim.api.nvim_create_user_command("Theme", function(cmd)
    if cmd.args == "" then M.pick() else M.set(cmd.args) end
end, {
    nargs = "?",
    complete = function()
        return vim.tbl_map(function(p) return p.id end, M.presets())
    end,
    desc = "Switch colour theme (no arg: open the picker)",
})

vim.api.nvim_create_user_command("ThemeReload", function()
    if M.current then M.reload(M.current) end
end, { desc = "Re-read the current custom theme file and re-apply it" })

return M
