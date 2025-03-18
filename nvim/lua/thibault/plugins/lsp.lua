return {
    'neoclide/coc.nvim',
    branch = 'release',
    config = function()
        vim.opt.backup = false
        vim.opt.writebackup = false
        vim.opt.updatetime = 300
        vim.opt.signcolumn = "yes"
        vim.api.nvim_create_augroup("CocGroup", {})

        -- Highlight symbol under cursor on CursorHold
        vim.api.nvim_create_autocmd("CursorHold", {
            group = "CocGroup",
            command = "silent call CocActionAsync('highlight')",
            desc = "Highlight symbol under cursor on CursorHold"
        })

        -- Disable CursorHold for large files (more than 1000 lines)
        vim.api.nvim_create_autocmd("BufReadPost", {
            pattern = "*",
            command = "if &filetype != 'coc' && line('$') > 1000 | autocmd! CursorHold | endif",
            desc = "Disable CursorHold for large files"
        })

        function _G.check_back_space()
            local col = vim.fn.col('.') - 1
            return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
        end

        -- CoC Extensions
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
            'coc-sh',
            'coc-eslint',
            'coc-prettier'
        })

        -- Key mapping options
        local opts = { silent = true, noremap = true, expr = true, replace_keycodes = false }

        -- Completion navigation
        vim.keymap.set("i", "<TAB>",
            'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()', opts)
        vim.keymap.set("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], opts)
        vim.keymap.set("i", "<cr>", [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]],
            opts)

        -- Manually trigger completion with <C-Space>
        vim.keymap.set('i', '<C-Space>', 'coc#refresh()', opts)

        -- Snippets
        vim.keymap.set("i", "<c-j>", "<Plug>(coc-snippets-expand-jump)")

        -- Go to diagnostics
        vim.keymap.set("n", "gp", "<Plug>(coc-diagnostic-prev)", {silent = true})
        vim.keymap.set("n", "gn", "<Plug>(coc-diagnostic-next)", {silent = true})

        -- Go to definitions, types, implementations, and references
        vim.keymap.set("n", "gd", "<Plug>(coc-definition)", {silent = true})
        vim.keymap.set("n", "gy", "<Plug>(coc-type-definition)", {silent = true})
        vim.keymap.set("n", "gi", "<Plug>(coc-implementation)", {silent = true})
        vim.keymap.set("n", "gr", "<Plug>(coc-references)", {silent = true})

        -- Rename symbol
        vim.keymap.set("n", "<leader>rn", "<Plug>(coc-rename)", {silent = true})
        vim.keymap.set("x", "<leader>f", "<Plug>(coc-format-selected)", {silent = true})
        vim.keymap.set("n", "<leader>f", "<Plug>(coc-format-selected)", {silent = true})

        -- Code actions
        opts = {silent = true, nowait = true}
        vim.keymap.set("x", "<leader>ca", "<Plug>(coc-codeaction-selected)", opts)
        vim.keymap.set("n", "<leader>ca", "<Plug>(coc-codeaction-selected)", opts)
        vim.keymap.set("n", "<leader>cac", "<Plug>(coc-codeaction-cursor)", opts)
        vim.keymap.set("n", "<leader>cas", "<Plug>(coc-codeaction-source)", opts)
        vim.keymap.set("n", "<leader>qf", "<Plug>(coc-fix-current)", opts)

        -- Refactor code
        vim.keymap.set("n", "<leader>re", "<Plug>(coc-codeaction-refactor)", {silent = true})
        vim.keymap.set("x", "<leader>r", "<Plug>(coc-codeaction-refactor-selected)", {silent = true})
        vim.keymap.set("n", "<leader>r", "<Plug>(coc-codeaction-refactor-selected)", {silent = true})

        -- Code lens action
        vim.keymap.set("n", "<leader>cl", "<Plug>(coc-codelens-action)", opts)

        -- Open diagnostics in a separate window
        vim.keymap.set("n", "<leader>cd", ":CocDiagnostics<CR>", {silent = true})

        -- Auto-format on save
        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*",
            command = "silent! lua vim.lsp.buf.formatting_sync()",
            desc = "Auto-format code on save"
        })
    end
}

