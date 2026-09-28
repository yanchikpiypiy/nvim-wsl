-- Palette tuner for the Monochrome theme: pick a symbol kind, hover swatches,
-- watch the editor recolour live, <CR> writes the hex into lua/config/palette.lua.
--
-- Two levels, and you can walk back up:
--   <leader>up  open           kind list -> swatch list
--   <CR>        save, then drop back to the kind list (tune the next one)
--   <Esc>       back one level -- from the kind list, that closes
--   q           quit outright, reverting the colour being previewed
-- Typing a hex in the swatch filter picks it directly: #rrggbb, #rgb or bare rrggbb.
local M = {}

local palette_file = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "config", "palette.lua")

-- What each palette key paints. Order = order in the picker.
M.jobs = {
    { key = "type",      desc = "class / struct / enum / generics" },
    { key = "interface", desc = "interfaces" },
    { key = "method",    desc = "class methods" },
    { key = "func",      desc = "free functions, static methods" },
    { key = "member",    desc = "fields / properties" },
    { key = "variable",  desc = "locals / parameters" },
    { key = "constant",  desc = "numbers, booleans, enum members" },
    { key = "keyword",   desc = "keywords, control flow, macros" },
    { key = "import",    desc = "#include and other directives" },
    { key = "namespace", desc = "std::, YanMesh::" },
    { key = "string",    desc = "strings" },
    { key = "comment",   desc = "comments" },
}

-- Candidate colours, grouped by where they come from. Add your own freely.
M.swatches = {
    { "gruvbox red",       "#fb4934" }, { "gruvbox orange",    "#fe8019" }, { "gruvbox yellow",    "#fabd2f" },
    { "gruvbox green",     "#b8bb26" }, { "gruvbox aqua",      "#8ec07c" }, { "gruvbox blue",      "#83a598" },
    { "gruvbox purple",    "#d3869b" }, { "gruvbox fg",        "#ebdbb2" }, { "gruvbox grey",      "#928374" },
    { "mocha rosewater",   "#f5e0dc" }, { "mocha pink",        "#f5c2e7" }, { "mocha mauve",       "#cba6f7" },
    { "mocha red",         "#f38ba8" }, { "mocha maroon",      "#eba0ac" }, { "mocha peach",       "#fab387" },
    { "mocha yellow",      "#f9e2af" }, { "mocha green",       "#a6e3a1" }, { "mocha teal",        "#94e2d5" },
    { "mocha sky",         "#89dceb" }, { "mocha sapphire",    "#74c7ec" }, { "mocha blue",        "#89b4fa" },
    { "mocha lavender",    "#b4befe" }, { "mocha text",        "#cdd6f4" }, { "mocha subtext",     "#a6adc8" },
    { "mocha overlay",     "#6c7086" },
    { "everforest red",    "#e67e80" }, { "everforest orange", "#e69875" }, { "everforest yellow", "#dbbc7f" },
    { "everforest green",  "#a7c080" }, { "everforest aqua",   "#83c092" }, { "everforest blue",   "#7fbbb3" },
    { "everforest purple", "#d699b6" }, { "everforest fg",     "#d3c6aa" }, { "everforest grey",   "#859289" },
    { "mono lavender",     "#d8bdf3" }, { "mono red-pink",     "#e85c6a" }, { "mono rose",         "#dd8a9c" },
    { "mono amber",        "#d6a06a" }, { "mono gold-muted",   "#d8c987" }, { "mono white",        "#eeeeee" },
    { "mono grey",         "#a6a6a6" }, { "mono dim",          "#5e5e5e" }, { "mono purple",       "#9a6dd7" },
    { "mono sage",         "#7fc9b0" }, { "mono neon blue",    "#62c8ff" }, { "mono lilac-grey",   "#d3c9e0" },
}

local function palette() return require("config.palette") end

local function swatch_hl(hex)
    local group = "PaletteSwatch" .. hex:sub(2)
    vim.api.nvim_set_hl(0, group, { fg = hex })
    return group
end

local function is_hex(s) return type(s) == "string" and s:match("^#%x%x%x%x%x%x$") ~= nil end

