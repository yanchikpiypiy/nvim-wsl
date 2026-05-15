# Neovim Config — Prerequisites

Everything that must be installed before this config works correctly.

---

## Neovim

**Version**: 0.10+ required (uses `vim.lsp.inlay_hint`, `vim.lsp.enable`, etc.)

---

## System tools

### Git
Required by lazy.nvim (plugin manager) to clone and update plugins.

### make / GCC (or any C compiler)
Required to build `telescope-fzf-native.nvim` (`build = "make"`).
On Windows: install via [MSYS2](https://www.msys2.org/) or use WSL.

### fd
Used by Telescope's `find_files` picker as the find backend.
- Windows: `scoop install fd` or `winget install sharkdp.fd`
- Linux/WSL: `apt install fd-find` or `cargo install fd-find`

### ripgrep (rg)
Used by Telescope's `live_grep` picker.
- Windows: `scoop install ripgrep` or `winget install BurntSushi.ripgrep.MSVC`
- Linux/WSL: `apt install ripgrep`

### Node.js + npm
Required by Mason to install several language servers (ts_ls, lua_ls, etc.).
Get it from [nodejs.org](https://nodejs.org/) or via `nvm`.

### .NET SDK
Required by the Roslyn language server (C# LSP).
Install from [dot.net](https://dot.net). The `roslyn` Mason package wraps the
compiler toolchain — without .NET SDK installed it will not start.

### LazyGit
Required by `lazygit.nvim` (`<leader>gg`).
- Windows: `scoop install lazygit` or `winget install JesseDuffield.lazygit`
- Linux/WSL: see [lazygit releases](https://github.com/jesseduffield/lazygit/releases)

---

## Mason-installed language servers

Mason auto-installs these on first launch (via `ensure_installed`), but they
need the system dependencies above to work.

| Server | Language | Mason package | Needs |
|---|---|---|---|
| `roslyn` | C# | `roslyn` (Crashdummyy registry) | .NET SDK |
| `lua_ls` | Lua | `lua-language-server` | — |
| `clangd` | C / C++ | `clangd` | — |
| `ts_ls` | JS / TS / React | `typescript-language-server` | Node.js |

> **Note**: Roslyn requires the custom Mason registry `Crashdummyy/mason-registry`.
> It is already configured in `lua/plugins/lsp.lua`. Run `:MasonUpdate` then
> `:MasonInstall roslyn` on first setup.

---

## Nerd Font

All icons in the statusline, completion menu, file explorer, and git signs
use Nerd Font codepoints. Install any [Nerd Font](https://www.nerdfonts.com/)
and set it as your terminal font (e.g. `JetBrainsMono Nerd Font`).

---

## GitHub Copilot

`copilot.lua` is loaded at startup. Authenticate once with `:Copilot auth`
inside Neovim. Requires a GitHub Copilot subscription.

---

## Anthropic API key (avante.nvim)

AI inline editing (`<leader>ae`) calls the Anthropic API and bills per request.

1. Create `lua/config/secrets.lua` (already gitignored):
   ```lua
   vim.env.ANTHROPIC_API_KEY = "sk-ant-..."
   ```
2. Get a key from [console.anthropic.com](https://console.anthropic.com/).

---

## Claude Code CLI (claudecode.nvim)

AI chat/project integration (`<leader>ac`) uses the Claude CLI via your
Claude subscription — no API billing.

Install: `npm install -g @anthropic-ai/claude-code`
Then authenticate once: `claude` in a terminal.

---

## First-launch checklist

1. Install all system tools above
2. Open Neovim — lazy.nvim bootstraps and installs all plugins automatically
3. Run `:MasonUpdate` to refresh registries (pulls Crashdummyy registry)
4. Run `:MasonInstall roslyn` for C# support
5. Run `:TSUpdate` if tree-sitter parsers weren't auto-installed
6. Run `:Copilot auth` to authenticate GitHub Copilot
7. Add `lua/config/secrets.lua` with your Anthropic API key
8. Run `claude` in a terminal to authenticate the Claude CLI
