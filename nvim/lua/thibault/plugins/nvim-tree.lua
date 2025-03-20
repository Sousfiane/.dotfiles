return {
  'nvim-tree/nvim-tree.lua',
  dependencies = {'nvim-tree/nvim-web-devicons'},
  config = function()
    -- Set up NvimTree configuration
    require("nvim-tree").setup({
      view = {
        side = "left",
        adaptive_size = true,
        centralize_selection = true,
      },
      update_focused_file = {
        enable = true,
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
      },
      actions = {
        change_dir = {
          enable = false,
        },
      },
    })

    local api = require("nvim-tree.api")
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- Keymap to toggle NvimTree, but close UndoTree if it's open
    vim.keymap.set("n", "<leader>pv", function()
      -- Check if Undotree is open by looking for the Undotree buffer
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf):match("undotree") then
          -- Close Undotree if it's open
          vim.cmd('UndotreeHide')
          break
        end
      end

      -- Toggle NvimTree
      api.tree.toggle({ focus = true, find_file = true })
    end)
  end
}

