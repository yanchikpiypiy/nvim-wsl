-- Fuzzy picker (replaces telescope). snacks.picker is fast on large repos,
-- frecency-aware (smart finder), and owns vim.ui.select (code actions).
-- fs/fg scope to the CURRENT buffer's git root, so in the C:\Cris multi-repo
-- tree you only search the subrepo you're in, not all repos at once.
local function root()
    local name = vim.api.nvim_buf_get_name(0)
    local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
    return vim.fs.root(dir, ".git") or vim.fn.getcwd()
end

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false, -- load early so ui.select (code actions) is owned from startup
    opts = {
        picker = {
            ui_select = true, -- route vim.ui.select (code actions) through the picker
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
    },
}