-- Accepts "#rrggbb", "#rgb" and a bare "rrggbb" so the filter box doubles as a
-- hex entry. Returns nil when the text is just a search term.
local function norm_hex(s)
    s = (s or ""):gsub("%s", ""):lower():gsub("^#", "")
    if s:match("^%x%x%x$") then s = s:gsub("(%x)", "%1%1") end
    return s:match("^%x%x%x%x%x%x$") and ("#" .. s) or nil
end

-- Every colorscheme starts with `:hi clear`, which wipes these swatch groups and
-- leaves the picker drawing every swatch in the default foreground -- i.e. all
-- white. A live preview reloads a colorscheme on each keypress, so re-register
-- them whenever one lands.
local function define_swatches()
    for _, sw in ipairs(M.swatches) do swatch_hl(sw[2]) end
    for _, job in ipairs(M.jobs) do
        local hex = palette()[job.key]
        if is_hex(hex) then swatch_hl(hex) end
    end
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = define_swatches })

-- Mutate the loaded palette and repaint. Monochrome is the only palette-driven
-- theme, so the tuner always previews on it.
local function preview(key, hex)
    palette()[key] = hex
    require("config.theme").apply("monochrome")
    define_swatches()  -- a theme with no `base` repaints without firing ColorScheme
end

local function persist(key, hex)
    local lines = vim.fn.readfile(palette_file)
    for i, line in ipairs(lines) do
        local head = line:match('^(%s*' .. key .. '%s*=%s*)"#%x+"')
        if head then
            lines[i] = head .. '"' .. hex .. '"' .. (line:match('"#%x+"(.*)$') or "")
            vim.fn.writefile(lines, palette_file)
            return true
        end
    end
    return false
end

local sample_cpp = {
    "#include <vector>",
    "#include \"Mesh.h\"",
    "",
    "namespace yanmesh {",
    "",
    "constexpr uint32_t kInvalid = 0xFFFFFFFF;  // sentinel",
    "",
    "class Mesh : public IShape {",
    "public:",
    "    [[nodiscard]] bool isBoundary(uint32_t he) const {",
    "        return halfEdges_[he].twin == kInvalid;",
    "    }",
    "    static Mesh fromFile(std::string_view path);",
    "private:",
    "    std::vector<HalfEdge> halfEdges_;",
    "    std::string name_ = \"unnamed\";",
    "};",
    "",
    "template <typename T>",
    "T lerp(const T& a, const T& b, float t) { return a + (b - a) * t; }",
    "",
    "} // namespace yanmesh",
}

-- `q` quits from anywhere, but "gruvbox aqua" / "everforest aqua" are swatch
-- names and the filter box starts in insert mode -- so q only quits once the
-- box is empty, and stays an ordinary letter while you are typing.
local function quit_action(mark)
    return function(picker)
        if picker:filter().pattern ~= "" then
            vim.api.nvim_feedkeys("q", "n", false)
            return
        end
        if mark then mark() end
        picker:close()
    end
end

-- Remembered so walking back up lands on the kind you were just editing.
local last_idx = 1

