-- ~/.config/nvim/lua/plugins/warp.lua
-- warp.nvim — Jump to file paths, URLs, and markdown links visible in any buffer.
-- Especially useful in terminal buffers: press \w, type the hint label, land there.
-- Prefix hint with S or V to open in a split instead.

return {
  "nolleh/warp.nvim",
  keys = {
    { "<leader>w", desc = "Warp — jump to path/URL" },
  },
  config = function()
    require("warp").setup({
      -- Disable the built-in default so we control the binding ourselves
      default_keymap = false,
    })

    vim.keymap.set("n", "<leader>w", function()
      require("warp").warp()
    end, { desc = "Warp — jump to path/URL/link" })

    -- WhichKey group registration
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>w", desc = "Warp — jump to path/URL" },
      })
    end
  end,
}
