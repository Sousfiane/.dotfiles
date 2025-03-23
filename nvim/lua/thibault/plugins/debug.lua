return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui", -- DAP UI for better debugging interface
		"nvim-neotest/nvim-nio", -- Dependency for nvim-dap (optional, useful for tests)
		"williamboman/mason.nvim", -- Package manager for Neovim
		"jay-babu/mason-nvim-dap.nvim", -- Integration between mason and nvim-dap
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		------------------------------------------------------------
		-- Mason DAP Setup
		------------------------------------------------------------
		require("mason-nvim-dap").setup({
			ensure_installed = {
				"delve", -- Go debugger
				"chrome-debug-adapter", -- Chrome debugging (for web)
				"js-debug-adapter", -- JavaScript debugging
			},
		})

		------------------------------------------------------------
		-- DAP UI Setup
		------------------------------------------------------------
		dapui.setup({
			icons = {
				expanded = "▾",
				collapsed = "▸",
				current_frame = "*",
			},
			controls = {
				icons = {
					pause = "⏸",
					play = "▶",
					step_into = "⏎",
					step_over = "⏭",
					step_out = "⏮",
					step_back = "b",
					run_last = "▶▶",
					terminate = "⏹",
					disconnect = "⏏",
				},
			},
		})

		------------------------------------------------------------
		-- DAP Listeners for UI and Sessions
		------------------------------------------------------------
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
			vim.cmd("UndotreeHide") -- Hide undotree when DAP session starts
			vim.cmd(":Neotree filesystem close") -- Close neotree file explorer during debugging
		end
		--dap.listeners.before.event_terminated["dapui_config"] = dapui.close
		--dap.listeners.before.event_exited["dapui_config"] = dapui.close

		------------------------------------------------------------
		-- DAP Adapter Configurations
		------------------------------------------------------------
		-- Node.js Debug Adapter
		dap.adapters["pwa-node"] = {
			type = "server",
			host = "localhost",
			port = "${port}",
			executable = {
				command = "node",
				args = {
					os.getenv("HOME")
						.. "/.local/share/nvim/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
					"${port}",
				},
			},
		}

		-- Chrome Debug Adapter
		dap.adapters.chrome = {
			type = "executable",
			command = "node",
			args = {
				os.getenv("HOME") .. "/.local/share/nvim/mason/packages/chrome-debug-adapter/out/src/chromeDebug.js",
			},
		}

		------------------------------------------------------------
		-- Key Mappings for Debugging Actions
		------------------------------------------------------------
		vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
		vim.keymap.set("n", "<F1>", dap.step_into, { desc = "Debug: Step Into" })
		vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
		vim.keymap.set("n", "<F3>", dap.step_out, { desc = "Debug: Step Out" })
		vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
		vim.keymap.set("n", "<leader>B", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, { desc = "Debug: Set Breakpoint" })
		vim.keymap.set("n", "<F7>", dapui.toggle, { desc = "Debug: See last session result." })
	end,
}
