-- Editor options, set before anything else so plugins see them.

vim.g.mapleader = " "

-- neo-tree is the file browser
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.o.number = true
vim.o.relativenumber = true

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.o.hlsearch = false
vim.o.incsearch = true

vim.o.termguicolors = true

vim.o.scrolloff = 8
vim.o.signcolumn = "yes"
vim.o.winborder = "rounded"

-- how long the cursor rests before CursorHold: the diagnostic float and LSP word highlights (autocmds.lua,
-- lsp.lua). 50 made the float flash up on every pause
vim.o.updatetime = 250

vim.o.fillchars = "eob: "

-- the dotfiles keep home files without their dot (home/zprofile is linked as ~/.zprofile): Neovim knows
-- `zshrc` with or without it, but not `zprofile`
vim.filetype.add({ filename = { zprofile = "zsh" } })
