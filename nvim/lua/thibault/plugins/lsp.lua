return{
        'neoclide/coc.nvim',
        branch = 'release',
        config = function()
            -- Some servers have issues with backup files, see #649
            vim.opt.backup = false
            vim.opt.writebackup = false

            -- Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
            -- delays and poor user experience
            vim.opt.updatetime = 300

            -- Always show the signcolumn, otherwise it would shift the text each time
            -- diagnostics appeared/became resolved
            vim.opt.signcolumn = "yes"

            -- Highlight the symbol and its references on a CursorHold event(cursor is idle)
            vim.api.nvim_create_augroup("CocGroup", {})
            vim.api.nvim_create_autocmd("CursorHold", {
                group = "CocGroup",
                command = "silent call CocActionAsync('highlight')",
                desc = "Highlight symbol under cursor on CursorHold"
            })

            local keyset = vim.keymap.set
            -- Autocomplete
            function _G.check_back_space()
                local col = vim.fn.col('.') - 1
                return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
            end

            -- Auto install plugins
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

            -- Use Tab for trigger completion 
            local opts = {silent = true, noremap = true, expr = true, replace_keycodes = false}
            keyset("i", "<TAB>", 'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()', opts)
            keyset("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], opts)

            -- Make <CR> to accept selected completion item or notify coc.nvim to format
            -- <C-g>u breaks current undo, please make your own choice
            keyset("i", "<cr>", [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], opts)

            -- Use <c-j> to trigger snippets
            keyset("i", "<c-j>", "<Plug>(coc-snippets-expand-jump)")

            -- Apply the most preferred quickfix action on the current line.
            keyset("n", "<leader>qf", "<Plug>(coc-fix-current)",{silent = true, nowait = true})
        end
    }
