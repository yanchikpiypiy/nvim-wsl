-- Local, single-pane PR/commit review — no octo required.
--
-- Pick a SCOPE (an open PR, the branch vs main, a commit, or "since a commit"),
-- get its changed files in a snacks picker, and open them as real buffers.
-- gitsigns' diff base is set to match the scope, so each file shows that
-- scope's changes as hunks you jump with ]c / [c and inspect with <leader>gp /
-- <leader>gP. One window, no diffview.
--
-- The selector = OPEN PRs (via gh) + LOCAL branches with unmerged work
-- (`--no-merged main`). So you get real PRs AND WIP branches that never opened a
-- PR, but not the pile of stale/merged branches.
--
-- Keys:
--   <leader>gn   Review MENU — pick a scope: PR/branch (vs main) / a commit /
--                since a commit / current branch / reset. Whatever you pick
--                becomes the active scope (and is remembered for grl).
--   <leader>grl  List the files for the chosen scope again and jump between
--                them (falls back to "where I am now" if nothing's chosen yet).
--   <leader>gN   In review -> go COMPLETELY back (original branch, file, cursor,
--                review off). Not in review -> same menu as <leader>gn.
--
-- A "REVIEW …" badge shows in the statusline while a session is active.
--
-- gitsigns' base is GLOBAL + STICKY: once set, every file diffs against it until
-- you exit. It does NOT turn off when you switch files. Exit with <leader>gN /
-- q / the menu's Reset / <leader>gM.

local M = {}

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "Review" })
end

local function root()
    local name = vim.api.nvim_buf_get_name(0)
    local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
    return vim.fs.root(dir, ".git") or vim.fn.getcwd()
end

local function git(cwd, args)
    local cmd = { "git", "-C", cwd }
    vim.list_extend(cmd, args)
    local out = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 then return nil end
    return out
end

local function first(cwd, args)
    local out = git(cwd, args)
    return out and out[1] or nil
end

local function base_ref(cwd)
    for _, ref in ipairs({ "origin/main", "origin/master", "main", "master" }) do
        if git(cwd, { "rev-parse", "--verify", "--quiet", ref }) then return ref end
    end
end

-- Current branch name, or the raw commit sha if HEAD is detached.
local function current_ref(cwd)
    return first(cwd, { "symbolic-ref", "--quiet", "--short", "HEAD" })
        or first(cwd, { "rev-parse", "HEAD" })
end

-- Snapshot of where we are, to return to on exit.
local function capture(cwd)
    local file = vim.api.nvim_buf_get_name(0)
    local ok, cur = pcall(vim.api.nvim_win_get_cursor, 0)
    return {
        cwd = cwd,
        branch = current_ref(cwd),
        file = (file ~= "" and vim.fn.filereadable(file) == 1) and file or nil,
        cursor = ok and cur or nil,
    }
end

-- gitsigns' change_base is ASYNC. `cb` runs once the base is actually applied,
-- so callers can open files only AFTER it's in effect (otherwise a freshly
-- opened buffer can attach before the base lands and show no hunks).
local function set_base(rev, cb)
    local ok, gs = pcall(require, "gitsigns")
    if ok then
        gs.change_base(rev, true, function()
            gs.refresh() -- re-diff already-open buffers vs the new base (not just freshly-opened ones)
            -- Rescue new/renamed files that don't exist at the rev base (gitsigns
            -- can't diff those, so they'd show ZERO hunks). Only meaningful when
            -- setting a rev base; on reset (rev=nil) it's a harmless no-op.
            -- Files opened later (e.g. from the picker) are caught by gitsigns'
            -- BufReadPost/BufWinEnter autocmd, which runs the same rescue.
            if rev and _G.__gitsigns_fixup_all then
                vim.schedule(function() pcall(_G.__gitsigns_fixup_all) end)
            end
            if cb then vim.schedule(cb) end
        end)
    elseif cb then
        vim.schedule(cb)
    end
end


-- ── review session state (for the badge, q exit, and full return) ──────────
M._active = false
M._label = nil
M._session = nil
M._origin = nil -- where we were when the CURRENT review began (branch/file/cursor)

-- The return point for `back`. Captured by the entry points (menu / grl) BEFORE
-- any picker opens, so branch + file + cursor are the user's real spot — not a
-- picker buffer. Reused for the whole session.
local function mark_origin()
    if not M._active then M._origin = capture(root()) end
end

local function origin_session()
    return M._origin or capture(root())
end

function M.is_active() return M._active end

function M.status()
    return M._active and ("REVIEW  " .. (M._label or "")) or ""
end

local function enter(session, label)
    M._active = true
    M._session = session
    M._label = label
    pcall(function() require("lualine").refresh() end)
end

