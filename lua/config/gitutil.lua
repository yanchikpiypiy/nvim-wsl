-- Small git helpers shared by the git keymaps (snacks pickers, diffview, review).
local M = {}

-- First of origin/main / origin/master / main / master that exists, or nil.
-- Remote first so "what did this branch change" matches what a PR would show.
function M.main_base(cwd, quiet)
    for _, base in ipairs({ "origin/main", "origin/master", "main", "master" }) do
        local cmd = cwd and { "git", "-C", cwd, "rev-parse", "--verify", "-q", base }
            or { "git", "rev-parse", "--verify", "-q", base }
        if vim.fn.system(cmd) ~= "" and vim.v.shell_error == 0 then
            return base
        end
    end
    if not quiet then vim.notify("No main/master branch found", vim.log.levels.WARN) end
end

return M
