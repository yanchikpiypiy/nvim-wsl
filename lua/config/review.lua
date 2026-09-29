-- Review panel: a left sidebar over what a scope changed (uncommitted and
-- untracked files included). Other branches / PRs / single commits are opened
-- in their own worktree, so your tree is never checked out from under you.
-- Keys and behaviour: README.md → "Review mode".

local gitutil = require("config.gitutil")

local M = {}

local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
local WIDTH = 46
local ns = vim.api.nvim_create_namespace("gitreview")
local aug = vim.api.nvim_create_augroup("GitReview", { clear = true })

local function define_hl()
    for name, link in pairs({
        GitReviewTitle = "Title", GitReviewHeader = "Label", GitReviewDim = "Comment",
        GitReviewAdd = "Added", GitReviewDel = "Removed", GitReviewMod = "Changed",
        GitReviewViewed = "DiagnosticOk", GitReviewLocal = "DiagnosticWarn", GitReviewKey = "Special",
    }) do
        vim.api.nvim_set_hl(0, name, { link = link, default = true })
    end
end
define_hl()
vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = define_hl })

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "Review" })
end

local function gitcmd(cwd, args)
    return vim.list_extend({ "git", "-c", "core.quotePath=false", "-C", cwd }, args)
end

local function git(cwd, args)
    local out = vim.fn.systemlist(gitcmd(cwd, args))
    if vim.v.shell_error ~= 0 then return nil end
    return out
end

local function first(cwd, args)
    local out = git(cwd, args)
    return out and out[1] or nil
end

local function run(cmd, cwd, cb)
    vim.system(cmd, { cwd = cwd, text = true }, function(r)
        vim.schedule(function() cb(r.code == 0, r.stdout or "", r.stderr or "") end)
    end)
end

local function git_async(cwd, args, cb)
    run(gitcmd(cwd, args), nil, function(ok, out, err)
        cb(ok and vim.split(out, "\n", { trimempty = true }) or nil, err)
    end)
end

local function realpath(p)
    return p and (vim.uv.fs_realpath(p) or vim.fs.normalize(p)) or nil
end

local function toplevel(path)
    local dir = (path and path ~= "") and vim.fs.dirname(path) or vim.fn.getcwd()
    if vim.fn.isdirectory(dir) == 0 then dir = vim.fn.getcwd() end
    return first(dir, { "rev-parse", "--show-toplevel" })
end

local function ref_name(tree)
    return first(tree, { "symbolic-ref", "--quiet", "--short", "HEAD" })
        or first(tree, { "rev-parse", "--short", "HEAD" }) or "?"
end

