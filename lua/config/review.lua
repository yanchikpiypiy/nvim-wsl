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

-- <parent>/<repo>.review/<slug>, next to the main checkout.
local function review_path(cwd, slug)
    local common = first(cwd, { "rev-parse", "--path-format=absolute", "--git-common-dir" })
    if not common then return nil end
    local main = vim.fs.dirname(common)
    return vim.fs.joinpath(vim.fs.dirname(main), vim.fs.basename(main) .. ".review",
        (slug:gsub("[^%w%._-]", "-")))
end

local function is_worktree(cwd, path)
    local want = realpath(path)
    for _, w in ipairs(worktrees(cwd)) do
        if realpath(w.path) == want then return true end
    end
    return false
end

local function add_worktree(cwd, path, args, cb)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    git(cwd, { "worktree", "prune" })
    notify("Creating worktree " .. vim.fn.fnamemodify(path, ":~") .. " …")
    git_async(cwd, vim.list_extend({ "worktree", "add" }, args), function(out, err)
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
--         label, files, commits, viewed, created, buf, win, main_win, help, map, gen }
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
    return rev
end

local function make_label(tree, scope, main)
    local k = scope.kind
    if k == "commit" then
        return "commit " .. scope.ref:sub(1, 7) .. "  " .. (first(tree, { "log", "-1", "--format=%s", scope.ref }) or "")
    end
    local b = ref_name(tree)
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
    s.label = make_label(tree, scope, main)
    s.files, s.commits = nil, nil
    s.gen = (s.gen or 0) + 1
    render(s)
    lualine_refresh()
    set_base(base, function() refresh(s) end)
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

local function open_file(s, f)
    if f.status == "D" then return preview(s, f) end
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

function M.set_home(path)
    local s = M.s
    if not s then return end
    s.home = path
    apply(s, path, { kind = "branch" })
    vim.cmd("checktime")
end