local function pick_colour(job, job_idx)
    local before = palette()[job.key]
    -- "quit" reverts and stops, "back" reverts and reopens, "saved" keeps and reopens.
    local outcome = "quit"

    local items = {}
    for i, sw in ipairs(M.swatches) do
        items[i] = { idx = i, text = sw[1] .. " " .. sw[2], name = sw[1], hex = sw[2] }
    end

    local function finish(hex)
        preview(job.key, hex)
        if persist(job.key, hex) then
            vim.notify(("palette.%s = %s  (saved)"):format(job.key, hex), vim.log.levels.INFO)
        else
            vim.notify(("palette.%s = %s applied, but the key was not found in palette.lua"):format(job.key, hex), vim.log.levels.WARN)
        end
    end

    Snacks.picker.pick({
        source = "palette_colour",
        title = (" %s · %s · was %s   <CR> save   <Esc> back   q quit "):format(job.key, job.desc, before),
        items = items,
        layout = { preset = "vertical" },
        win = {
            input = { keys = {
                ["<Esc>"] = { "tuner_back", mode = { "i", "n" } },
                ["q"]     = { "tuner_quit", mode = { "i", "n" } },
            } },
            list = { keys = {
                ["<Esc>"] = "tuner_back",
                ["q"]     = "tuner_quit",
            } },
        },
        actions = {
            tuner_back = function(picker) outcome = "back"; picker:close() end,
            tuner_quit = quit_action(function() outcome = "quit" end),
        },
        format = function(item)
            return {
                { item.hex == before and "● " or "  ", "SnacksPickerSpecial" },
                { "██ ", swatch_hl(item.hex) },
                { Snacks.picker.util.align(item.name, 20), "SnacksPickerLabel" },
                { item.hex, "SnacksPickerComment" },
            }
        end,
        preview = function(ctx)
            ctx.preview:reset()
            ctx.preview:set_title(job.key .. " = " .. ctx.item.hex)
            ctx.preview:set_lines(sample_cpp)
            ctx.preview:highlight({ lang = "cpp" })
        end,
        on_change = function(_, item)
            if item and palette()[job.key] ~= item.hex then
                vim.schedule(function() preview(job.key, item.hex) end)
            end
        end,
        confirm = function(picker, item)
            local hex = (item and item.hex) or norm_hex(picker:filter().pattern)
            if not hex then return end
            outcome = "saved"
            picker:close()
            vim.schedule(function()
                finish(hex)
                M.pick({ idx = job_idx })
            end)
        end,
        on_close = function()
            if outcome ~= "saved" and palette()[job.key] ~= before then
                vim.schedule(function() preview(job.key, before) end)
            end
            if outcome == "back" then
                vim.schedule(function() M.pick({ idx = job_idx }) end)
            end
        end,
    })
end

---@param opts? { idx?: integer } idx: kind to put the cursor on when reopening
function M.pick(opts)
    opts = opts or {}
    local T = require("config.theme")
    if T.current ~= "monochrome" then
        T.apply("monochrome")
        vim.notify("Palette tuner previews on Monochrome (switched for now)", vim.log.levels.INFO)
    end
    last_idx = opts.idx or last_idx
    local items = {}
    for i, job in ipairs(M.jobs) do
        items[i] = { idx = i, text = job.key .. " " .. job.desc, job = job }
    end
    Snacks.picker.pick({
        source = "palette_job",
        title = " Palette · what to recolour   <CR> pick colour   <Esc>/q close ",
        items = items,
        layout = { preset = "vertical" },
        win = {
            input = { keys = { ["q"] = { "tuner_quit", mode = { "i", "n" } } } },
            list  = { keys = { ["q"] = "tuner_quit" } },
        },
        actions = { tuner_quit = quit_action() },
        -- Deferred: the list is not rendered yet when on_show fires. pcall'd so a
        -- snacks internals change costs us the cursor position, not the picker.
        on_show = function(picker)
            if last_idx > 1 then
                vim.schedule(function() pcall(function() picker.list:view(last_idx) end) end)
            end
        end,
        format = function(item)
            local hex = palette()[item.job.key] or "#000000"
            return {
                { "██ ", swatch_hl(hex) },
                { Snacks.picker.util.align(item.job.key, 11), "SnacksPickerLabel" },
                { Snacks.picker.util.align(hex, 9), "SnacksPickerComment" },
                { item.job.desc, "SnacksPickerComment" },
            }
        end,
        preview = function(ctx)
            ctx.preview:reset()
            ctx.preview:set_title(ctx.item.job.key)
            ctx.preview:set_lines(sample_cpp)
            ctx.preview:highlight({ lang = "cpp" })
        end,
        confirm = function(picker, item)
            picker:close()
            if item then
                last_idx = item.idx
                vim.schedule(function() pick_colour(item.job, item.idx) end)
            end
        end,
    })
end

vim.api.nvim_create_user_command("Palette", M.pick, { desc = "Tune one Monochrome palette colour with live preview" })

return M
