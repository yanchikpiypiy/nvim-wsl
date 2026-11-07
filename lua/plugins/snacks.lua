-- Fuzzy picker (replaces telescope). snacks.picker is fast on large repos,
-- frecency-aware (smart finder), and owns vim.ui.select (code actions).
-- fs/fg scope to the CURRENT buffer's git root, so in the C:\Cris multi-repo
-- tree you only search the subrepo you're in, not all repos at once.
local function root()
    local name = vim.api.nvim_buf_get_name(0)
    local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
    return vim.fs.root(dir, ".git") or vim.fn.getcwd()
end

-- Return the first existing subdir of the repo root from a candidate list,
-- falling back to the repo root. Lets us scope searches to frontend/backend
-- (e.g. cris-erm/app and cris-erm/api) instead of the whole repo.
local function sub(candidates)
    local r = root()
    for _, c in ipairs(candidates) do
        local p = vim.fs.joinpath(r, c)
        if vim.fn.isdirectory(p) == 1 then return p end
    end
    return r
end
-- File finders look like oil: full window, plain list, no preview (<a-p> shows it)
local quick = {
    fullscreen = true,
    hidden = { "preview" },
    layout = {
        box = "vertical",
        backdrop = false,
        border = "none",
        { win = "input", height = 1, border = "none" },
        { win = "list", border = "top", title = " {title} {live} {flags}", title_pos = "left" },
        { win = "preview", title = "{preview}", height = 0.5, border = "top" },
    },
}

-- Folder finder: pick a directory by name, open it in oil
local function find_dirs()
    local cwd = root()
    Snacks.picker.pick({
        title = "Folders",
        layout = quick,
        format = "file",
        finder = function(opts, ctx)
            return require("snacks.picker.source.proc").proc(ctx:opts({
                cmd = "fd",
                args = { "--type", "d", "--hidden", "-E", ".git", "-E", "node_modules", "-E", "bin", "-E", "obj" },
                cwd = cwd,
                transform = function(item)
                    item.cwd = cwd
                    item.file = item.text
                    item.dir = true
                end,
            }), ctx)
        end,
        confirm = function(picker, item)
            picker:close()
            if item then require("oil").open(vim.fs.joinpath(cwd, item.file)) end
        end,
    })
end

