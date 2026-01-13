-- ~/AppData/Local/nvim/lua/plugins/treesitter.lua
return {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
        -- Install parsers
        local ts = require('nvim-treesitter')
        ts.install({ 'javascript', 'typescript', 'tsx', 'html', 'css', 'lua', 'vim', 'c_sharp' })
        -- Enable highlighting for ALL filetypes automatically
        vim.api.nvim_create_autocmd('FileType', {
            pattern = '*',
            callback = function(event)
                local ok = pcall(vim.treesitter.start, event.buf)
                if not ok then
                    -- Parser not installed for this filetype, silently continue
                    return
                end
            end,
        })
    end
}
