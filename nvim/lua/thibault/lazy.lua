-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
    'lewis6991/gitsigns.nvim',
    'm4xshen/autoclose.nvim',
    'ThePrimeagen/vim-be-good',

    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.4',
        dependencies = {'nvim-lua/plenary.nvim'},
    },

    {
        'rose-pine/neovim',
        as = 'rose-pine',
    },

    {
        'nvim-tree/nvim-tree.lua',
        dependencies = {'nvim-tree/nvim-web-devicons'},
    },

    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
    },

    {
        'neoclide/coc.nvim',
        branch = 'release',
    },

    {
        'ThePrimeagen/harpoon',
        branch = 'harpoon2',
        dependencies = {'nvim-lua/plenary.nvim'},
    },
})
