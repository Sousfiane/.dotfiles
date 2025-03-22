return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "nvim-java/nvim-java",
            "williamboman/mason-lspconfig.nvim",
            "williamboman/mason.nvim",
        },
        lazy = false,
        config = function()
            require("mason").setup()
            require("java").setup()
            require("mason-lspconfig").setup({
                automatic_installation = true,
            })

            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            local lspconfig = require("lspconfig")
            lspconfig.ts_ls.setup({
                capabilities = capabilities,
            })
            lspconfig.html.setup({
                capabilities = capabilities,
            })
            lspconfig.lua_ls.setup({
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" },
                        },
                    },
                },
            })
            lspconfig.jdtls.setup({
                capabilities = capabilities,
            })
            lspconfig.clangd.setup({
                capabilities = capabilities,
            })

            vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
            vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
            vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})

            local signs = {
                Error = " ",
                Warn = " ",
                Hint = " ",
                Info = " ",
            }

            for type, icon in pairs(signs) do
                local hl = "DiagnosticSign" .. type
                vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
            end

            vim.diagnostic.config({
                signs = true, -- Show signs in sign column
                underline = true,
                update_in_insert = false,
                float = {
                    border = "rounded",
                    source = "always",
                },
            })
        end,
    },
}
