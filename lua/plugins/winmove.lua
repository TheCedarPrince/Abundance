-- ~/.config/nvim/lua/plugins/winmove.lua
-- winmove.nvim — Move, swap, and resize windows.
-- Modes are driven by Hydra (see hydra-winmove.lua).
-- This file just configures winmove itself; keymaps to *enter* modes live in hydra-winmove.lua.

return {
  "MisanthropicBit/winmove.nvim",
  lazy = true, -- loaded on demand by Hydra bindings

  config = function()
    local winmove  = require("winmove")
    local at_edge  = require("winmove.at_edge")

    winmove.configure({
      keymaps = {
        help       = "?",    -- show help popup inside the mode
        help_close = "q",
        quit       = "q",
        toggle_mode = "<Tab>", -- cycle move → swap → resize
      },

      modes = {
        move = {
          highlight = "Visual",
          at_edge = {
            horizontal = at_edge.AtEdge.Wrap,    -- wrap around editor edges
            vertical   = at_edge.AtEdge.Wrap,
          },
          keymaps = {
            left      = "h",
            down      = "j",
            up        = "k",
            right     = "l",
            far_left  = "H",  -- move as far left as possible
            far_down  = "J",
            far_up    = "K",
            far_right = "L",
            split_left  = "sh",
            split_down  = "sj",
            split_up    = "sk",
            split_right = "sl",
          },
        },

        swap = {
          highlight = "Substitute",
          at_edge = {
            horizontal = at_edge.AtEdge.None,
            vertical   = at_edge.AtEdge.None,
          },
          keymaps = {
            left  = "h",
            down  = "j",
            up    = "k",
            right = "l",
          },
        },

        resize = {
          highlight = "Todo",
          default_resize_count = 3,
          keymaps = {
            left  = "h",
            down  = "j",
            up    = "k",
            right = "l",
            large_left  = "H",
            large_down  = "J",
            large_up    = "K",
            large_right = "L",
            -- bottom-right anchor variants
            left_botright  = "<C-h>",
            down_botright  = "<C-j>",
            up_botright    = "<C-k>",
            right_botright = "<C-l>",
          },
        },
      },
    })
  end,
}
