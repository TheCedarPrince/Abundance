-- ~/.config/nvim/lua/plugins/winshift.lua
-- sindrets/winshift.nvim — rearrange windows with ease.
-- Replaces the winmove + hydra setup entirely.
--
-- ── How to use ───────────────────────────────────────────────────────────────
--
--   \wm        enter Win-Move mode for current window
--              (then use hjkl to move, HJKL to move to far edge, q/<Esc> to exit)
--   \wx        swap current window with another (letter picker appears)
--
--   One-shot directional moves (no modal entry needed):
--   \wh  \wj  \wk  \wl        move window one step in direction
--   \wH  \wJ  \wK  \wL        move window to far edge in direction

return {
  "sindrets/winshift.nvim",
  commit = "37468ed6f385dfb50402368669766504c0e15583",
  cmd  = "WinShift",
  keys = {
    { "<leader>wm", "<cmd>WinShift<CR>",           desc = "Win-Move mode" },
    { "<leader>wx", "<cmd>WinShift swap<CR>",       desc = "Swap windows" },
    { "<leader>wh", "<cmd>WinShift left<CR>",       desc = "Move window left" },
    { "<leader>wj", "<cmd>WinShift down<CR>",       desc = "Move window down" },
    { "<leader>wk", "<cmd>WinShift up<CR>",         desc = "Move window up" },
    { "<leader>wl", "<cmd>WinShift right<CR>",      desc = "Move window right" },
    { "<leader>wH", "<cmd>WinShift far_left<CR>",   desc = "Move window far left" },
    { "<leader>wJ", "<cmd>WinShift far_down<CR>",   desc = "Move window far down" },
    { "<leader>wK", "<cmd>WinShift far_up<CR>",     desc = "Move window far up" },
    { "<leader>wL", "<cmd>WinShift far_right<CR>",  desc = "Move window far right" },
  },

  opts = {
    highlight_moving_win = true,
    focused_hl_group     = "Visual",
    moving_win_options   = {
      wrap         = false,
      cursorline   = false,
      cursorcolumn = false,
      colorcolumn  = "",
    },
    keymaps = {
      disable_defaults = false,
      win_move_mode    = {
        ["h"] = "left",  ["j"] = "down",  ["k"] = "up",  ["l"] = "right",
        ["H"] = "far_left", ["J"] = "far_down", ["K"] = "far_up", ["L"] = "far_right",
        ["<left>"] = "left", ["<down>"] = "down", ["<up>"] = "up", ["<right>"] = "right",
        ["<S-left>"] = "far_left", ["<S-down>"] = "far_down",
        ["<S-up>"]   = "far_up",   ["<S-right>"] = "far_right",
      },
    },
  },

  config = function(_, opts)
    require("winshift").setup(opts)

    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>w",  group = "Window" },
        { "<leader>wm", desc  = "Win-Move mode (hjkl, q to exit)" },
        { "<leader>wx", desc  = "Swap windows" },
        { "<leader>wh", desc  = "Move left" },
        { "<leader>wj", desc  = "Move down" },
        { "<leader>wk", desc  = "Move up" },
        { "<leader>wl", desc  = "Move right" },
        { "<leader>wH", desc  = "Move far left" },
        { "<leader>wJ", desc  = "Move far down" },
        { "<leader>wK", desc  = "Move far up" },
        { "<leader>wL", desc  = "Move far right" },
      })
    end
  end,
}
