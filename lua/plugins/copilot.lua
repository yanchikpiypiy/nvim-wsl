return {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter", -- only consumed by blink completion; keep off startup
    -- `InsertEnter` also fires under `nvim --headless` -- any `normal! A...` in a
    -- probe script enters insert and starts a server. That one is orphaned when
    -- the script exits: it misses the LSP shutdown handshake, then busy-loops on
    -- closed stdio and grows ~40MB/s with no ceiling. A scripted loop over a few
    -- nvim runs exhausts RAM+swap and hard-freezes the machine (this cost two
    -- resets on 2026-09-08). Headless has no completion menu to feed, so skip it.
    cond = function()
        return #vim.api.nvim_list_uis() > 0
    end,
    config = function()
        require("copilot").setup({
            suggestion = { enabled = false },
            panel = { enabled = false },
            -- The default root_dir searches upward from CWD, not the buffer.
            -- Launched at C:\Cris -- a plain folder with no .git of its own --
            -- that search finds nothing. Resolve from the buffer so each repo
            -- gets a real workspace root.
            root_dir = function()
                return vim.fs.root(0, ".git") or vim.uv.cwd()
            end,
            -- The bundled server emits a WARN per failed org-custom-agent
            -- lookup ("list Infonetica/cris-erm -> 404") -- ~1.5k a session,
            -- each one a synchronous write into nvim's lsp.log.
            logger = { print_log_level = vim.log.levels.ERROR },
        })
    end,
}