-- One commit, isolated: a detached worktree slot (reused) checked out at it.
function M.review_commit(sha)
    local s = M.s
    if not s then return end
    local full = first(s.home, { "rev-parse", sha })
    local slot = review_path(s.home, "_commit")
    if not (full and slot) then return notify("Can't resolve " .. sha, vim.log.levels.WARN) end
    local function go()
        s.created[slot] = true
        apply(s, slot, { kind = "commit", ref = full })
        vim.cmd("checktime")
    end
    if is_worktree(s.home, slot) then
        git_async(slot, { "checkout", "--detach", full }, function(out, err)
            if not out then return notify("Commit worktree is dirty? " .. err, vim.log.levels.ERROR) end
            go()
        end)
    else
        add_worktree(s.home, slot, { "--detach", slot, full }, go)
    end
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
        { "Against any branch / ref", function()
            Snacks.picker.git_branches({
                all = true,
                cwd = s.home,
                title = "Review against…",
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

local function open_tree_picker(s, items, by_branch)
    local cwd = s.origin.tree
    Snacks.picker.pick({
        title = "Review which tree / branch / PR",
        items = items,
        format = "text",
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            if item.kind == "tree" then return M.set_home(item.path) end
            if item.kind == "branch" then
                local path = review_path(cwd, item.branch)
                return add_worktree(cwd, path, { path, item.branch }, function(p)
                    s.created[p] = true
                    M.set_home(p)
                end)
            end
            -- PR: reuse the worktree that already has its branch, else a fresh one
            local wt = item.head and by_branch[item.head]
            if wt then
                notify("PR #" .. item.pr .. " is already in " .. vim.fn.fnamemodify(wt.path, ":~") .. " — pull there to update")
                return M.set_home(wt.path)
            end
            local path = review_path(cwd, "pr-" .. item.pr)
            local function checkout(p)
                s.created[p] = true
                notify("gh pr checkout " .. item.pr .. " …")
                run({ "gh", "pr", "checkout", tostring(item.pr) }, p, function(ok, _, err)
                    if not ok then return notify("gh pr checkout failed: " .. err, vim.log.levels.ERROR) end
                    M.set_home(p)
                end)
            end
            if is_worktree(cwd, path) then checkout(path) else add_worktree(cwd, path, { "--detach", path }, checkout) end
        end,
    })
end

function M.tree_menu()
    local s = M.s
    if not s then return end
    local cwd = s.origin.tree
    local items, by_branch = {}, {}
    local wts = worktrees(cwd)
    for _, w in ipairs(wts) do
        if w.branch then by_branch[w.branch] = w end
    end
    for _, w in ipairs(wts) do
        if vim.fs.basename(w.path) ~= "_commit" then
            local tag = realpath(w.path) == realpath(cwd) and "this tree" or "worktree"
            local cur = realpath(w.path) == realpath(s.home) and " ●" or ""
            items[#items + 1] = {
                text = string.format("%-9s  %s  %s%s", tag, w.branch or "(detached)", vim.fn.fnamemodify(w.path, ":~"), cur),
                kind = "tree", path = w.path,
            }
        end
    end
    local main = gitutil.main_base(cwd, true)
    if main then
        local merged = {}
        for _, b in ipairs(git(cwd, { "branch", "--merged", main, "--format=%(refname:short)" }) or {}) do
            merged[vim.trim(b)] = true
        end
        local n = 0
        for _, row in ipairs(git(cwd, { "for-each-ref", "--sort=-committerdate",
            "--format=%(refname:short)%09%(committerdate:relative)", "refs/heads/" }) or {}) do
            local b, when = row:match("^([^\t]+)\t(.*)$")
            if b and not merged[b] and not by_branch[b] then
                items[#items + 1] = { text = string.format("%-9s  %s  (%s)", "branch", b, when), kind = "branch", branch = b }
                n = n + 1
                if n >= 20 then break end
            end
        end
    end
    if vim.fn.executable("gh") == 0 then return open_tree_picker(s, items, by_branch) end
    notify("Loading PRs …")
    run({ "gh", "pr", "list", "--state", "open", "--limit", "100", "--json", "number,title,headRefName,author,isDraft" },
        cwd, function(ok, out)
            local okj, prs = pcall(vim.json.decode, ok and out or "")
            for _, p in ipairs(okj and type(prs) == "table" and prs or {}) do
                local where = by_branch[p.headRefName] and "  [worktree]" or ""
                items[#items + 1] = {
                    text = string.format("%-9s  #%d %s  (%s)%s%s", "PR", p.number, p.title,
                        (p.author and p.author.login) or "?", p.isDraft and " [draft]" or "", where),
                    kind = "pr", pr = p.number, head = p.headRefName,
                }
            end
            open_tree_picker(s, items, by_branch)
        end)
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
        home = tree, viewed = {}, created = {},
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

local function cleanup_worktrees(s)
    local paths = vim.tbl_filter(function(p) return vim.fn.isdirectory(p) == 1 end, vim.tbl_keys(s.created))
    if #paths == 0 then return end
    vim.ui.select({ "Keep", "Remove" }, {
        prompt = "Remove " .. #paths .. " review worktree(s)? (refused if they have uncommitted work)",
    }, function(choice)
        if choice ~= "Remove" then return end
        for _, p in ipairs(paths) do
            local root = realpath(p) .. "/"
            local busy = false
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
                local name = realpath(vim.api.nvim_buf_get_name(b))
                if name and name:sub(1, #root) == root then
                    if vim.bo[b].modified then busy = true else pcall(vim.api.nvim_buf_delete, b, { force = true }) end
                end
            end
            for _, c in ipairs(vim.lsp.get_clients()) do
                local r = c.root_dir and realpath(c.root_dir)
                if r and (r .. "/"):sub(1, #root) == root then c:stop() end
            end
            if busy then
                notify("Kept " .. vim.fn.fnamemodify(p, ":~") .. " — it has unsaved buffers", vim.log.levels.WARN)
            else
                git_async(s.origin.tree, { "worktree", "remove", p }, function(out, err)
                    if out then notify("Removed " .. vim.fn.fnamemodify(p, ":~"))
                    else notify("Kept " .. vim.fn.fnamemodify(p, ":~") .. ": " .. err, vim.log.levels.WARN) end
                end)
            end
        end
    end)
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
    cleanup_worktrees(s)
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
