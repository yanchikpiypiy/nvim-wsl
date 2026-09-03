-- Small git helpers shared by the git keymaps (snacks pickers, diffview).
local M = {}

-- First of main / master / origin/main / origin/master that exists in this
-- repo, or nil. Used as the base for "what did this branch change" views.
function M.main_base()
    for _, base in ipairs({ "main", "master", "origin/main", "origin/master" }) do
        if vim.fn.system({ "git", "rev-parse", "--verify", "-q", base }) ~= "" then
            return base
        end
    end
    vim.notify("No main/master branch found", vim.log.levels.WARN)
end

return M
