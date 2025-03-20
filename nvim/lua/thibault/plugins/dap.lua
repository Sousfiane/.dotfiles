return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "theHamsta/nvim-dap-virtual-text",
        "nvim-neotest/nvim-nio",
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        dap.set_log_level("TRACE")

        require("nvim-dap-virtual-text").setup()

        dapui.setup({
            layout = {
                {
                    elements = {
                        { id = "scopes",      size = 0.25 },
                        { id = "breakpoints", size = 0.25 },
                        { id = "stacks",      size = 0.25 },
                        { id = "watches",     size = 0.25 },
                    },
                    size = 12,
                    position = "left",
                },
                {
                    elements = {
                        { id = "console", size = 0.5 },
                        { id = "repl",    size = 0.5 },
                    },
                    size = 12,
                    position = "bottom",
                },
            },
            expand_lines = true,
        })

        dap.listeners.before.attach.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            dapui.close()
        end

        dap.adapters["pwa-node"] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
                command = "node",
                args = { os.getenv("HOME") .. "/.config/dap/js-debug/src/dapDebugServer.js", "${port}" },
            },
        }

        dap.adapters.chrome = {
            type = "executable",
            command = "node",
            args = { os.getenv("HOME") .. "/.config/dap/vscode-chrome-debug/out/src/chromeDebug.js" },
        }

        local map = function(mode, lhs, rhs, opts)
            opts = opts or {}
            opts.silent = true
            vim.keymap.set(mode, lhs, rhs, opts)
        end

        map("n", "<F5>", dap.continue, { desc = "Start/Continue Debugging" })
        map("n", "<F10>", dap.step_over, { desc = "Step Over" })
        map("n", "<F11>", dap.step_into, { desc = "Step Into" })
        map("n", "<F12>", dap.step_out, { desc = "Step Out" })
        map("n", "<Leader>b", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
        map("n", "<Leader>B", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
            { desc = "Set Conditional Breakpoint" })
        map("n", "<Leader>dl", dap.run_last, { desc = "Run Last Debugging Session" })
        map("n", "<Leader>du", function()
            require("nvim-tree.api").tree.close()
            vim.cmd('UndotreeHide')
            dapui.toggle()
        end, { desc = "Run Last Debugging Session" })
    end,
}
