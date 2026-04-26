-- ~/.config/nvim/lua/plugins/jabs.lua
-- JABS — Just Another Buffer Switcher
-- Primary buffer switcher. Use \b to open the floating picker.
-- vim-ctrlspace handles workspace/session management separately.

return {
  "matbme/JABS.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>b", "<cmd>JABSOpen<CR>", desc = "Buffers (JABS)" },
  },
  opts = {
    -- Position: middle-right of the editor
    position = { "right", "center" },
    relative = "editor",
    clip_popup_size = true,

    width = 60,
    height = 16,
    border = "rounded",

    offset = {
      top = 0,
      bottom = 0,
      left = 0,
      right = 2,
    },

    sort_mru = true,          -- most-recently-used buffers on top
    split_filename = true,    -- separate filename from path
    split_filename_path_width = 18,

    -- Preview appears to the left of the JABS window
    preview_position = "left",
    preview = {
      width = 60,
      height = 24,
      border = "rounded",
    },

    highlight = {
      current   = "Title",
      hidden    = "StatusLineNC",
      split     = "WarningMsg",
      alternate = "StatusLine",
    },

    -- Clean symbol set (nerd font)
    symbols = {
      current        = "",
      split          = "",
      alternate      = "",
      hidden         = "󰘓",
      locked         = "",
      ro             = "",
      edited         = "",
      terminal       = "",
      default_file   = "",
      terminal_symbol = ">_",
    },

    -- Keymaps active inside the JABS floating window
    keymap = {
      close   = "d",         -- delete/close buffer
      jump    = "<CR>",      -- jump to buffer
      h_split = "s",         -- open in horizontal split
      v_split = "v",         -- open in vertical split
      preview = "p",         -- toggle preview pane
    },

    use_devicons = true,
  },

  config = function(_, opts)
    require("jabs").setup(opts)

    -- WhichKey group registration
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>b", desc = "Buffers (JABS)" },
      })
    end
  end,
}
