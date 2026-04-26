-- ~/.config/nvim/lua/plugins/hydra-winmove.lua
-- Hydra.nvim — persistent modal keymaps for winmove window management.
--
-- Three separate Hydras, one per winmove mode.
-- Enter via:  \wm  (move)   \ws  (swap)   \wr  (resize)
-- The hint window appears immediately on entry (hint = "window").
-- Press <Tab> inside any mode to hand off to winmove's own toggle_mode.
-- Press q or <Esc> to exit.

return {
  "nvimtools/hydra.nvim",
  dependencies = { "MisanthropicBit/winmove.nvim" },
  keys = {
    { "<leader>wm", desc = "Window: enter MOVE mode" },
    { "<leader>ws", desc = "Window: enter SWAP mode" },
    { "<leader>wr", desc = "Window: enter RESIZE mode" },
  },

  config = function()
    local Hydra   = require("hydra")
    local winmove = require("winmove")

    -- ── Shared hint-window configuration ───────────────────────────────────────
    local hint_config = {
      type     = "window",   -- floating hint always visible while Hydra is active
      border   = "rounded",
      position = "bottom-right",
    }

    -- ── Helper: safely exit winmove when Hydra exits ────────────────────────────
    local function on_exit()
      pcall(winmove.stop_mode)
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- MOVE MODE
    -- ═══════════════════════════════════════════════════════════════════════════
    local move_hint = [[
 ╭──── Window Move ──────────────────────────────────╮
 │  h/j/k/l   move window          H/J/K/L  move far │
 │  sh/sj/sk/sl  split into dir    <Tab>   → swap     │
 │  ?  help      q/<Esc>  exit                        │
 ╰────────────────────────────────────────────────────╯
]]

    Hydra({
      name   = "Window Move",
      hint   = move_hint,
      config = vim.tbl_extend("force", hint_config, {
        invoke_on_body = true,
        on_enter = function()
          winmove.start_mode("move")
        end,
        on_exit = on_exit,
      }),
      mode = "n",
      body = "<leader>wm",
      heads = {
        -- Cardinal moves
        { "h", function() winmove.move_window(0, "h") end, { desc = "Move left" } },
        { "j", function() winmove.move_window(0, "j") end, { desc = "Move down" } },
        { "k", function() winmove.move_window(0, "k") end, { desc = "Move up" } },
        { "l", function() winmove.move_window(0, "l") end, { desc = "Move right" } },
        -- Far moves
        { "H", function() winmove.move_window_far(0, "h") end, { desc = "Move far left" } },
        { "J", function() winmove.move_window_far(0, "j") end, { desc = "Move far down" } },
        { "K", function() winmove.move_window_far(0, "k") end, { desc = "Move far up" } },
        { "L", function() winmove.move_window_far(0, "l") end, { desc = "Move far right" } },
        -- Split into
        { "sh", function() winmove.split_into(0, "h") end, { desc = "Split left" } },
        { "sj", function() winmove.split_into(0, "j") end, { desc = "Split down" } },
        { "sk", function() winmove.split_into(0, "k") end, { desc = "Split up" } },
        { "sl", function() winmove.split_into(0, "l") end, { desc = "Split right" } },
        -- Exit
        { "q",     nil, { exit = true, nowait = true, desc = "Exit" } },
        { "<Esc>", nil, { exit = true, nowait = true, desc = "Exit" } },
      },
    })

    -- ═══════════════════════════════════════════════════════════════════════════
    -- SWAP MODE
    -- ═══════════════════════════════════════════════════════════════════════════
    local swap_hint = [[
 ╭──── Window Swap ───────────────────────────────────╮
 │  h/j/k/l  swap window in direction                  │
 │  <Tab>  → resize mode   q/<Esc>  exit               │
 ╰────────────────────────────────────────────────────╯
]]

    Hydra({
      name   = "Window Swap",
      hint   = swap_hint,
      config = vim.tbl_extend("force", hint_config, {
        invoke_on_body = true,
        on_enter = function()
          winmove.start_mode("swap")
        end,
        on_exit = on_exit,
      }),
      mode = "n",
      body = "<leader>ws",
      heads = {
        { "h", function() winmove.swap_window_in_direction(0, "h") end, { desc = "Swap left" } },
        { "j", function() winmove.swap_window_in_direction(0, "j") end, { desc = "Swap down" } },
        { "k", function() winmove.swap_window_in_direction(0, "k") end, { desc = "Swap up" } },
        { "l", function() winmove.swap_window_in_direction(0, "l") end, { desc = "Swap right" } },
        { "q",     nil, { exit = true, nowait = true, desc = "Exit" } },
        { "<Esc>", nil, { exit = true, nowait = true, desc = "Exit" } },
      },
    })

    -- ═══════════════════════════════════════════════════════════════════════════
    -- RESIZE MODE
    -- ═══════════════════════════════════════════════════════════════════════════
    local resize_hint = [[
 ╭──── Window Resize ─────────────────────────────────────────────────────╮
 │  h/j/k/l         resize (top-left anchor)                              │
 │  H/J/K/L         resize large amount                                   │
 │  <C-h/j/k/l>     resize (bottom-right anchor)                          │
 │  q/<Esc>  exit                                                          │
 ╰────────────────────────────────────────────────────────────────────────╯
]]

    local function resize(dir, count, anchor)
      local winmove_anchor = require("winmove").ResizeAnchor
      winmove.resize_window(
        vim.api.nvim_get_current_win(),
        dir,
        count or 3,
        anchor or winmove_anchor.TopLeft
      )
    end

    Hydra({
      name   = "Window Resize",
      hint   = resize_hint,
      config = vim.tbl_extend("force", hint_config, {
        invoke_on_body = true,
        on_enter = function()
          winmove.start_mode("resize")
        end,
        on_exit = on_exit,
      }),
      mode = "n",
      body = "<leader>wr",
      heads = {
        -- Small (top-left anchor)
        { "h", function() resize("h", 3) end,  { desc = "← shrink" } },
        { "j", function() resize("j", 3) end,  { desc = "↓ grow" } },
        { "k", function() resize("k", 3) end,  { desc = "↑ shrink" } },
        { "l", function() resize("l", 3) end,  { desc = "→ grow" } },
        -- Large (top-left anchor)
        { "H", function() resize("h", 10) end, { desc = "← shrink (large)" } },
        { "J", function() resize("j", 10) end, { desc = "↓ grow (large)" } },
        { "K", function() resize("k", 10) end, { desc = "↑ shrink (large)" } },
        { "L", function() resize("l", 10) end, { desc = "→ grow (large)" } },
        -- Bottom-right anchor
        { "<C-h>", function() resize("h", 3,  require("winmove").ResizeAnchor.BottomRight) end, { desc = "← (BR anchor)" } },
        { "<C-j>", function() resize("j", 3,  require("winmove").ResizeAnchor.BottomRight) end, { desc = "↓ (BR anchor)" } },
        { "<C-k>", function() resize("k", 3,  require("winmove").ResizeAnchor.BottomRight) end, { desc = "↑ (BR anchor)" } },
        { "<C-l>", function() resize("l", 3,  require("winmove").ResizeAnchor.BottomRight) end, { desc = "→ (BR anchor)" } },
        -- Exit
        { "q",     nil, { exit = true, nowait = true, desc = "Exit" } },
        { "<Esc>", nil, { exit = true, nowait = true, desc = "Exit" } },
      },
    })

    -- ── WhichKey group ──────────────────────────────────────────────────────────
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>w",  group = "Window management" },
        { "<leader>wm", desc  = "Window: MOVE mode (Hydra)" },
        { "<leader>ws", desc  = "Window: SWAP mode (Hydra)" },
        { "<leader>wr", desc  = "Window: RESIZE mode (Hydra)" },
      })
    end
  end,
}