local function fe_dir() return sub({ "app", "frontend", "web", "client", "ui" }) end
local function be_dir() return sub({ "api", "backend", "server", "src" }) end

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false, -- load early so ui.select (code actions) is owned from startup
    opts = {
        -- Toast notifications in the corner. Without this, every vim.notify /
        -- Snacks.notify (e.g. "Stash applied", checkout, hunk staged, buffer
        -- reloaded) only flashes once in the command line and is easy to miss,
        -- so git actions feel like nothing happened. This surfaces them all.
        notifier = {
            enabled = true,
            timeout = 3000,
            style = "compact",
        },
        picker = {
            ui_select = true, -- route vim.ui.select (code actions) through the picker
            previewers = { diff = { style = "terminal", cmd = { "delta" } } },
            sources = {
                grep = {
                    hidden = true,
                    exclude = {
                        ".git", "bin", "obj", "build", "node_modules", ".vs", ".idea", "packages",
                        "TestResults", "dist", "*.map", "*.min.js", "*.min.css", "*.svg",
                        "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "*.lock",
                    },
                },
                smart = { layout = quick },
                recent = { layout = quick },
                buffers = { layout = quick },
                git_files = { layout = quick },
                files = {
                    layout = quick,
                    hidden = true, -- show dotfiles (gitignored still excluded)
                    exclude = {
                        ".git", "bin", "obj", "build", "node_modules",
                        ".vs", ".idea", "packages", "TestResults", "dist",
                        "*.exe", "*.dll", "*.pdb",
                        -- asset / generated noise (useless in a code finder)
                        "*.map", "*.min.js", "*.min.css",
                        "*.png", "*.jpg", "*.jpeg", "*.gif", "*.svg", "*.ico",
                        "*.woff", "*.woff2", "*.ttf", "*.eot",
                    },
                },
            },
        },
    },
    keys = {
        -- Files (scoped to the current repo)
        { "<leader>fs", function() Snacks.picker.files({ cwd = root() }) end, desc = "Find files (current repo)" },
        { "<leader>ff", function() Snacks.picker.smart({ cwd = root() }) end, desc = "Smart find (recent + files)" },
        { "<leader>fg", function() Snacks.picker.grep({ cwd = root() }) end,  desc = "Live grep (current repo)" },
        { "<leader>fd", find_dirs, desc = "Find folder (opens in oil)" },
        { "<leader>fw", function() Snacks.picker.grep_word({ cwd = root() }) end, mode = { "n", "x" }, desc = "Grep word/selection (current repo)" },
        -- Scoped to frontend (app/) vs backend (api/) — split search
        { "<leader>fe", function() Snacks.picker.files({ cwd = fe_dir() }) end, desc = "Find files (frontend)" },
        { "<leader>fa", function() Snacks.picker.files({ cwd = be_dir() }) end, desc = "Find files (backend/api)" },
        { "<leader>fE", function() Snacks.picker.grep({ cwd = fe_dir() }) end,  desc = "Live grep (frontend)" },
        { "<leader>fA", function() Snacks.picker.grep({ cwd = be_dir() }) end,  desc = "Live grep (backend/api)" },
        -- Whole cwd tree (all repos) when you actually want it
        { "<leader>fS", function() Snacks.picker.files() end, desc = "Find files (all / cwd)" },
        { "<leader>fG", function() Snacks.picker.grep() end,  desc = "Live grep (all / cwd)" },
        -- Misc pickers
        { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
        { "<leader>fr", function() Snacks.picker.recent() end,  desc = "Recent files" },
        { "<leader>fR", function() Snacks.picker.resume() end,  desc = "Resume last picker" },
        {
            "<leader>fc",
            function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end,
            desc = "Find config file",
        },
        -- Git pickers
        { "<leader>gf", function() Snacks.picker.git_files() end,    desc = "Git files (tracked)" },
        { "<leader>gt", function() Snacks.picker.git_status() end,   desc = "Git status (changed files)" },
        -- To review a branch/commit without checking it out: <leader>gn, then w / s.
        {
            "<leader>gc",
            function()
                local range = require("config.gitutil").branch_range(root())
                Snacks.picker.git_log({ cwd = root(), cmd_args = range and { range } or nil })
            end,
            desc = "Git commits (this branch's own, else full log)",
        },
        { "<leader>gA", function() Snacks.picker.git_log({ cwd = root() }) end, desc = "Git commits (full log)" },
        { "<leader>gC", function() Snacks.picker.git_log_file() end, desc = "Git commits (this file)" },
        {
            "<leader>gl",
            function()
                Snacks.picker.git_branches({ cwd = root(), transform = require("config.gitutil").branch_filter(root()) })
            end,
            desc = "Git branches (active only)",
        },
        { "<leader>gL", function() Snacks.picker.git_branches({ all = true }) end, desc = "Git branches (everything)" },
        { "<leader>gz", function() Snacks.picker.git_stash() end,    desc = "Git stash" },
        -- Hunk lists rendered through delta (j/k = next/prev hunk, preview on the right).
        -- gv: uncommitted hunks (Tab stages the hunk under the cursor).
        -- gV: hunks this branch changed vs main (merge-base, like main...HEAD).
        -- In-buffer review of the same (panel + gitsigns base, ]r/]c) is <leader>gn.
        -- Side-by-side buffer diffs are :DiffviewOpen / :DiffviewOpen main...HEAD.
        { "<leader>gv", function() Snacks.picker.git_diff() end, desc = "Hunks: uncommitted" },
        {
            "<leader>gV",
            function()
                local base = require("config.gitutil").main_base()
                if base then Snacks.picker.git_diff({ base = base }) end
            end,
            desc = "Hunks: branch vs main",
        },
    },
}
