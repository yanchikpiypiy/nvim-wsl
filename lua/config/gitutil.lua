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

local function lines(cwd, args)
    local out = vim.fn.systemlist(vim.list_extend({ "git", "-C", cwd or vim.fn.getcwd() }, args))
    return vim.v.shell_error == 0 and out or {}
end

-- Snacks `transform` for branch pickers. Hides branches whose remote is gone (squash-merged PRs)
-- and pushed branches already merged into main; local-only ones stay so a fresh empty branch
-- isn't hidden. Remote branches show unless merged (main and this branch's upstream always stay);
-- a remote copy is kept beside its local branch since the two can differ.
function M.branch_filter(cwd)
    local main = M.main_base(cwd, true)
    local hide, pushed = {}, {}
    for _, row in ipairs(lines(cwd, { "for-each-ref",
        "--format=%(refname:short)%09%(upstream:short)%09%(upstream:track)", "refs/heads/" })) do
        local name, up, track = row:match("^([^\t]*)\t([^\t]*)\t(.*)$")
        if name then
            pushed[name] = up ~= ""
            if track:find("gone") then hide[name] = true end
        end
    end
    if main then
        for _, b in ipairs(lines(cwd, { "branch", "-a", "--merged", main, "--format=%(refname)" })) do
            local l, r = b:match("^refs/heads/(.+)$"), b:match("^refs/(remotes/.+)$")
            if l and pushed[l] then hide[l] = true end
            if r then hide[r] = true end
        end
    end
    hide.main, hide.master = nil, nil
    if main then hide["remotes/" .. main] = nil end
    local up = lines(cwd, { "rev-parse", "--abbrev-ref", "@{upstream}" })[1]
    if up then hide["remotes/" .. up] = nil end
    return function(item)
        if item.current then return end
        if hide[item.branch or ""] or (item.branch or ""):match("/HEAD$") then return false end
    end
end

-- Range for a commit picker: just this branch's own commits, or nil on main / with nothing ahead.
function M.branch_range(cwd)
    local main = M.main_base(cwd, true)
    if not main then return end
    local ahead = tonumber(lines(cwd, { "rev-list", "--count", main .. "..HEAD" })[1])
    if ahead and ahead > 0 then return main .. "..HEAD" end
end

return M
