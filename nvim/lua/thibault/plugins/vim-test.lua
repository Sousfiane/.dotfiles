return {
    "vim-test/vim-test",
    dependencies = {
        "voldikss/vim-floaterm"
    },
    config = function()
        vim.keymap.set("n", "<leader>t", ":TestNearest<CR>", {})
        vim.keymap.set("n", "<leader>T", ":TestFile<CR>", {})
        vim.keymap.set("n", "<leader>a", ":TestSuite<CR>", {})
        vim.keymap.set("n", "<leader>l", ":TestLast<CR>", {})
        vim.keymap.set("n", "<leader>g", ":TestVisit<CR>", {})
        vim.cmd("let test#strategy = 'floaterm'")
        vim.cmd("let g:floaterm_borderchars = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']")
        vim.cmd("highlight FloatermBorder guifg=#6e6a86")
        vim.cmd("let g:floaterm_title = ''")
    end,
}

