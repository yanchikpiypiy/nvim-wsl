# nvim-wsl

A Neovim config tuned for polyglot work — **.NET (C#) + React/TypeScript** — with
`roslyn.nvim` for C# intelligence, `ts_ls` for TS, `blink.cmp` completion,
`snacks.nvim` pickers, `neo-tree` explorer, and a full test/debug workflow.

- **Leader key:** `Space`
- **Plugin manager:** lazy.nvim (plugins in `lua/plugins/*.lua`)
- **Prerequisites:** see [`PREREQUISITES.md`](./PREREQUISITES.md)

C# tests use easy-dotnet's runner (`<leader>nt*`); frontend tests run via
`vitest --ui`/terminal (slow pnpm suite — no in-editor plugin). Debugging is
nvim-dap + dap-ui.

---

## Keymaps

> `<leader>` = `Space`. Press `<leader>` and pause to get the which-key popup.

### General
| Key | Action |
|-----|--------|
| `<Esc>` | Clear search highlight |
| `[b` / `]b` | Previous / next buffer |
| `<C-Left/Right/Up/Down>` | Resize the current window |
| `<leader>y` / `<leader>Y` | Yank selection / line to system clipboard |
| `<leader>p` | Paste from system clipboard |
| `<leader>vs` | Reload the current config file |
| `<leader>ut` | Theme picker — hover previews live, `<CR>` keeps it, `<Esc>` reverts (`:Theme <id>` too) |
| `<leader>up` | Palette tuner — pick a symbol kind, hover swatches (live). `<CR>` saves + steps back, `<Esc>` back one level, `q` quits (`:Palette`) |
| `<leader>f` | Format buffer (conform) — note: also the file-picker prefix |

### Motion / editing
| Key | Action |
|-----|--------|
| `s` / `S` | Flash jump / Flash treesitter |
| `af` `if` / `ac` `ic` / `aa` `ia` | Select function / class / parameter (outer/inner) |
| `]f` `[f` | Next / previous function |
| `]]` `[[` | Next / previous class |
| `<leader>a` | Harpoon: add file |
| `<leader>h` | Harpoon: menu |
| `<leader>1`..`<leader>4` | Harpoon: jump to file 1–4 |

### LSP (in a code buffer)
| Key | Action |
|-----|--------|
| `K` | Hover docs |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gi` | Go to implementation |
| `gy` | Go to type definition |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>ls` / `<leader>lw` | Document / workspace symbols |
| `<leader>li` | LSP info |
| `<leader>lh` | Toggle inlay hints |

### Diagnostics & Trouble (`<leader>x`)
| Key | Action |
|-----|--------|
| `<leader>d` | Show diagnostics (float) |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>xx` | Trouble: diagnostics |
| `<leader>xd` | Trouble: buffer diagnostics |
| `<leader>xs` | Trouble: symbols |
| `<leader>xr` | Trouble: LSP references |
| `<leader>xq` | Trouble: quickfix |
| `<leader>xt` | Trouble: todos |
| `]t` / `[t` | Next / previous todo comment |

### Find / search (`<leader>f`) — snacks.picker
| Key | Action |
|-----|--------|
| `<leader>ff` | Smart find (recent + files, current repo) |
| `<leader>fs` | Find files (current repo) |
| `<leader>fg` | Live grep (current repo) |
| `<leader>fe` | Find files — **frontend** (`app/`) |
| `<leader>fa` | Find files — **backend/api** (`api/`) |
| `<leader>fE` | Live grep — **frontend** |
| `<leader>fA` | Live grep — **backend/api** |
| `<leader>fS` / `<leader>fG` | Find files / grep — everything (cwd) |
| `<leader>fb` | Buffers |
| `<leader>fr` / `<leader>fR` | Recent files / resume last picker |
| `<leader>fc` | Find a config file |
| `<leader>ft` | Find todos (quickfix) |

### Explorer (neo-tree)
| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file explorer |
| `<leader>be` | Buffer explorer |
| `<leader>ge` | Git status (float) |
| in tree: `l` `h` `H` `P` | open / close node / toggle hidden / preview |

### Git (`<leader>g`)
| Key | Action |
|-----|--------|
| `<leader>gg` | Open LazyGit |
| `<leader>gf` | Git files (tracked) |
| `<leader>gt` | Git status (changed files) |
| `<leader>gc` / `<leader>gC` | Git log / log for current file |
| `<leader>gl` / `<leader>gz` | Branches / stash |
| `<leader>gs` / `<leader>gS` | Stage hunk / buffer |
| `<leader>gR` | Reset hunk |
| `<leader>gp` / `<leader>gP` | Preview hunk (float / inline) |
| `<leader>gb` / `<leader>gB` | Blame line / toggle line blame |
| `<leader>gd` | Diff this (gitsigns) |
| `<leader>gv` | Hunk list: uncommitted changes, delta preview; `<Tab>` stages the hunk |
| `<leader>gV` | Hunk list: this branch vs `main` (merge-base), delta preview |
| `<leader>gh` / `<leader>gH` | File history (current / all) — diffview |
| `]c` / `[c` | Next / previous hunk |
| `ih` | Select hunk (text object) |
| `:DiffviewOpen [main...HEAD]` | Side-by-side buffer diff (no key; `q` closes) |

#### Review mode (`lua/config/review.lua`)
A left sidebar listing what a scope changed; opening a file sets the gitsigns diff base
to match, so `]c`/`[c` walk exactly that scope's hunks.

| Key | Action |
|-----|--------|
| `<leader>gn` | Start a review / focus the panel / hide it (when already in it) |
| `]r` / `[r` | Next / previous review file, from anywhere (echoes `[3/7] path`) |
| `<leader>ga` | Gitsigns refresh (re-diff all buffers against the current base) |
| in panel: `<CR>` / `o` | Open file in the main window · on a commit line: review that commit |
| in panel: `p` | Full-file diff in a float, through delta (`q`/`<Esc>` closes) |
| in panel: `v` | Toggle viewed ✓ and move to the next file |
| in panel: `s` | Scope: branch vs main · uncommitted only · one commit · since a commit · any ref |
| in panel: `w` | Review another branch / PR: local + remote-only branches, open PRs (gh), your other worktrees |
| in panel: `r` / `q` / `Q` / `?` | Refresh (re-resolve base) · hide · end review · key help |

How it behaves:
- **Local changes are always in.** Every scope diffs the *working tree* against its base, so
  uncommitted edits and untracked files are listed (`●` = not committed yet, `?` = untracked).
  Starting on `main` with nothing ahead defaults to "uncommitted only".
- **Other branches / PRs never block anything.** `w` builds a throwaway copy under
  `../<repo>.review/` (a detached worktree at the branch's commit; PRs are fetched as
  `pull/<n>/head`), so no branch is locked and no branch is created. Local branches,
  remote-only branches (`origin/*`) and open PRs are all listed. Files open from that copy,
  so LSPs start a second root there.
- **One commit is isolated** in the same way (`../<repo>.review/_commit`, base = its parent).
- **Copies are always cleaned up**: switching to another review, `Q`, and quitting nvim
  force-remove them (their buffers and LSP clients are closed first), and starting a review
  sweeps any left by a crash. Edits made inside a review copy are thrown away. Branches are
  never deleted. `Q` also resets the gitsigns base and returns you to where you started.
- "main" is the first of `origin/main`, `origin/master`, `main`, `master` (`gitutil.lua`),
  and the diff base is the merge-base with it — the same thing a PR shows. Fetch first if
  `origin/main` is stale. `<leader>gV` uses the same ref.
- The panel refreshes on save and on focus (e.g. after committing in lazygit); `r` also
  re-resolves the base (after a rebase).
- Viewed marks last for the nvim session only.

**delta** renders every text diff: `git diff`/`log`/`show` in the shell, lazygit's diff pane,
the snacks git pickers (`gt`/`gc`/`gC`/`gz`/`gv`/`gV`) and the review panel's `p` preview
(`previewers.diff.style = "terminal"` in `snacks.lua`). In-buffer views (gitsigns hunks,
diffview) use Neovim's own diff highlighting instead.

### Build — C/C++ via CMake (`<leader>m`, `lua/config/cppbuild.lua`)
| Key | Action |
|-----|--------|
| `<leader>mb` | Build (async; saves all buffers first). Errors → quickfix; Trouble opens on failure |
| `<leader>mq` | Toggle the build error list (Trouble quickfix) |
| `]q` / `[q` | Next / previous build error (wraps) |
| `<leader>md` | Pick build dir when a project has several (remembered per project for the session) |
| `:make` | Same build, classic command (makeprg is set per C/C++ buffer) |

Project root = topmost dir with `CMakeLists.txt` above the file. Candidate build dirs are
`build*` folders containing `CMakeCache.txt` (i.e. already configured); default is `build`,
else the first alphabetically. Output is parsed with the default `errorformat` (gcc/clang/ld),
so cmake/ninja progress lines are dropped. `<leader>xx` is clangd's live analysis of open
files; `<leader>mb` is the real compiler + linker.

### .NET — easy-dotnet (`<leader>n`)
| Key | Action |
|-----|--------|
| `<leader>nr` | Run project |
| `<leader>nb` | Build |
| `<leader>ns` | User-secrets |
| `<leader>np` | Add NuGet package |
| `<leader>nf` | New file (class/interface/…) in the folder under cursor |

#### C# tests (`<leader>nt`, easy-dotnet runner)
| Key | Action |
|-----|--------|
| `<leader>ntt` | Open the test runner window |
| `<leader>ntr` | Run test under cursor (in a test file) |
| `<leader>ntd` | Debug test under cursor (in a test file) |
| `<leader>nta` | Run all tests in file |
| `<leader>ntp` | Peek test output |
| runner window | `r` run · `R` run all · `d` debug · `<CR>`/`gd` open source · `p` peek · `o`/`E`/`W` expand/collapse · `]f`/`[f` failures · `<C-r>` refresh · `<C-c>` cancel · `q` close |

### Debugging — nvim-dap (`<leader>nd` + F-keys)
| Key | Action |
|-----|--------|
| `<F9>` | Toggle breakpoint |
| `<F5>` | Continue / start |
| `<F10>` / `<F11>` / `<F8>` | Step over / into / out |
| `<leader>ndd` | Debug project (start) |
| `<leader>ndc` | Continue |
| `<leader>ndb` / `<leader>ndB` | Toggle / conditional breakpoint |
| `<leader>ndo` / `<leader>ndi` / `<leader>ndu` | Step over / into / out |
| `<leader>ndr` | Run to cursor |
| `<leader>ndq` | Terminate session |
| `<leader>ndv` | Toggle debug UI panels |
| `<leader>nde` | Evaluate expression (also visual) |
| `<leader>ndz` | Zoom the variables panel (float) |
| `<leader>ndm` | Maximize / restore the focused panel |

### Frontend tests (Vitest)
Run from a terminal (the suite is slow + pnpm, so no in-editor plugin):
- `npx vitest --ui` — the Vitest browser dashboard (watch + filter)
- `npx vitest` — terminal watch mode

### package.json — package-info (`<leader>j`)
| Key | Action |
|-----|--------|
| `<leader>ju` | Update package under cursor |
| `<leader>jd` | Delete package under cursor |
| `<leader>ji` | Install a new package |
| `<leader>jc` | Change version |
| `<leader>jt` | Toggle version display |

### Terminal & completion
| Key | Action |
|-----|--------|
| `<C-\>` | Toggle floating terminal |
| insert: `<C-x>` `<C-e>` `<CR>` `<Tab>` `<S-Tab>` | completion: show · cancel · accept · next/snippet · prev |
| `<leader>uc` | Toggle Copilot completions — flips `vim.g.copilot_blink`, which gates the `copilot` blink source in `lua/plugins/completion.lua`. Copilot has no inline ghost-text here (`suggestion = { enabled = false }` in `lua/plugins/copilot.lua`), so its suggestions only ever arrive inside the blink menu; turning the source off removes them completely while the LSP client stays attached, so flipping it back needs no reload. State is global and resets on restart. |

---

## Themes
- `<leader>ut` / `:Theme` opens the picker. Entries are tagged **plugin** (gruvbox,
  everforest) or **custom** (hand-rolled). Hovering previews live; `<CR>` saves the
  choice to `~/.local/state/nvim/theme`, `<Esc>` reverts.
- Plugin themes are listed in `lua/config/theme.lua` (`M.plugins`).
- Custom themes live one-per-file in `lua/themes/`. A file returns
  `{ name, desc, base?, setup?, background?, highlights = function() return { Group = spec } end }`.
  `base` names a plugin colorscheme to paint over (Monochrome uses `monochrome.nvim`,
  both Gruvbox themes use `gruvbox`); `setup` runs before it loads, for plugin options;
  leave `base` out to start from Neovim's defaults. Drop a file in and it shows up in
  the picker. `:ThemeReload` re-reads the current custom file after you edit it.

| Custom theme | Look |
|---|---|
| **Monochrome** | greyscale + accents; the only theme driven by `palette.lua` |
| **Gruvbox Distinct** | gruvbox hard background, Monochrome's warm accents — orange keywords, red methods, rose members |
| **Gruvbox Classic** | gruvbox hard background and gruvbox's own hues, plus orange comments; keywords split three ways |

Shared gruvbox UI furniture — fg-only git status colours, subtle diff tints, the
diffview / snacks / neo-tree groups — lives in `lua/config/gruvbox_chrome.lua` rather
than being duplicated per theme. `build{ white, dim, add, change, delete }` returns the
table to merge underneath your syntax groups:

```lua
local chrome = require("config.gruvbox_chrome").build({ white = c.variable, change = c.type })
return vim.tbl_extend("force", chrome, syntax)
```

It sits in `config/` and not `themes/` because `theme.lua` treats every file in
`lua/themes/` as a selectable theme.

### Writing a theme: the Roslyn priority rule
`lua/config/options.lua` sets `vim.hl.priorities.semantic_tokens = 125` against
treesitter's 100, so in C# the LSP wins every contest. Two consequences, both of which
have already cost a debugging session:

- **Never colour `@lsp.type.variable` / `@lsp.type.local`.** Roslyn tags everything it
  has not resolved *yet* as `variable`. Colouring that paints most of a C# buffer flat
  and hides treesitter's correct method and type colours — leave them `{}` so
  treesitter shows through.
- **Leave `@lsp.type.keyword` / `@lsp.type.controlKeyword` empty if you want granular
  keywords.** Roslyn collapses `public`, `class`, `return` and `is` into one token type,
  which in C# measured a quarter of all coloured glyphs. Treesitter's
  `@keyword.modifier` / `@keyword.type` / `@keyword.return` captures only surface once
  the LSP group stops overriding them. The trade: keyword colour then depends on
  treesitter, so it drops out in buffers over 256KB where highlighting is disabled.

`:Inspect` on a symbol lists every group applying there in priority order — use it
before hunting for the right key.

### Palette tuner
Monochrome's colours come from `lua/config/palette.lua`: one table keyed by symbol kind,
fanned out to **both** engines — the `method` key alone reaches `@function.method`,
`@function.method.call`, `@lsp.type.method.cs`, `@lsp.type.extensionMethod.cs` and
`@lsp.type.operatorOverloaded.cs`, so one swatch recolours C++ and C# together.

`<leader>up` / `:Palette` tunes one key at a time. Hover a swatch to see it live in the
editor, then:

| Key | Action |
|-----|--------|
| `<CR>` | save to `palette.lua`, then step back to the kind list |
| `<Esc>` | back one level — from the kind list, close |
| `q` | quit outright, reverting the colour being previewed |

Typing a colour in the filter box works too — `#rrggbb`, `#rgb`, or a bare `rrggbb`. A
highlighted swatch wins, so a typed hex only applies when nothing matched (`q` is an
ordinary letter while the box has text, so `aqua` is still searchable). Add swatches in
`lua/config/palette_tuner.lua`.

**The tuner only drives Monochrome** and switches you to it on open. The Gruvbox themes
don't read `palette.lua` — edit the `c` table at the top of their file, then
`:ThemeReload`.

## Notes
- `<leader>f` is bound to **format** *and* is the prefix for the find group — pressing
  `<leader>f` alone formats after `timeoutlen`; `<leader>f{key}` opens a picker.
- `]f`/`[f` = next/prev **function** globally, but **next/prev failing test** inside
  the C# test-runner window (buffer-local).
- Indentation on blank lines: `autoindent` inserts the indent when you press Enter but
  **removes it again** if you leave the line without typing (`:h 'autoindent'`), so blank
  lines are genuinely empty and arrowing onto one puts you at column 0. `virtualedit` is
  deliberately left unset — `"all"` was tried and made normal-mode motions worse. Use `S`
  on a blank line to re-apply the indent, or `<C-t>` / `<C-d>` to indent/outdent by one
  `shiftwidth` while inserting.
- C# tests use easy-dotnet's runner (`<leader>nt*`). Frontend tests run outside
  nvim (`npx vitest --ui`) — the pnpm suite is too slow for an in-editor runner.
- Comment continuation: filetype plugins add `o` and `r` to `formatoptions`, which is
  why `o`/`O` on a comment line used to repeat the `//`. A `FileType` autocmd in
  `lua/config/autocmds.lua` strips `o`, so `o`/`O` always opens a plain line. `r` is
  kept on purpose — Enter inside a comment still continues it, which is what you want
  when writing a multi-line block. To also drop that, add `:remove("r")` next to it.
- C/C++ indent while typing (`CIndentPrefersTreesitter` in `lua/config/autocmds.lua`):
  `cindent` lands you in the wrong column after a constructor-init list, a lambda
  passed as a call argument, and a wrapped argument list. Treesitter's indenter gets
  those right, so C/C++ buffers use it and fall back to `cindent` with `cinoptions=j1`
  (the flag that fixes lambdas) when no parser is loaded or the file is over 256KB.
  Still wrong in both: `<<` stream chains and wrapped template arguments — clang-format
  fixes those on `:w`. Treesitter also puts the `: member_(x)` line itself at the
  function's own indent rather than +4; the next Enter is correct.
- Do NOT probe this config with scripted `nvim --headless` runs that enter insert mode.
  See the comment in `lua/plugins/copilot.lua` — it cost two hard resets on 2026-09-08.