local function teardown()
    M._active = false
    M._label = nil
    M._reopen = nil
    M._origin = nil
    pcall(function() require("lualine").refresh() end)
end

-- ── the exit: reset base, restore branch + file + cursor ───────────────────
function M.back()
    set_base(nil)
    local s = M._session
    teardown()
    M._session = nil
    if not s then
        notify("Diff base reset (no session to return to)")
        return
    end
    -- Switch back to the original branch if we're not already on it.
    if s.branch and current_ref(s.cwd) ~= s.branch then
        local co = vim.system({ "git", "checkout", s.branch }, { cwd = s.cwd, text = true }):wait()
        if co.code ~= 0 then
            notify("Base reset, but could not switch to " .. s.branch
                .. " (uncommitted changes?): " .. (co.stderr or ""), vim.log.levels.ERROR)
            return
        end
        vim.cmd("checktime")
    end
    -- Reopen the file + cursor we were on when review started.
    if s.file and vim.fn.filereadable(s.file) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(s.file))
        if s.cursor then pcall(vim.api.nvim_win_set_cursor, 0, s.cursor) end
    end
    notify("Back on " .. (s.branch or "?") .. " — review off")
end

M.reset = M.back -- menu "Reset" is just the full exit

-- ── a picker over a list of changed files ──────────────────────────────────
-- Returns a function that opens the list; used both by scoped reviews (below)
-- and by the ad-hoc "files vs current base" list in M.list.
-- `base_rev` (optional) is what each file is diffed against for the preview.
local function file_picker(cwd, files, title, base_rev)
    local items = {}
    for _, f in ipairs(files) do
        -- snacks resolves path as `cwd .. "/" .. file`, so keep `file` relative.
        items[#items + 1] = { text = f, file = f, cwd = cwd }
    end
    return function()
        Snacks.picker.pick({
            title = title,
            items = items,
            format = "file",
            -- Preview = this file's diff against the review base (working tree vs
            -- base, i.e. exactly the hunks gitsigns shows), rendered through delta
            -- (previewers.diff.style = "terminal" in snacks.lua). Computed lazily.
            preview = function(ctx)
                if not ctx.item.diff then
                    local args = { "git", "-C", cwd, "diff", "--no-color", "--no-ext-diff" }
                    if base_rev then args[#args + 1] = base_rev end
                    vim.list_extend(args, { "--", ctx.item.file })
                    ctx.item.diff = vim.system(args, { text = true }):wait().stdout or ""
                end
                return require("snacks.picker.preview").diff(ctx)
            end,
            confirm = function(picker, item)
                picker:close()
                if item and item.file then
                    local abs = item.cwd and vim.fs.joinpath(item.cwd, item.file) or item.file
                    vim.cmd("edit " .. vim.fn.fnameescape(abs))
                end
            end,
        })
    end
end

-- ── open a scope's changed files ───────────────────────────────────────────
local function open_review(cwd, files, title, base_rev, session, label)
    if not files or #files == 0 then
        notify("No changed files for: " .. title, vim.log.levels.WARN)
        return
    end
    -- Remember how to re-open this exact list so <leader>grl can bring it back
    -- for whatever scope you picked, without re-choosing.
    M._reopen = file_picker(cwd, files, title, base_rev)
    -- Apply the base FIRST, then mark active + open — so files show hunks.
    set_base(base_rev, function()
        enter(session, label)
        M._reopen()
    end)
end

local function do_pr(cwd, session)
    local base = base_ref(cwd)
    if not base then
        notify("No main/master branch found to diff against", vim.log.levels.WARN)
        return
    end
    local mb = first(cwd, { "merge-base", "HEAD", base })
    if not mb then
        notify("Could not compute merge-base with " .. base, vim.log.levels.WARN)
        return
    end
    open_review(cwd, git(cwd, { "diff", "--name-only", mb, "HEAD" }),
        "PR: files changed vs " .. base, mb, session, session.label or ("vs " .. base))
end

function M.pr(cwd)
    cwd = cwd or root()
    do_pr(cwd, origin_session())
end

-- Review a single commit's own changes. base = C^, so exact only if C == HEAD
-- (otherwise you also see commits after C — we warn).
function M.review_commit(cwd, sha, session)
    cwd = cwd or root()
    session = session or origin_session()
    local head_full = first(cwd, { "rev-parse", "HEAD" })
    local sha_full = first(cwd, { "rev-parse", sha })
    if head_full and sha_full and head_full ~= sha_full then
        notify("Commit " .. sha .. " is not HEAD — hunks show its changes PLUS "
            .. "everything after it. Use 'Since' or checkout it for an isolated view.",
            vim.log.levels.WARN)
    end
    local subj = first(cwd, { "log", "-1", "--format=%s", sha }) or ""
    open_review(cwd, git(cwd, { "diff", "--name-only", sha .. "^", sha }),
        "Commit " .. sha .. ": " .. subj, sha .. "^", session, "commit " .. sha)
end

-- Review everything changed SINCE a commit (base = that commit, tip = HEAD).
function M.review_since(cwd, sha, session)
    cwd = cwd or root()
    session = session or origin_session()
    open_review(cwd, git(cwd, { "diff", "--name-only", sha, "HEAD" }),
        "Changes since " .. sha, sha, session, "since " .. sha)
end

-- Pick from THIS branch's own commits (what it added on top of main, i.e. the
-- PR's commits) — not the entire history. Falls back to full log only if the
-- branch has nothing ahead of main.
local function pick_commit(cwd, title, on_pick)
    local base = base_ref(cwd)
    local range = base and (base .. "..HEAD") or "HEAD"
    local lines = git(cwd, { "log", "--pretty=format:%h%x09%s%x09%an%x09%ad", "--date=short", range })
    if not lines or #lines == 0 then
        notify("No commits" .. (base and (" ahead of " .. base) or "") .. " on this branch",
            vim.log.levels.WARN)
        return
    end
    local items = {}
    for _, l in ipairs(lines) do
        local sha, subj, an, ad = l:match("^(%S+)\t([^\t]*)\t([^\t]*)\t(.*)$")
        if sha then
            items[#items + 1] = {
                text = string.format("%s  %s  (%s, %s)", sha, subj, an, ad),
                sha = sha,
                cwd = cwd,
            }
        end
    end
    Snacks.picker.pick({
        title = title,
        items = items,
        format = "text",
        confirm = function(picker, item)
            picker:close()
            if item and item.sha then on_pick(item.sha) end
        end,
    })
end

-- The one selector everything is filtered through: things worth reviewing =
-- OPEN PRs (via gh) + LOCAL branches with unmerged work. Picking one checks it
-- out and calls `on_pick(label)`; the ORIGIN (where back returns) was already
-- captured by the caller before this picker opened, so it isn't touched here.
local function pick_target(cwd, title, on_pick)
    local base = base_ref(cwd)
    local items = {}
    local seen = {} -- branch names already listed as a PR, to avoid duplicates

    -- Open PRs (if gh is available).
    if vim.fn.executable("gh") == 1 then
        local res = vim.system({
            "gh", "pr", "list", "--state", "open", "--limit", "100",
            "--json", "number,title,headRefName,author,isDraft",
        }, { cwd = cwd, text = true }):wait()
        if res.code == 0 then
            local ok, prs = pcall(vim.json.decode, res.stdout or "")
            if ok and type(prs) == "table" then
                for _, p in ipairs(prs) do
                    local author = (p.author and p.author.login) or "?"
                    local draft = p.isDraft and " [draft]" or ""
                    items[#items + 1] = {
                        text = string.format("PR #%d  %s  (%s)%s", p.number, p.title, author, draft),
                        kind = "pr", pr = p.number, cwd = cwd,
                    }
                    if p.headRefName then seen[p.headRefName] = true end
                end
            end
        end
    end

    -- Local branches worth reviewing: exclude ones already merged into main and
    -- any already shown as a PR, sort by most-recent commit, and cap the list so
    -- your active WIP branches surface at the top instead of a wall of old ones.
    if base then
        local merged = {}
        for _, b in ipairs(git(cwd, { "branch", "--merged", base, "--format=%(refname:short)" }) or {}) do
            merged[vim.trim(b)] = true
        end
        local rows = git(cwd, {
            "for-each-ref", "--sort=-committerdate",
            "--format=%(refname:short)%09%(committerdate:relative)", "refs/heads/",
        }) or {}
        local added, CAP = 0, 20
        for _, row in ipairs(rows) do
            local b, when = row:match("^([^\t]+)\t(.*)$")
            b = b and vim.trim(b)
            if b and b ~= "" and not seen[b] and not merged[b] then
                items[#items + 1] = {
                    text = string.format("local: %s  (%s)", b, when or ""),
                    kind = "branch", branch = b, cwd = cwd,
                }
                added = added + 1
                if added >= CAP then break end
            end
        end
    end

    if #items == 0 then
        notify("No open PRs or unmerged local branches to review", vim.log.levels.WARN)
        return
    end

    Snacks.picker.pick({
        title = title,
        items = items,
        format = "text",
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            local label
            if item.kind == "pr" then
                notify("Checking out PR #" .. item.pr .. " …")
                local co = vim.system({ "gh", "pr", "checkout", tostring(item.pr) },
                    { cwd = cwd, text = true }):wait()
                if co.code ~= 0 then
                    notify("Checkout failed (uncommitted changes?): " .. (co.stderr or ""),
                        vim.log.levels.ERROR)
                    return
                end
                label = "PR #" .. item.pr
            else
                if current_ref(cwd) ~= item.branch then
                    local co = vim.system({ "git", "checkout", item.branch },
                        { cwd = cwd, text = true }):wait()
                    if co.code ~= 0 then
                        notify("Checkout failed (uncommitted changes?): " .. (co.stderr or ""),
                            vim.log.levels.ERROR)
                        return
                    end
                end
                label = item.branch
            end
            vim.cmd("checktime")
            on_pick(label)
        end,
    })
end

-- Pick a PR/branch -> checkout -> review its whole diff vs main.
function M.prs()
    local cwd = root()
    local session = origin_session() -- captured BEFORE any picker (true origin)
    pick_target(cwd, "PRs + local branches — review vs main", function(label)
        session.label = label
        do_pr(cwd, session)
    end)
end

-- Pick a PR/branch -> checkout -> pick one of its commits -> review it.
function M.commit()
    local cwd = root()
    local session = origin_session()
    pick_target(cwd, "PRs + local branches — pick one, then a commit", function(label)
        session.label = label
        pick_commit(cwd, "Commits — pick one to review", function(sha)
            M.review_commit(cwd, sha, session)
        end)
    end)
end

-- Pick a PR/branch -> checkout -> pick a commit -> review everything since it.
function M.since()
    local cwd = root()
    local session = origin_session()
    pick_target(cwd, "PRs + local branches — pick one, then a commit (since)", function(label)
        session.label = label
        pick_commit(cwd, "Commits — review changes SINCE", function(sha)
            M.review_since(cwd, sha, session)
        end)
    end)
end

function M.menu()
    mark_origin() -- capture the real spot before any picker opens
    local choices = {
        { label = "PR/branch — review vs main",                       fn = M.prs },
        { label = "Commit — pick a PR/branch, then one of its commits", fn = M.commit },
        { label = "Since — pick a PR/branch, then a commit (changes since)", fn = M.since },
        { label = "Current branch — files vs main (no picker)",       fn = function() M.pr() end },
        { label = "Reset — exit review (base back to index)",         fn = M.back },
    }
    vim.ui.select(choices, {
        prompt = "Local review:",
        format_item = function(c) return c.label end,
    }, function(choice)
        if choice then choice.fn() end
    end)
end

-- <leader>gN: go back if reviewing, otherwise open the scope menu.
function M.gN()
    if M._active then M.back() else M.menu() end
end

-- <leader>grl: bring back the file list for the current comparison.
-- Precedence:
--   1. A scope chosen from the <leader>gn menu → replay that exact list.
--   2. Otherwise, if <leader>go / <leader>gm pointed the gitsigns base at a
--      branch or commit → list the files that differ between THAT base and HEAD.
--      This is the "files this branch changed vs another branch" list, and it
--      rebuilds each press so it always tracks whatever go last set. (go = pick
--      what to compare against, grl = list the files — the two compose.)
--   3. Otherwise fall back to "where I am now": on a branch → its changes vs
--      main; detached at a commit → that commit's own files.
function M.list()
    if M._reopen then
        M._reopen()
        return
    end
    mark_origin() -- entering review directly via grl
    local cwd = root()
    local ok, cfg = pcall(require, "gitsigns.config")
    local base = ok and cfg.config and cfg.config.base
    if base and vim.trim(tostring(base)) ~= "" then
        base = tostring(base)
        local files = git(cwd, { "diff", "--name-only", base, "HEAD" })
        if not files or #files == 0 then
            notify("No files differ between HEAD and base (" .. base .. ")", vim.log.levels.WARN)
            return
        end
        -- base is already applied by go/gm; just list. Ephemeral (not remembered),
        -- so the next grl re-reads the current base instead of a stale list.
        file_picker(cwd, files, "Files changed vs " .. base, base)()
        return
    end
    local branch = first(cwd, { "symbolic-ref", "--quiet", "--short", "HEAD" })
    if branch then
        M.pr(cwd) -- on a branch → its changes vs main
    else
        local sha = first(cwd, { "rev-parse", "HEAD" })
        if sha then
            M.review_commit(cwd, sha) -- detached → this commit's files
        else
            notify("Could not resolve HEAD", vim.log.levels.WARN)
        end
    end
end

local map = vim.keymap.set
map("n", "<leader>gn",  M.menu, { silent = true, desc = "Review: menu (pick scope)" })
map("n", "<leader>gN",  M.gN,   { silent = true, desc = "Review: back / menu" })
map("n", "<leader>grl", M.list, { silent = true, desc = "Review: list files (chosen scope)" })

return M
