return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        -- Resolve the base to diff a PR/feature branch against. Returns the
        -- MERGE-BASE of HEAD and the first existing main/master ref, so gitsigns
        -- shows only what THIS branch added — not commits main gained after you
        -- branched off. Second return value is the human-readable ref name.
        local function pr_base(bufnr)
            bufnr = bufnr or vim.api.nvim_get_current_buf()
            local file = vim.api.nvim_buf_get_name(bufnr)
            local dir  = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
            local function git(...)
                local out = vim.fn.systemlist({ "git", "-C", dir, ... })
                if vim.v.shell_error ~= 0 then return nil end
                return out
            end
            local base
            for _, ref in ipairs({ "origin/main", "origin/master", "main", "master" }) do
                if git("rev-parse", "--verify", "--quiet", ref) then base = ref; break end
            end
            if not base then return nil end
            local mb = git("merge-base", "HEAD", base)
            return (mb and mb[1]) or base, base
        end

        local gs = require("gitsigns")
        gs.setup({
            -- Windows line-ending fix. Buffers here load as `fileformat=dos`
            -- (CRLF), but the git blob gitsigns diffs against is LF — so WITHOUT
            -- this, every line mismatches on the trailing CR and gitsigns
            -- collapses the whole file into ONE giant "change" hunk. iwhiteeol
            -- ignores the CR at end-of-line so hunks match `git diff` exactly.
            diff_opts = {
                internal = true,
                ignore_whitespace_change_at_eol = true,
                linematch = 60,
            },
            -- Show signs on untracked/new files too (whole file as added).
            attach_to_untracked = true,
            signs = {
                add          = { text = "▎" },
                change       = { text = "▎" },
                delete       = { text = "" },
                topdelete    = { text = "" },
                changedelete = { text = "▎" },
                untracked    = { text = "▎" },
            },
            current_line_blame = false, -- toggle with <leader>gB
            on_attach = function(bufnr)
                local map = vim.keymap.set
                local o   = { buffer = bufnr, silent = true }

                -- Buffer-local hunk ACTIONS (need an attached git buffer). Wrapped
                -- in notify() since gitsigns is otherwise silent.
                map("n", "<leader>gs",  function() gs.stage_hunk();  vim.notify("Hunk stage toggled", vim.log.levels.INFO) end, vim.tbl_extend("force", o, { desc = "Stage hunk" }))
                map("n", "<leader>gS",  function() gs.stage_buffer(); vim.notify("Buffer staged", vim.log.levels.INFO) end,     vim.tbl_extend("force", o, { desc = "Stage buffer" }))
                map("n", "<leader>gR",  function() gs.reset_hunk();   vim.notify("Hunk reset", vim.log.levels.WARN) end,         vim.tbl_extend("force", o, { desc = "Reset hunk" }))
                map("n", "<leader>gb",  function() gs.blame_line({ full = true }) end, vim.tbl_extend("force", o, { desc = "Blame line" }))
                map("n", "<leader>gB",  gs.toggle_current_line_blame,               vim.tbl_extend("force", o, { desc = "Toggle blame" }))

                -- Diff this file against the base in a split, then press `q`
                -- (from the file window) to close it: turns diff off and closes
                -- the base scratch split, back to a single pane. The temporary
                -- `q` mapping removes itself when diff turns off.
                map("n", "<leader>gd", function()
                    local fbuf = vim.api.nvim_get_current_buf()
                    gs.diffthis()
                    vim.keymap.set("n", "q", function()
                        vim.cmd("diffoff!")
                        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                            local b = vim.api.nvim_win_get_buf(win)
                            if vim.api.nvim_buf_get_name(b):match("^gitsigns://") then
                                pcall(vim.api.nvim_win_close, win, true)
                            end
                        end
                    end, { buffer = fbuf, nowait = true, silent = true, desc = "Close diff" })
                    vim.api.nvim_create_autocmd("OptionSet", {
                        pattern = "diff",
                        callback = function()
                            if not vim.wo.diff then
                                pcall(vim.keymap.del, "n", "q", { buffer = fbuf })
                                return true
                            end
                        end,
                    })
                end, vim.tbl_extend("force", o, { desc = "Diff this (q to close)" }))

                -- Hunk text object (works with d/y/c + ih)
                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", vim.tbl_extend("force", o, { desc = "Select hunk" }))
            end,
        })

        -- GLOBAL keymaps — defined once, NOT inside on_attach, so they ALWAYS
        -- exist even on buffers gitsigns couldn't attach to (e.g. a file that's
        -- new in the branch and absent at the diff base). On attached buffers
        -- they work; elsewhere they no-op instead of silently not existing.
        local map = vim.keymap.set

        -- The canonical empty tree object — exists in every git repo.
        local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

        -- New-in-branch and RENAMED files don't exist (under their current path)
        -- at a rev base, so gitsigns can't resolve them in that revision's tree
        -- and silently FAILS TO ATTACH — zero signs, looking "broken" while the
        -- modified files next to them work. (Renames fail too: gitsigns' rename
        -- fallback in ls_tree looks the file up by ABSOLUTE path in a map keyed
        -- by repo-RELATIVE path, so it never matches.)
        --
        -- The old empty-tree pin no longer works: change_base(EMPTY_TREE, false)
        -- needs a cache entry that doesn't exist yet, and attaching against the
        -- empty tree fails the same way (the file isn't in the empty tree either).
        --
        -- Working fix: attach the buffer against HEAD (where the committed file
        -- DOES exist, so gitsigns builds a cache entry), then blank that entry's
        -- compare_text so the WHOLE buffer diffs as "added" — the same rendering
        -- gitsigns uses for untracked files. On reset, change_base(nil, true)
        -- re-resolves compare_text and the buffer returns to normal.
        --
        -- No-op when there's no rev base, or when the file exists at the base
        -- (gitsigns handles those normally), or when already rescued.
        local function fixup_added(buf)
            buf = buf or vim.api.nvim_get_current_buf()
            local base = require("gitsigns.config").config.base
            if not base then return end
            base = vim.trim(tostring(base))
            if base == "" or base == EMPTY_TREE then return end
            local name = vim.api.nvim_buf_get_name(buf)
            if name == "" or vim.fn.filereadable(name) == 0 then return end
            local dir = vim.fn.fnamemodify(name, ":h")
            -- Repo-relative path (forward slashes, matches git's tree lookup).
            local rel = vim.fn.systemlist({ "git", "-C", dir, "ls-files", "--full-name", "--", name })
            if vim.v.shell_error ~= 0 or not rel[1] or rel[1] == "" then return end
            -- Does the file exist at the base commit? cat-file -e is silent+cheap.
            -- (For a rename, rel is the NEW path, which is absent at the base — so
            -- renames fall through to the rescue and render as a whole-file add.)
            vim.fn.system({ "git", "-C", dir, "cat-file", "-e", base .. ":" .. rel[1] })
            if vim.v.shell_error == 0 then return end -- present at base → normal diff is fine

            local cache = require("gitsigns.cache")
            -- Idempotent: skip if this buffer is already rescued against this base
            -- (else every BufWinEnter would re-detach/attach and flicker).
            local existing = cache.cache[buf]
            if vim.b[buf].gs_rescued_base == base
                and existing and existing.compare_text and #existing.compare_text == 0 then
                return
            end

            local manager = require("gitsigns.manager")
            local top = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
            local gitdir = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--absolute-git-dir" })[1]
            local ctx = { file = name, toplevel = top, gitdir = gitdir, base = "HEAD" }
            pcall(gs.detach, buf)
            -- Attach against HEAD so a cache entry gets built for a file the rev
            -- base can't see. gitsigns' own auto-attach (against the rev base,
            -- which fails for this file) may already be in-flight for this buffer;
            -- gs.attach is throttled per-buffer, so a single call can be DROPPED.
            -- Retry until our HEAD attach actually lands a cache entry (bounded).
            local c
            for _ = 1, 20 do
                if not cache.cache[buf] then gs.attach({ bufnr = buf, ctx = ctx }) end
                vim.wait(200, function() return cache.cache[buf] ~= nil end)
                c = cache.cache[buf]
                if c then break end
            end
            if not c then return end
            -- Wait for the first update to populate compare_text (force one if the
            -- update deferred), so blanking it below can't be overwritten.
            if not vim.wait(1500, function() return c.compare_text ~= nil end) then
                pcall(manager.update, buf)
                vim.wait(1500, function() return c.compare_text ~= nil end)
            end
            c.compare_text = {}      -- empty base → whole buffer is "added"
            c.compare_text_head = {}
            pcall(manager.update, buf) -- recompute hunks from the now-empty base
            vim.b[buf].gs_rescued_base = base
        end

        -- Sweep every listed buffer through fixup_added (used after a base switch).
        local function fixup_all()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) then pcall(fixup_added, buf) end
            end
        end

        -- Bridge so the review module (config/review.lua), which sets the base on
        -- its own code path, can rescue absent-at-base files the same way <leader>gm
        -- does. Buffers opened afterwards are still caught by the autocmd below.
        _G.__gitsigns_fixup_all = fixup_all

        -- Switch the diff base and FORCE every already-attached buffer to
        -- re-diff against it. change_base alone only re-diffs a buffer at attach
        -- time — files you opened BEFORE switching base keep comparing against
        -- the OLD base, so they show stale or ZERO hunks while freshly-opened
        -- files look correct. refresh() re-diffs them all. (This was the "some
        -- files have hunks against the other branch, some don't" bug.)
        local function apply_base(rev, msg, level)
            gs.change_base(rev, true, function()
                -- Reset (rev=nil, base=index): drop any buffer-local empty-tree
                -- overrides we pinned, so those files follow the global base again
                -- instead of staying stuck showing their whole content as added.
                if rev == nil then
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_loaded(buf) then
                            pcall(vim.api.nvim_buf_call, buf, function() gs.change_base(nil, false) end)
                        end
                    end
                end
                gs.refresh()
                fixup_all() -- rescue new-in-branch files that can't diff vs a rev base
                if msg then vim.notify(msg, level or vim.log.levels.INFO) end
            end)
        end

        -- Files opened AFTER a rev base is set (e.g. picked from <leader>grl)
        -- attach one at a time — rescue each as it lands.
        vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter" }, {
            group = vim.api.nvim_create_augroup("GitsignsAddedFixup", { clear = true }),
            callback = function(args)
                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(args.buf) then pcall(fixup_added, args.buf) end
                end)
            end,
        })

        -- Navigate hunks (falls through to vim's native ]c/[c in diff mode).
        map("n", "]c", function()
            if vim.wo.diff then return "]c" end
            vim.schedule(function() pcall(gs.next_hunk) end)
            return "<Ignore>"
        end, { expr = true, silent = true, desc = "Next hunk" })
        map("n", "[c", function()
            if vim.wo.diff then return "[c" end
            vim.schedule(function() pcall(gs.prev_hunk) end)
            return "<Ignore>"
        end, { expr = true, silent = true, desc = "Prev hunk" })

        -- Preview a hunk (float / inline).
        map("n", "<leader>gp", function() pcall(gs.preview_hunk) end,        { silent = true, desc = "Preview hunk (float)" })
        map("n", "<leader>gP", function() pcall(gs.preview_hunk_inline) end, { silent = true, desc = "Preview hunk (inline)" })

        -- Manual refresh: re-apply the CURRENT base to recompute this buffer's
        -- hunks. gitsigns reliably re-diffs already-attached buffers on
        -- change_base, so this is the "kick it" key when signs look stale. Also
        -- re-runs the added-file rescue, so a new-in-branch file that showed no
        -- signs against a rev base gets pinned to the empty tree and lights up.
        map("n", "<leader>ga", function()
            gs.refresh() -- re-diff ALL attached buffers against the current base
            fixup_all()  -- rescue new-in-branch files (absent at a rev base)
            local base = require("gitsigns.config").config.base
            vim.notify("Gitsigns refreshed (base: " .. tostring(base or "index") .. ")", vim.log.levels.INFO)
        end, { silent = true, desc = "Gitsigns refresh (re-diff all buffers)" })

        -- Diff BASE control (global = applies to every buffer, current + future):
        --   <leader>gm  base = merge-base with origin/main  (PR review)
        --   <leader>go  base = pick ANY branch/commit (manual target)
        --   <leader>gM  base = index                        (back to normal)
        map("n", "<leader>gm", function()
            local rev, ref = pr_base(0)
            if not rev then
                vim.notify("No main/master branch found to diff against", vim.log.levels.WARN)
                return
            end
            apply_base(rev, "Gitsigns base → " .. ref .. " (merge-base). Jump hunks with ]c / [c")
        end, { silent = true, desc = "Diff base = main (PR review)" })

        map("n", "<leader>go", function()
            local function set(ref)
                if not ref or vim.trim(ref) == "" then return end
                ref = vim.trim(ref)
                apply_base(ref, "Gitsigns base → " .. ref)
            end
            if _G.Snacks and _G.Snacks.picker then
                Snacks.picker.git_branches({
                    all = true, -- include remote branches (origin/*), not just local
                    title = "Gitsigns base — pick a branch/commit",
                    confirm = function(picker, item)
                        picker:close()
                        -- item.branch for local/remote branches, item.commit when
                        -- the row is a detached/HEAD entry with no branch name.
                        if item then set(item.branch or item.commit) end
                    end,
                })
            else
                vim.ui.input({ prompt = "Gitsigns diff base (branch/commit): " }, set)
            end
        end, { silent = true, desc = "Diff base = pick branch/commit" })

        map("n", "<leader>gM", function()
            apply_base(nil, "Gitsigns base → index (default)")
        end, { silent = true, desc = "Diff base = index (reset)" })
    end,
}
