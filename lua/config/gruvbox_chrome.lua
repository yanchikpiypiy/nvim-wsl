-- Editor furniture shared by every gruvbox-based theme: the places where
-- gruvbox's own defaults fight the rest of the config (coloured blocks behind
-- git status letters, a lighter sign column, saturated diff slabs).
-- Syntax colours are NOT here -- each theme owns those.
--
-- Lives in config/ and not themes/ because config/theme.lua treats every file
-- in lua/themes/ as a selectable theme.
local M = {}

-- All opts are optional; anything omitted falls back to gruvbox's own palette.
--   white / dim   text and de-emphasised text
--   add / change / delete   git + diff accents
function M.build(opts)
    opts = opts or {}
    local g = require("gruvbox").palette
    local white  = opts.white  or g.light1
    local dim    = opts.dim    or g.light4
    local add    = opts.add    or g.bright_green
    local change = opts.change or g.bright_yellow
    local delete = opts.delete or g.bright_red
    local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg

    return {
        -- gruvbox's cream Normal reads orange next to white UI text
        ["Normal"]   = { fg = white, bg = bg },
        ["NormalNC"] = { fg = white, bg = bg },

        -- gruvbox.nvim links diffAdded -> DiffAdd, a *line background*, which is
        -- what puts a green block behind diffview's "A". Keep these fg-only.
        ["diffAdded"]   = { fg = add },
        ["diffRemoved"] = { fg = delete },
        ["diffChanged"] = { fg = change },
        ["Added"]       = { fg = add },
        ["Removed"]     = { fg = delete },
        ["Changed"]     = { fg = change },

        ["SignColumn"]   = { bg = bg },
        ["FoldColumn"]   = { fg = g.gray, bg = bg },
        ["CursorLineNr"] = { fg = g.bright_yellow, bg = bg, bold = true },
        ["DiagnosticSignError"] = { fg = g.bright_red },
        ["DiagnosticSignWarn"]  = { fg = g.bright_yellow },
        ["DiagnosticSignHint"]  = { fg = g.bright_aqua },
        ["DiagnosticSignInfo"]  = { fg = g.bright_blue },
        ["DiagnosticSignOk"]    = { fg = g.bright_green },
        ["GitSignsAdd"]    = { fg = add },
        ["GitSignsChange"] = { fg = change },
        ["GitSignsDelete"] = { fg = delete },

        -- subtle tints instead of gruvbox's saturated slabs (olive / red / dark-on-yellow)
        ["DiffAdd"]    = { bg = "#283322" },
        ["DiffDelete"] = { bg = "#3b2426" },
        ["DiffChange"] = { bg = "#2c2b24" },
        ["DiffText"]   = { bg = "#4a4323" },
        ["DiffviewDiffAddAsDelete"] = { bg = "#3b2426" },  -- diffview copies DiffDelete at load; pin it

        ["DiffviewStatusAdded"]       = { fg = add },
        ["DiffviewStatusUntracked"]   = { fg = add },
        ["DiffviewStatusCopied"]      = { fg = add },
        ["DiffviewStatusModified"]    = { fg = change },
        ["DiffviewStatusRenamed"]     = { fg = change },
        ["DiffviewStatusTypeChanged"] = { fg = change },
        ["DiffviewStatusUnmerged"]    = { fg = change },
        ["DiffviewStatusDeleted"]     = { fg = delete },
        ["DiffviewStatusBroken"]      = { fg = delete },
        ["DiffviewStatusUnknown"]     = { fg = delete },
        ["DiffviewStatusIgnored"]     = { fg = dim },
        ["DiffviewFilePanelFileName"] = { fg = white },
        ["DiffviewFilePanelCounter"]  = { fg = dim, bold = true },
        ["DiffviewFilePanelInsertions"] = { fg = add },
        ["DiffviewFilePanelDeletions"]  = { fg = delete },

        ["SnacksPickerFile"]               = { fg = white },
        ["SnacksPickerGitStatusAdded"]     = { fg = add },
        ["SnacksPickerGitStatusStaged"]    = { fg = add },
        ["SnacksPickerGitStatusModified"]  = { fg = change },
        ["SnacksPickerGitStatusRenamed"]   = { fg = change },
        ["SnacksPickerGitStatusDeleted"]   = { fg = delete },
        ["SnacksPickerGitStatusUntracked"] = { fg = dim },
        ["SnacksPickerGitStatusIgnored"]   = { fg = g.dark4 },
        ["SnacksPickerDir"]       = { fg = dim },
        ["SnacksPickerDirectory"] = { fg = white, bold = true },

        ["Directory"]            = { fg = white, bold = true },  -- gruvbox: green bold
        ["NeoTreeFileName"]      = { fg = white },
        ["NeoTreeDirectoryName"] = { fg = white, bold = true },
        ["NeoTreeDirectoryIcon"] = { fg = dim },
        ["NeoTreeRootName"]      = { fg = white, bold = true },
        ["NeoTreeDotfile"]       = { fg = dim },
        ["NeoTreeHiddenByName"]  = { fg = dim },
        ["NeoTreeIndentMarker"]  = { fg = g.dark3 },
        ["NeoTreeGitAdded"]      = { fg = add },
        ["NeoTreeGitStaged"]     = { fg = add },
        ["NeoTreeGitModified"]   = { fg = change },
        ["NeoTreeGitDeleted"]    = { fg = delete },
        ["NeoTreeGitConflict"]   = { fg = delete },
        ["NeoTreeGitUntracked"]  = { fg = dim },
    }
end

return M
