return {
  'mbbill/undotree',
  config = function()
    vim.keymap.set('n', '<leader>u', function()
      -- Check if NvimTree is open and close it
      local nvim_tree_api = require("nvim-tree.api")
      if nvim_tree_api.tree.is_visible() then
        -- Close NvimTree
        nvim_tree_api.tree.close()
      end

      -- Toggle UndoTree
      vim.cmd.UndotreeToggle()
    end)

    -- Set Undotree width
    vim.g.undotree_SplitWidth = 40
  end
}
