# Neovim Config — Prerequisites

Everything that must exist on the machine before this config works. Plugins install
themselves; the things below do not.

---

## Neovim

**0.11+ required.** The config uses `vim.lsp.config`, `vim.lsp.enable` and
`vim.hl.priorities`, none of which exist in 0.10. Developed against `v0.13.0-dev`.

> Despite the repo name, this is a **native Windows** config, not WSL. `lua/plugins/csharp.lua`
> launches the Roslyn dll directly because libuv cannot exec a `.cmd` shim on Windows.

---

## System tools

| Tool | Needed for | Install (Windows) |
|---|---|---|
| **git** | lazy.nvim clones every plugin | `winget install Git.Git` |
| **ripgrep** | snacks.picker live grep (`<leader>fg`) | `scoop install ripgrep` |
| **fd** | snacks.picker file finder (`<leader>ff`) | `scoop install fd` |
| **delta** | every diff preview — git pickers, review panel, lazygit | `scoop install delta` |
| **lazygit** | `<leader>gg` | `scoop install lazygit` |
| **gh** (GitHub CLI) | review mode: `w` → open PRs, `gh pr checkout` worktrees | `winget install GitHub.cli` |
| **tree-sitter CLI** | compiles parsers (nvim-treesitter `main` branch) | `npm i -g tree-sitter-cli` |
| **C compiler** | building those parsers | MSVC, or MSYS2/mingw |
| **Nerd Font** | every icon in the statusline, picker, explorer, git signs | [nerdfonts.com](https://www.nerdfonts.com/) |

**Node.js** is only needed for `ts_ls` and Copilot. A C#-only user can skip it.

---

## Per language

### C# / .NET
- **.NET SDK** — required by both the Roslyn language server and easy-dotnet. [dot.net](https://dot.net)
- **Mason `roslyn`** — see the manual step below.
- **Mason `netcoredbg`** — the debug adapter. easy-dotnet auto-registers it
  (`debugger.auto_register_dap`), but the package still has to be installed.

### C / C++
- **CMake** — `<leader>mb` builds through it (`lua/config/cppbuild.lua`); a build dir must
  already be configured (`CMakeCache.txt` present).
- **clang-format** — ships with LLVM/clangd; used by conform on save.
- For project-wide `gr`/`gd`, clangd needs `compile_commands.json`:
  `cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build`

### JS / TS
- Node.js, and `prettier` (Mason) for formatting.

---

## Language servers (Mason)

| Server | Language | Auto-installed? |
|---|---|---|
| `lua_ls` | Lua | ✅ `ensure_installed` |
| `clangd` | C / C++ | ✅ `ensure_installed` |
| `ts_ls` | JS / TS / React | ✅ `ensure_installed` |
| **`roslyn`** | **C#** | ❌ **manual — see below** |

> **The one manual step.** `roslyn` is not in `ensure_installed` and lives in a custom
> registry. Run `:MasonUpdate` then `:MasonInstall roslyn`.
>
> If it is missing, `lua/plugins/csharp.lua` finds no dll, sets `cmd = nil`, and falls back
> to a binary that is not on PATH. C# then opens with **no completion, no hover and no
> diagnostics, and no error message**. If C# feels dead, check this first with `:Mason`.

The Crashdummyy registry is already configured in `lua/plugins/lsp.lua`.

OmniSharp is deliberately disabled (`vim.lsp.enable("omnisharp", false)`) so it cannot
double-index alongside Roslyn. `automatic_enable = false` means installing any other
server does **not** silently start it — servers are enabled explicitly in `lsp.lua`.

---

## Formatters (conform, Mason)

`stylua` (lua) · `clang-format` (c, cpp) · `prettier` (js, ts, jsx, tsx)

There is **no C# formatter configured** — C# formats through Roslyn's LSP formatter via
`lsp_fallback`. To use csharpier instead, install it with Mason and add
`csharp = { "csharpier" }` to `formatters_by_ft` in `lua/plugins/formatter.lua`.

---

## GitHub Copilot

`copilot.lua` loads on `InsertEnter` and feeds the blink completion menu (no inline ghost
text). Authenticate once with `:Copilot auth`. Requires a Copilot subscription.
Toggle its completions with `<leader>uc`. Without a subscription, nothing else breaks.

---

## First launch

1. Install the system tools above, and the .NET SDK if you write C#.
2. Open Neovim — lazy.nvim bootstraps and installs every plugin.
3. `:MasonUpdate`, then **`:MasonInstall roslyn`** (the C# server; nothing else needs this).
4. Treesitter parsers compile automatically on `VeryLazy`. `:checkhealth nvim-treesitter`
   if something looks unhighlighted.
5. `:Copilot auth` if you use Copilot.
6. `:checkhealth` to catch anything missing from the table above.

---

## Notes

- `lua/config/secrets.lua` is gitignored and no longer used by anything. If you have one
  from an older checkout, it is dead weight — delete it.
- Do **not** probe this config with scripted `nvim --headless` runs that enter insert mode.
  See the comment at the top of `lua/plugins/copilot.lua`.