-- ── worktrees ───────────────────────────────────────────────────────────────
local function worktrees(cwd)
    local list, cur = {}, nil
    for _, l in ipairs(git(cwd, { "worktree", "list", "--porcelain" }) or {}) do
        local path = l:match("^worktree (.+)$")
        if path then
            cur = { path = path }
            list[#list + 1] = cur
        elseif cur then
            cur.branch = l:match("^branch refs/heads/(.+)$") or cur.branch
            if l == "bare" then cur.bare = true end
        end
    end
    return vim.tbl_filter(function(w)
        return not w.bare and vim.fn.isdirectory(w.path) == 1
    end, list)
end

-- <parent>/<repo>.review — every review worktree lives here and is disposable.
local function review_root(cwd)
    local common = first(cwd, { "rev-parse", "--path-format=absolute", "--git-common-dir" })
    if not common then return nil end
    local main = vim.fs.dirname(common)
    return vim.fs.joinpath(vim.fs.dirname(main), vim.fs.basename(main) .. ".review")
end

local function under(path, root)
    return path ~= nil and root ~= nil and (path .. "/"):sub(1, #root + 1) == root .. "/"
end

-- Close buffers/LSPs living in `path`, then force-remove the worktree.
local function drop_tree(cwd, path, cb)
    local root = realpath(path)
    local spare
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if under(realpath(vim.api.nvim_buf_get_name(b)), root) then
            for _, w in ipairs(vim.fn.win_findbuf(b)) do
                spare = spare or vim.api.nvim_create_buf(true, false)
                pcall(vim.api.nvim_win_set_buf, w, spare)
            end
            pcall(vim.api.nvim_buf_delete, b, { force = true })
        end
    end
    for _, c in ipairs(vim.lsp.get_clients()) do
        if c.root_dir and under(realpath(c.root_dir), root) then c:stop(true) end
    end
    local cmd = gitcmd(cwd, { "worktree", "remove", "--force", path })
    if cb then run(cmd, nil, cb) else vim.fn.system(cmd) end
end

-- Remove every review worktree except `keep` (list of paths); sync when `sync`.
local function sweep(cwd, keep, sync)
    -- Before the early return: a half-failed removal leaves the folder gone but git's record of it behind.
    git(cwd, { "worktree", "prune" })
    local root = review_root(cwd)
    if not root or vim.fn.isdirectory(root) == 0 then return end
    local rroot, kept = realpath(root), {}
    for _, k in ipairs(keep or {}) do kept[realpath(k)] = true end
    local todo = {}
    for _, w in ipairs(worktrees(cwd)) do
        local rp = realpath(w.path)
        if under(rp, rroot) and not kept[rp] then todo[#todo + 1] = w.path end
    end
    local function finish()
        git(cwd, { "worktree", "prune" })
        for name, kind in vim.fs.dir(root) do
            local p = vim.fs.joinpath(root, name)
            if kind == "directory" and not kept[realpath(p)] and not vim.tbl_contains(todo, p)
                and (vim.fn.filereadable(p .. "/.git") == 1 or vim.fn.empty(vim.fn.readdir(p)) == 1) then
                vim.fn.delete(p, "rf")
            end
        end
        vim.uv.fs_rmdir(root)
        if sync or #todo == 0 then return end
        local left = vim.fn.isdirectory(root) == 1 and vim.fn.readdir(root) or {}
        if #left == 0 then
            notify(string.format("Removed %d review cop%s", #todo, #todo == 1 and "y" or "ies"))
        else
            notify("Couldn't remove review copies " .. table.concat(left, ", ") .. " in " .. vim.fn.fnamemodify(root, ":~")
                .. " (a file is probably still open); ending the next review retries", vim.log.levels.WARN)
        end
    end
    if sync then
        for _, p in ipairs(todo) do drop_tree(cwd, p) end
        return finish()
    end
    local pending = #todo
    if pending == 0 then return finish() end
    for _, p in ipairs(todo) do
        drop_tree(cwd, p, function()
            pending = pending - 1
            if pending == 0 then finish() end
        end)
    end
end

-- Fresh detached worktree at `rev` (never holds a branch), replacing any old copy.
local function fresh_tree(cwd, slug, rev, cb)
    local root = review_root(cwd)
    if not root then return notify("Can't find the repo's git dir", vim.log.levels.ERROR) end
    local path = vim.fs.joinpath(root, (slug:gsub("[^%w%._-]", "-")))
    drop_tree(cwd, path)
    if vim.fn.isdirectory(path) == 1 then vim.fn.delete(path, "rf") end
    vim.fn.mkdir(root, "p")
    git(cwd, { "worktree", "prune" })
    notify("Creating review copy " .. vim.fn.fnamemodify(path, ":~") .. " …")
    git_async(cwd, { "worktree", "add", "--detach", path, rev }, function(out, err)
        if not out then return notify("worktree add failed: " .. err, vim.log.levels.ERROR) end
        cb(path)
    end)
end

-- ── gitsigns base (bridge in plugins/gitsigns.lua) ──────────────────────────
local function set_base(rev, cb)
    pcall(require, "gitsigns")
    if _G.__gitsigns_apply_base then
        _G.__gitsigns_apply_base(rev, cb and vim.schedule_wrap(cb))
    elseif cb then
        vim.schedule(cb)
    end
end

-- ── session ─────────────────────────────────────────────────────────────────
-- M.s = { origin, home (tree picked with w), tree (tree shown), scope, base,
--         label, names, files, commits, viewed, buf, win, main_win, help, map, gen }
M.s = nil

function M.is_active() return M.s ~= nil end

function M.status()
    return M.s and ("REVIEW  " .. (M.s.label or "")) or ""
end

local function lualine_refresh()
    pcall(function() require("lualine").refresh() end)
end

local function resolve(tree, scope)
    local k = scope.kind
    if k == "local" then return "HEAD" end
    if k == "branch" then
        local main = gitutil.main_base(tree, true)
        if not main then return nil, "no main/master branch" end
        local mb = first(tree, { "merge-base", "HEAD", main })
        if not mb then return nil, "no merge-base with " .. main end
        return mb, nil, main
    end
    if k == "commit" then
        return first(tree, { "rev-parse", "--verify", "--quiet", scope.ref .. "^" }) or EMPTY_TREE
    end
    local rev = first(tree, { "rev-parse", "--verify", "--quiet", scope.ref .. "^{commit}" })
    if not rev then return nil, "unknown ref " .. scope.ref end
    -- Against this branch's own remote copy, compare tips: a rebased branch only shares history below the
    -- whole stack. Against any other branch, compare from where they split, or its changes show reversed.
    local picked = scope.ref:gsub("^remotes/", "")
    local branch = first(tree, { "rev-parse", "--abbrev-ref", "HEAD" })
    local upstream = first(tree, { "rev-parse", "--abbrev-ref", "HEAD@{upstream}" })
    if picked == upstream or (branch and picked == "origin/" .. branch) then return rev end
    return first(tree, { "merge-base", "HEAD", rev }) or rev
end

local function make_label(tree, scope, main, name)
    local k = scope.kind
    if k == "commit" then
        return "commit " .. scope.ref:sub(1, 7) .. "  " .. (first(tree, { "log", "-1", "--format=%s", scope.ref }) or "")
    end
    local b = name or ref_name(tree)
    if k == "local" then return b .. " · uncommitted" end
    if k == "branch" then return b .. " vs " .. main end
    if k == "since" then return b .. " since " .. scope.ref:sub(1, 7) end
    return b .. " vs " .. scope.ref
end

local function load(s, done)
    local jobs = {
        numstat = { "diff", "--numstat", "--no-renames", s.base },
        status = { "diff", "--name-status", "--no-renames", s.base },
        untracked = { "ls-files", "--others", "--exclude-standard" },
        dirty = { "diff", "--name-only", "--no-renames", "HEAD" },
    }
    if s.scope.kind == "commit" then
        jobs.log = { "log", "-1", "--format=%h%x09%s%x09%ar", "HEAD" }
    elseif s.scope.kind ~= "local" then
        jobs.log = { "log", "-200", "--format=%h%x09%s%x09%ar", s.base .. "..HEAD" }
    end
    local res, pending = {}, vim.tbl_count(jobs)
    for key, args in pairs(jobs) do
        git_async(s.tree, args, function(out)
            res[key] = out or {}
            pending = pending - 1
            if pending == 0 then done(res) end
        end)
    end
end

local function build(res)
    local files, by, dirty = {}, {}, {}
    for _, p in ipairs(res.dirty) do dirty[p] = true end
    for _, l in ipairs(res.status) do
        local st, p = l:match("^(%a)%d*\t(.+)$")
        if p then
            by[p] = { path = p, status = st }
            files[#files + 1] = by[p]
        end
    end
    for _, l in ipairs(res.numstat) do
        local a, d, p = l:match("^(%S+)\t(%S+)\t(.+)$")
        if p and by[p] then by[p].add, by[p].del = tonumber(a), tonumber(d) end
    end
    for _, p in ipairs(res.untracked) do
        if not by[p] then
            by[p] = { path = p, status = "?" }
            files[#files + 1] = by[p]
        end
        dirty[p] = true
    end
    table.sort(files, function(a, b) return a.path < b.path end)
    for i, f in ipairs(files) do
        f.dirty, f.idx = dirty[f.path] or false, i
    end
    local commits = {}
    for _, l in ipairs(res.log or {}) do
        local sha, subj, when = l:match("^(%S+)\t([^\t]*)\t(.*)$")
        if sha then commits[#commits + 1] = { sha = sha, subject = subj, when = when } end
    end
    return files, commits
end

local function viewed_key(s, f) return s.tree .. "|" .. s.base .. "|" .. f.path end

-- ── panel rendering ─────────────────────────────────────────────────────────
local ST_HL = { A = "GitReviewAdd", ["?"] = "GitReviewAdd", D = "GitReviewDel" }

local HELP = {
    { "<CR> o", "open file · on a commit: review it" },
    { "p", "diff preview (delta)" },
    { "v", "mark viewed" },
    { "]r [r", "next / prev file (from anywhere)" },
    { "]c [c", "next / prev hunk (in the file)" },
    { "s", "change scope" },
    { "w", "review another branch / PR / worktree" },
    { "r", "refresh (re-resolve base)" },
    { "q", "hide panel (<leader>gn reopens)" },
    { "Q", "end review" },
}

local function render(s)
    if not (s.buf and vim.api.nvim_buf_is_valid(s.buf)) then return end
    local lines, hls, map = {}, {}, {}
    local function line(parts, item)
        local text = ""
        for _, p in ipairs(parts) do
            if p[2] then hls[#hls + 1] = { #lines, #text, #text + #p[1], p[2] } end
            text = text .. p[1]
        end
        lines[#lines + 1] = text
        map[#lines] = item
    end

    local where = s.tree == s.origin.tree and "this tree" or vim.fn.fnamemodify(s.tree, ":~")
    line({ { " REVIEW ", "GitReviewTitle" }, { s.label or "", "GitReviewHeader" } })
    line({ { " " .. where .. "  ·  base " .. (s.base or "?"):sub(1, 7), "GitReviewDim" } })

    if not s.files then
        line({})
        line({ { " loading…", "GitReviewDim" } })
    else
        local add, del, dirty, seen = 0, 0, 0, 0
        for _, f in ipairs(s.files) do
            add, del = add + (f.add or 0), del + (f.del or 0)
            if f.dirty then dirty = dirty + 1 end
            if s.viewed[viewed_key(s, f)] then seen = seen + 1 end
        end
        local sum = { { " " .. #s.files .. " files  " }, { "+" .. add, "GitReviewAdd" }, { " " }, { "-" .. del, "GitReviewDel" } }
        if dirty > 0 then sum[#sum + 1] = { "  ● " .. dirty .. " uncommitted", "GitReviewLocal" } end
        sum[#sum + 1] = { "  ✓ " .. seen .. "/" .. #s.files, "GitReviewViewed" }
        line(sum)
        line({})
        line({ { " Files", "GitReviewTitle" } })
        if #s.files == 0 then line({ { "   nothing changed", "GitReviewDim" } }) end
        for _, f in ipairs(s.files) do
            local seen_f = s.viewed[viewed_key(s, f)]
            local parts = {
                { seen_f and " ✓ " or "   ", "GitReviewViewed" },
                { f.status .. " ", ST_HL[f.status] or "GitReviewMod" },
                { vim.fs.basename(f.path), seen_f and "GitReviewDim" or nil },
            }
            local dir = vim.fs.dirname(f.path)
            if dir ~= "." then parts[#parts + 1] = { " " .. dir, "GitReviewDim" } end
            if f.status == "?" then
                parts[#parts + 1] = { "  new", "GitReviewAdd" }
            elseif f.add then
                parts[#parts + 1] = { "  +" .. f.add, "GitReviewAdd" }
                parts[#parts + 1] = { " -" .. f.del, "GitReviewDel" }
            elseif f.status ~= "D" then
                parts[#parts + 1] = { "  bin", "GitReviewDim" }
            end
            if f.dirty and s.scope.kind ~= "local" then parts[#parts + 1] = { " ●", "GitReviewLocal" } end
            line(parts, { file = f })
        end
        if #s.commits > 0 then
            line({})
            line({ { " Commits (" .. #s.commits .. ")", "GitReviewTitle" } })
            for _, c in ipairs(s.commits) do
                line({ { "   " .. c.sha, "GitReviewKey" }, { "  " .. c.subject }, { "  " .. c.when, "GitReviewDim" } },
                    { commit = c })
            end
        end
    end

    line({})
    if s.help then
        for _, h in ipairs(HELP) do
            line({ { string.format(" %-7s", h[1]), "GitReviewKey" }, { h[2], "GitReviewDim" } })
        end
    else
        line({ { " ?", "GitReviewKey" }, { " help  ", "GitReviewDim" }, { "s", "GitReviewKey" }, { " scope  ", "GitReviewDim" },
            { "w", "GitReviewKey" }, { " tree  ", "GitReviewDim" }, { "Q", "GitReviewKey" }, { " end", "GitReviewDim" } })
    end

    -- keep the cursor on the same file across re-renders
    local win = s.win and vim.api.nvim_win_is_valid(s.win) and s.win or nil
    local keep = win and s.map and s.map[vim.api.nvim_win_get_cursor(win)[1]]
    keep = keep and keep.file and keep.file.path

    vim.bo[s.buf].modifiable = true
    vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, lines)
    vim.bo[s.buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(s.buf, ns, 0, -1)
    for _, h in ipairs(hls) do
        vim.api.nvim_buf_set_extmark(s.buf, ns, h[1], h[2], { end_col = h[3], hl_group = h[4] })
    end
    s.map = map

    if win and keep then
        for lnum, it in pairs(map) do
            if it.file and it.file.path == keep then
                pcall(vim.api.nvim_win_set_cursor, win, { lnum, 0 })
                break
            end
        end
    end
end

local function refresh(s)
    if M.s ~= s then return end
    local gen = s.gen
    load(s, function(res)
        if M.s ~= s or s.gen ~= gen then return end
        s.files, s.commits = build(res)
        render(s)
    end)
end

local function apply(s, tree, scope)
    local base, err, main = resolve(tree, scope)
    if not base then return notify("Can't review: " .. err, vim.log.levels.WARN) end
    s.tree, s.scope, s.base = tree, scope, base
    s.label = make_label(tree, scope, main, s.names[tree])
    s.files, s.commits = nil, nil
    s.gen = (s.gen or 0) + 1
    render(s)
    lualine_refresh()
    set_base(base, function() refresh(s) end)
    sweep(s.origin.tree, { s.home, s.tree })
end

-- ── windows ─────────────────────────────────────────────────────────────────
local function panel_win(s)
    return s.win and vim.api.nvim_win_is_valid(s.win) and s.win or nil
end

local function is_normal_win(w)
    return vim.api.nvim_win_get_config(w).relative == ""
        and vim.bo[vim.api.nvim_win_get_buf(w)].buftype == ""
end

local function main_win(s)
    if s.main_win and vim.api.nvim_win_is_valid(s.main_win) and s.main_win ~= s.win then return s.main_win end
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if w ~= s.win and is_normal_win(w) then
            s.main_win = w
            return w
        end
    end
    s.main_win = vim.api.nvim_open_win(vim.api.nvim_create_buf(true, false), false, { split = "right", win = s.win })
    if panel_win(s) then vim.api.nvim_win_set_width(s.win, WIDTH) end
    return s.main_win
end

local function preview(s, f)
    local cols, rows = math.floor(vim.o.columns * 0.85), math.floor(vim.o.lines * 0.8)
    local cmd = f.status == "?"
        and ("git diff --no-ext-diff --no-index -- /dev/null " .. vim.fn.shellescape(f.path))
        or ("git diff --no-ext-diff " .. vim.fn.shellescape(s.base) .. " -- " .. vim.fn.shellescape(f.path))
    cmd = cmd .. " | delta --paging=never --width=" .. (cols - 2)
    local b = vim.api.nvim_create_buf(false, true)
    local w = vim.api.nvim_open_win(b, true, {
        relative = "editor", width = cols, height = rows, border = "rounded",
        row = math.floor((vim.o.lines - rows) / 2), col = math.floor((vim.o.columns - cols) / 2),
        title = " " .. f.path .. "  (q to close) ", title_pos = "center",
    })
    vim.fn.jobstart({ "sh", "-c", cmd }, { term = true, cwd = s.tree })
    for _, k in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", k, function() pcall(vim.api.nvim_win_close, w, true) end, { buffer = b, nowait = true })
    end
end

-- A deleted file has nothing to `:edit`, so it was the one status that never
-- opened in the main window -- <CR> could only ever throw the delta float at
-- you. Load the base version into a scratch buffer instead, so it reads like
-- any other file: searchable, yankable, treesitter-highlighted. `p` still gives
-- the diff.
local function open_deleted(s, f)
    s.gone = s.gone or {}
    local buf = s.gone[f.path]
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
        local lines = git(s.tree, { "show", s.base .. ":" .. f.path })
        if not lines then
            notify("No content for " .. f.path .. " at " .. s.base, vim.log.levels.WARN)
            return preview(s, f)
        end
        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        pcall(vim.api.nvim_buf_set_name, buf, f.path .. "  (deleted)")
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].swapfile = false
        vim.bo[buf].filetype = vim.filetype.match({ filename = f.path }) or ""
        vim.bo[buf].modifiable = false
        s.gone[f.path] = buf
    end
    local w = main_win(s)
    vim.api.nvim_set_current_win(w)
    vim.api.nvim_win_set_buf(w, buf)
end

local function open_file(s, f)
    if f.status == "D" then return open_deleted(s, f) end
    vim.api.nvim_set_current_win(main_win(s))
    vim.cmd("edit " .. vim.fn.fnameescape(vim.fs.joinpath(s.tree, f.path)))
end

local function focus_panel_on(s, f)
    local w = panel_win(s)
    if not (w and s.map) then return end
    for lnum, it in pairs(s.map) do
        if it.file == f then return pcall(vim.api.nvim_win_set_cursor, w, { lnum, 0 }) end
    end
end

-- ── pickers ─────────────────────────────────────────────────────────────────
local function pick_commit(tree, title, on_pick)
    local main = gitutil.main_base(tree, true)
    local mb = main and first(tree, { "merge-base", "HEAD", main })
    local fmt = "--format=%h%x09%s%x09%an%x09%ar"
    local lines = mb and git(tree, { "log", fmt, mb .. "..HEAD" }) or {}
    if #lines == 0 then lines = git(tree, { "log", fmt, "-100" }) or {} end
    local items = {}
    for _, l in ipairs(lines) do
        local sha, subj, an, ar = l:match("^(%S+)\t([^\t]*)\t([^\t]*)\t(.*)$")
        if sha then
            items[#items + 1] = { text = string.format("%s  %s  (%s, %s)", sha, subj, an, ar), sha = sha }
        end
    end
    if #items == 0 then return notify("No commits", vim.log.levels.WARN) end
    Snacks.picker.pick({
        title = title,
        items = items,
        format = "text",
        preview = function(ctx)
            if not ctx.item.diff then
                ctx.item.diff = vim.system(gitcmd(tree, { "show", "--no-color", "--no-ext-diff", ctx.item.sha }),
                    { text = true }):wait().stdout or ""
            end
            return require("snacks.picker.preview").diff(ctx)
        end,
        confirm = function(picker, item)
            picker:close()
            if item then on_pick(item.sha) end
        end,
    })
end

function M.set_scope(scope)
    local s = M.s
    if s then apply(s, s.home, scope) end
end

function M.set_home(path, name)
    local s = M.s
    if not s then return end
    s.home = path
    s.names[path] = name
    apply(s, path, { kind = "branch" })
    vim.cmd("checktime")
end

-- One commit, isolated: a detached worktree slot (reused) checked out at it.
function M.review_commit(sha)
    local s = M.s
    if not s then return end
    local full = first(s.home, { "rev-parse", sha })
    if not full then return notify("Can't resolve " .. sha, vim.log.levels.WARN) end
    fresh_tree(s.origin.tree, "_commit", full, function(p)
        apply(s, p, { kind = "commit", ref = full })
        vim.cmd("checktime")
    end)
end

function M.scope_menu()
    local s = M.s
    if not s then return end
    local choices = {
        { "Branch vs main — committed + uncommitted", function() M.set_scope({ kind = "branch" }) end },
        { "Uncommitted only — vs HEAD", function() M.set_scope({ kind = "local" }) end },
        { "One commit — isolated, in the review worktree", function()
            pick_commit(s.home, "Review one commit", M.review_commit)
        end },
        { "Since a commit — everything after it, plus uncommitted", function()
            pick_commit(s.home, "Review changes since", function(sha) M.set_scope({ kind = "since", ref = sha }) end)
        end },
        { "Against another branch — only what this branch changed since it split from it", function()
            local upstream = {}
            for _, row in ipairs(git(s.home, { "for-each-ref", "--format=%(refname:short)%09%(upstream:short)%09%(upstream:track)", "refs/heads/" }) or {}) do
                local name, up, track = row:match("^([^\t]*)\t([^\t]*)\t(.*)$")
                if name then upstream[name] = up == "" and "local only" or track:find("gone") and "gone" or "local" end
            end
            local label_hl = { current = "GitReviewAdd", ["local"] = "GitReviewKey", ["local only"] = "GitReviewLocal", gone = "GitReviewDel", remote = "GitReviewDim" }
            Snacks.picker.git_branches({
                all = true,
                cwd = s.home,
                title = "Review against…",
                format = function(item, picker)
                    local b = item.branch or ""
                    local label = item.current and "current" or b:match("^remotes/") and "remote" or upstream[b] or "local"
                    return vim.list_extend({ { string.format("%-11s", label), label_hl[label] } },
                        require("snacks.picker.format").git_branch(item, picker))
                end,
                confirm = function(picker, item)
                    picker:close()
                    local ref = item and (item.branch or item.commit)
                    if ref then M.set_scope({ kind = "ref", ref = vim.trim(ref) }) end
                end,
            })
        end },
    }
    vim.ui.select(choices, {
        prompt = "Review scope",
        format_item = function(c) return c[1] end,
    }, function(c) if c then c[2]() end end)
end

local function open_tree_picker(s, title, items)
    local cwd = s.origin.tree
    if #items == 0 then return notify("Nothing to review under " .. title, vim.log.levels.INFO) end
    Snacks.picker.pick({
        title = title,
        items = items,
        format = "text",
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            if item.kind == "here" then return M.set_home(cwd) end
            if item.kind == "tree" then return M.set_home(item.path) end
            if item.kind == "branch" then
                return fresh_tree(cwd, item.name, item.ref, function(p) M.set_home(p, item.name) end)
            end
            notify("Fetching PR #" .. item.pr .. " …")
            git_async(cwd, { "fetch", "--quiet", "origin", "pull/" .. item.pr .. "/head" }, function(out, err)
                if not out then return notify("fetch PR #" .. item.pr .. " failed: " .. err, vim.log.levels.ERROR) end
                local sha = first(cwd, { "rev-parse", "FETCH_HEAD" })
                fresh_tree(cwd, "pr-" .. item.pr, sha, function(p) M.set_home(p, "PR #" .. item.pr) end)
            end)
        end,
    })
end

-- Branch names already checked out in a worktree: reviewing one of those means picking its tree.
local function tree_items(cwd)
    local rroot = realpath(review_root(cwd))
    local here = ref_name(cwd)
    local items = { { text = string.format("%s  (your tree)", here), kind = "here" } }
    local busy = { [here] = true }
    for _, w in ipairs(worktrees(cwd)) do
        local rp = realpath(w.path)
        if rp ~= realpath(cwd) and not under(rp, rroot) then
            items[#items + 1] = {
                text = string.format("%s  %s", w.branch or "(detached)", vim.fn.fnamemodify(w.path, ":~")),
                kind = "tree", path = w.path,
            }
            if w.branch then busy[w.branch] = true end
        end
    end
    return items, busy
end

local function merged_refs(cwd, main)
    local merged = {}
    for _, b in ipairs(git(cwd, { "branch", "-a", "--merged", main, "--format=%(refname)" }) or {}) do
        merged[vim.trim(b)] = true
    end
    return merged
end

-- Unmerged, newest first, with commits ahead and last subject.
local function local_branch_items(cwd)
    local main = gitutil.main_base(cwd, true)
    if not main then return {} end
    local _, busy = tree_items(cwd)
    local merged = merged_refs(cwd, main)
    local items = {}
    for _, row in ipairs(git(cwd, { "for-each-ref", "--sort=-committerdate",
        "--format=%(refname:short)%09%(ahead-behind:" .. main .. ")%09%(committerdate:relative)%09%(contents:subject)",
        "refs/heads/" }) or {}) do
        local name, ahead, when, subj = row:match("^([^\t]+)\t(%d+) %d+\t([^\t]*)\t(.*)$")
        if name and not busy[name] and not merged["refs/heads/" .. name] then
            items[#items + 1] = {
                text = string.format("%s  +%s · %s · %s", name, ahead, when, subj),
                kind = "branch", name = name, ref = "refs/heads/" .. name,
            }
        end
    end
    return items
end

-- Unmerged remote branches with no local copy, capped.
local function remote_branch_items(cwd)
    local main = gitutil.main_base(cwd, true)
    if not main then return {} end
    local _, busy = tree_items(cwd)
    local merged = merged_refs(cwd, main)
    local locals = {}
    for _, b in ipairs(git(cwd, { "for-each-ref", "--format=%(refname:short)", "refs/heads/" }) or {}) do
        locals[vim.trim(b)] = true
    end
    local items = {}
    for _, row in ipairs(git(cwd, { "for-each-ref", "--sort=-committerdate",
        "--format=%(refname:lstrip=3)%09%(committerdate:relative)%09%(contents:subject)", "refs/remotes/origin/" }) or {}) do
        local name, when, subj = row:match("^([^\t]+)\t([^\t]*)\t(.*)$")
        if name and name ~= "HEAD" and not locals[name] and not busy[name]
            and not merged["refs/remotes/origin/" .. name] then
            items[#items + 1] = {
                text = string.format("%s  %s · %s", name, when, subj),
                kind = "branch", name = name, ref = "refs/remotes/origin/" .. name,
            }
            if #items >= 30 then break end
        end
    end
    return items
end

local function with_pr_items(cwd, cb)
    if vim.fn.executable("gh") == 0 then
        notify("gh is not installed, so open PRs can't be listed", vim.log.levels.WARN)
        return cb({})
    end
    notify("Loading PRs …")
    run({ "gh", "pr", "list", "--state", "open", "--limit", "100", "--json", "number,title,author,isDraft" },
        cwd, function(ok, out)
            local okj, prs = pcall(vim.json.decode, ok and out or "")
            local items = {}
            for _, p in ipairs(okj and type(prs) == "table" and prs or {}) do
                items[#items + 1] = {
                    text = string.format("#%d %s  (%s)%s", p.number, p.title,
                        (p.author and p.author.login) or "?", p.isDraft and " [draft]" or ""),
                    kind = "pr", pr = p.number,
                }
            end
            cb(items)
        end)
end

function M.tree_menu()
    local s = M.s
    if not s then return end
    local cwd = s.origin.tree
    local choices = {
        { "Worktrees — this tree and your other worktrees", function()
            open_tree_picker(s, "Review a worktree", (tree_items(cwd)))
        end },
        { "Local branches — unmerged, newest first", function()
            open_tree_picker(s, "Review a local branch", local_branch_items(cwd))
        end },
        { "Open PRs", function()
            with_pr_items(cwd, function(items) open_tree_picker(s, "Review an open PR", items) end)
        end },
        { "Remote-only branches", function()
            open_tree_picker(s, "Review a remote branch", remote_branch_items(cwd))
        end },
    }
    vim.ui.select(choices, {
        prompt = "Review what",
        format_item = function(c) return c[1] end,
    }, function(c) if c then c[2]() end end)
end

-- ── panel lifecycle ─────────────────────────────────────────────────────────
local function item_at_cursor(s)
    return s.map and s.map[vim.api.nvim_win_get_cursor(0)[1]]
end

function M.jump(dir)
    local s = M.s
    if not (s and s.files and #s.files > 0) then return notify("No review files (<leader>gn)", vim.log.levels.WARN) end
    local idx
    if vim.api.nvim_get_current_win() == panel_win(s) then
        local it = item_at_cursor(s)
        idx = it and it.file and it.file.idx
    else
        local cur = realpath(vim.api.nvim_buf_get_name(0))
        for _, f in ipairs(s.files) do
            if realpath(vim.fs.joinpath(s.tree, f.path)) == cur then idx = f.idx end
        end
    end
    local n = #s.files
    local f = s.files[idx and ((idx - 1 + dir) % n) + 1 or (dir > 0 and 1 or n)]
    open_file(s, f)
    focus_panel_on(s, f)
    vim.api.nvim_echo({ { string.format("[%d/%d] %s", f.idx, n, f.path) } }, false, {})
end

function M.hide()
    local w = M.s and panel_win(M.s)
    if w and not pcall(vim.api.nvim_win_close, w, false) then
        notify("Panel is the last window — Q ends the review", vim.log.levels.WARN)
    end
end

local function set_keys(s, b)
    local function k(lhs, fn, desc) vim.keymap.set("n", lhs, fn, { buffer = b, nowait = true, silent = true, desc = desc }) end
    local function on_item(fn)
        return function()
            local it = item_at_cursor(s)
            if it then fn(it) end
        end
    end
    local open = on_item(function(it)
        if it.file then open_file(s, it.file) elseif it.commit then M.review_commit(it.commit.sha) end
    end)
    k("<CR>", open, "Open")
    k("o", open, "Open")
    k("p", on_item(function(it) if it.file then preview(s, it.file) end end), "Diff preview")
    k("v", on_item(function(it)
        if not it.file then return end
        local key = viewed_key(s, it.file)
        s.viewed[key] = not s.viewed[key] or nil
        render(s)
        local nxt = s.files[it.file.idx + 1]
        if nxt then focus_panel_on(s, nxt) end
    end), "Toggle viewed")
    k("s", M.scope_menu, "Scope")
    k("w", M.tree_menu, "Tree / branch / PR")
    k("r", function() apply(s, s.tree, s.scope) end, "Refresh")
    k("q", M.hide, "Hide panel")
    k("Q", M.stop, "End review")
    k("?", function() s.help = not s.help; render(s) end, "Help")
end

local function show(s, focus)
    if not (s.buf and vim.api.nvim_buf_is_valid(s.buf)) then
        s.buf = vim.api.nvim_create_buf(false, true)
        vim.bo[s.buf].filetype = "gitreview"
        vim.bo[s.buf].modifiable = false
        pcall(vim.api.nvim_buf_set_name, s.buf, "gitreview://panel")
        set_keys(s, s.buf)
    end
    local w = panel_win(s)
    if not w then
        w = vim.api.nvim_open_win(s.buf, focus, { split = "left", win = -1, width = WIDTH })
        local wo = vim.wo[w]
        wo.number, wo.relativenumber, wo.signcolumn, wo.foldcolumn = false, false, "no", "0"
        wo.statuscolumn, wo.wrap, wo.cursorline, wo.winfixwidth = "", false, true, true
        wo.spell, wo.list = false, false
        s.win = w
    elseif focus then
        vim.api.nvim_set_current_win(w)
    end
    render(s)
end

function M.start()
    local file = vim.api.nvim_buf_get_name(0)
    local tree = toplevel(file)
    if not tree then return notify("Not in a git repo", vim.log.levels.WARN) end
    local win = vim.api.nvim_get_current_win()
    local ok, cur = pcall(vim.api.nvim_win_get_cursor, win)
    local s = {
        origin = { win = win, file = vim.fn.filereadable(file) == 1 and file or nil, cursor = ok and cur or nil, tree = tree },
        home = tree, viewed = {}, names = {},
        main_win = is_normal_win(win) and win or nil,
    }
    M.s = s
    local main = gitutil.main_base(tree, true)
    local mb = main and first(tree, { "merge-base", "HEAD", main })
    local on_main = not mb or mb == first(tree, { "rev-parse", "HEAD" })
    show(s, true)
    apply(s, tree, { kind = on_main and "local" or "branch" })
end

function M.toggle()
    local s = M.s
    if not s then return M.start() end
    if vim.api.nvim_get_current_win() == panel_win(s) then return M.hide() end
    show(s, true)
end

function M.stop()
    local s = M.s
    if not s then return end
    M.s = nil
    set_base(nil)
    local o = s.origin
    local target = (o.win and vim.api.nvim_win_is_valid(o.win) and o.win ~= s.win) and o.win or main_win(s)
    vim.api.nvim_set_current_win(target)
    if o.file and vim.fn.filereadable(o.file) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(o.file))
        if o.cursor then pcall(vim.api.nvim_win_set_cursor, 0, o.cursor) end
    end
    if panel_win(s) then pcall(vim.api.nvim_win_close, s.win, true) end
    if s.buf and vim.api.nvim_buf_is_valid(s.buf) then pcall(vim.api.nvim_buf_delete, s.buf, { force = true }) end
    lualine_refresh()
    notify("Review off")
    sweep(o.tree, {})
end

-- ── autocmds + keys ─────────────────────────────────────────────────────────
local timer
vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
    group = aug,
    callback = function()
        if not M.s then return end
        timer = timer or vim.uv.new_timer()
        timer:stop()
        timer:start(300, 0, vim.schedule_wrap(function() if M.s then refresh(M.s) end end))
    end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
        if M.s then sweep(M.s.origin.tree, {}, true) end
    end,
})

vim.api.nvim_create_autocmd("WinEnter", {
    group = aug,
    callback = function()
        local s, w = M.s, vim.api.nvim_get_current_win()
        if s and w ~= s.win and is_normal_win(w) then s.main_win = w end
    end,
})

local map = vim.keymap.set
map("n", "<leader>gn", M.toggle, { silent = true, desc = "Review panel (open / focus / hide)" })
map("n", "]r", function() M.jump(1) end, { silent = true, desc = "Next review file" })
map("n", "[r", function() M.jump(-1) end, { silent = true, desc = "Prev review file" })

return M
