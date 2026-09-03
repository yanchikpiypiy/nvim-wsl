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
local function fe_dir() return sub({ "app", "frontend", "web", "client", "ui" }) end
local function be_dir() return sub({ "api", "backend", "server", "src" }) end

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false, -- load early so ui.select (code actions) is owned from startup
    opts = {
        picker = {
            ui_select = true, -- route vim.ui.select (code actions) through the picker
            previewers = { diff = { builtin = false, cmd = { "delta" } } },
            sources = {
                files = {
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
        { "<leader>gc", function() Snacks.picker.git_log() end,      desc = "Git commits (log)" },
        { "<leader>gC", function() Snacks.picker.git_log_file() end, desc = "Git commits (this file)" },
        { "<leader>gl", function() Snacks.picker.git_branches() end, desc = "Git branches" },
        { "<leader>gz", function() Snacks.picker.git_stash() end,    desc = "Git stash" },
        -- Hunk lists rendered through delta (j/k = next/prev hunk, preview on the right).
        -- gv: uncommitted hunks (Tab stages the hunk under the cursor).
        -- gm: hunks this branch changed vs main (merge-base, like main...HEAD).
        -- Side-by-side buffer diffs of the same are :DiffviewOpen / :DiffviewOpen main...HEAD.
        { "<leader>gv", function() Snacks.picker.git_diff() end, desc = "Hunks: uncommitted" },
        {
            "<leader>gm",
            function()
                local base = require("config.gitutil").main_base()
                if base then Snacks.picker.git_diff({ base = base }) end
            end,
            desc = "Hunks: branch vs main",
        },
    },
}
