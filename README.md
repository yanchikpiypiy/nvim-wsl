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
| `<leader>gp` | Preview hunk |
| `<leader>gb` / `<leader>gB` | Blame line / toggle line blame |
| `<leader>gd` | Diff this (gitsigns) |
| `<leader>gv` / `<leader>gV` | Diffview open / close (uncommitted changes) |
| `<leader>gm` | Diffview: this branch vs `main` (`main...HEAD`, falls back to master/origin) |
| `<leader>gh` / `<leader>gH` | File history (current / all) |
| `]c` / `[c` | Next / previous hunk |
| `ih` | Select hunk (text object) |
| diffview window | `]c`/`[c` hunks · `<Tab>`/`<S-Tab>` files · `<leader>e` file list · `do` take other side · `q` close |

Git pickers (`gt`/`gc`/`gC`/`gz`) preview diffs through **delta** (`previewers.diff` in
`snacks.lua`); same rendering as `git diff` in the shell and in lazygit.

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

---

## Themes
- `<leader>ut` / `:Theme` opens the picker. Entries are tagged **plugin** (gruvbox,
  everforest) or **custom** (hand-rolled). Hovering previews live; `<CR>` saves the
  choice to `~/.local/state/nvim/theme`, `<Esc>` reverts.
- Plugin themes are listed in `lua/config/theme.lua` (`M.plugins`).
- Custom themes live one-per-file in `lua/themes/`. A file returns
  `{ name, desc, base?, background?, highlights = function() return { Group = spec } end }`.
  `base` names a plugin colorscheme to paint over (Monochrome uses `monochrome.nvim`);
  leave it out to start from Neovim's defaults. Drop a file in and it shows up in the picker.
  `:ThemeReload` re-reads the current custom file after you edit it.

## Notes
- `<leader>f` is bound to **format** *and* is the prefix for the find group — pressing
  `<leader>f` alone formats after `timeoutlen`; `<leader>f{key}` opens a picker.
- `]f`/`[f` = next/prev **function** globally, but **next/prev failing test** inside
  the C# test-runner window (buffer-local).
- C# tests use easy-dotnet's runner (`<leader>nt*`). Frontend tests run outside
  nvim (`npx vitest --ui`) — the pnpm suite is too slow for an in-editor runner.
