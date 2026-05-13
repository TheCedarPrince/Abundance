-- ~/.config/nvim/lua/plugins/warp.nvim
-- warp.nvim — automatic jump hints on visible file paths, URLs, markdown links.
-- No manual keybind needed: warp detects paths in the buffer and overlays
-- hint labels automatically. Type the label to jump/open.
-- Configured here with no custom keymap to avoid conflicts with \w (winmove).

return {
  "nolleh/warp.nvim",
  commit = "d91533e9fa768f6d6fbd31fc27bf8b1236c4c712",
  event = "VeryLazy",
  config = function()
    require("warp").setup({
      default_keymap = false, -- no keybind; warp overlays hints passively
    })
  end,
}
