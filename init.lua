require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.cppbuild")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- All colorscheme plugins are loaded now; apply the saved preset (default: gruvbox dark hard).
require("config.theme").restore()
