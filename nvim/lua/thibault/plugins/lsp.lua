return {
    'neoclide/coc.nvim',
    branch = 'release',
    config = function()
        vim.opt.backup = false
        vim.opt.writebackup = false
        vim.opt.updatetime = 300
        vim.opt.signcolumn = "yes"
        vim.api.nvim_create_augroup("CocGroup", {})
        vim.api.nvim_create_autocmd("CursorHold", {
            group = "CocGroup",
            command = "silent call CocActionAsync('highlight')",
            desc = "Highlight symbol under cursor on CursorHold"
        })

        function _G.check_back_space()
            local col = vim.fn.col('.') - 1
            return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
        end

        vim.api.nvim_set_var('coc_global_extensions', {
            'coc-json',
            'coc-css',
            'coc-tsserver',
            'coc-html',
            'coc-clangd',
            'coc-java',
            'coc-pyright',
            'coc-lua',
            'coc-snippets',
            'coc-pairs',
            'coc-sh'
        })

        local opts = { silent = true, noremap = true, expr = true, replace_keycodes = false }

        vim.keymap.set("i", "<TAB>",
            'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()', opts)
        vim.keymap.set("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], opts)
        vim.keymap.set("i", "<cr>", [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]],
            opts)

        vim.keymap.set("i", "<c-j>", "<Plug>(coc-snippets-expand-jump)")

        vim.keymap.set("n", "<leader>qf", "<Plug>(coc-fix-current)", { silent = true, nowait = true })

        vim.keymap.set("x", "<leader>f", "<Plug>(coc-format-selected)", { silent = true })
        vim.keymap.set("n", "<leader>f", "<Plug>(coc-format-selected)", { silent = true })
    end
}
