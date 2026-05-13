-- ~/.config/nvim/lua/plugins/tabby.lua
-- nanozuki/tabby.nvim — tab-centric tabline with vim-ctrlspace label integration.
--
-- Philosophy: tabs are workspaces (like ctrlspace projects), not buffers.
-- Each tab shows its ctrlspace label if set, otherwise its number.
-- The active tab expands to show its open windows on the right side.
--
-- ── How to use ────────────────────────────────────────────────────────────
--   Rename a tab:     :Tabby rename_tab <name>   (or :TabRename in older API)
--   Jump to a tab:    :Tabby jump_to_tab          (shows single-key labels)
--   Pick a window:    :Tabby pick_window
--   Native tab ops:   gt / gT / <number>gt still work as normal
--
-- ── ctrlspace integration ─────────────────────────────────────────────────
--   When vim-ctrlspace sets a tab label (via its workspace feature), tabby
--   reads it with ctrlspace#util#Gettabvar and shows it in the tabline.
--   If no label is set, falls back to the tab number.
--   This makes the tabline read as: "1: API  2: Frontend  3: Tests"

return {
  "nanozuki/tabby.nvim",
  commit = "3c130e1fcb598ce39a9c292847e32d7c3987cf11",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },

  config = function()
    local theme = {
      fill        = "TabLineFill",
      head        = "TabLine",
      current_tab = "TabLineSel",
      tab         = "TabLine",
      win         = "TabLine",
      tail        = "TabLine",
    }

    -- ── CtrlSpace label helper ─────────────────────────────────────────────
    -- Reads the CtrlSpaceLabel tab variable set by vim-ctrlspace's workspace
    -- feature. Returns "<number>: <label>" when a label exists, or just the
    -- tab number when not. Fails gracefully if ctrlspace is not loaded.
    local function get_tab_label(tab_number)
      local ok, label = pcall(function()
        return vim.api.nvim_eval(
          "ctrlspace#util#Gettabvar(" .. tab_number .. ", 'CtrlSpaceLabel')"
        )
      end)
      if ok and label and label ~= "" then
        return tab_number .. ": " .. label
      end
      return tostring(tab_number)
    end

    -- ── Tabline layout ─────────────────────────────────────────────────────
    -- Left:  powerline-style tab list with ctrlspace labels.
    --        Active tab is highlighted with TabLineSel.
    -- Right: windows open in the active tab (filename only, no path noise).
    -- Jump mode: tab.jump_key() replaces tab number while active.
    require("tabby").setup({
      line = function(line)
        return {
          -- Head accent
          {
            { "  ", hl = theme.head },
            line.sep("", theme.head, theme.fill),
          },

          -- Tab list
          line.tabs().foreach(function(tab)
            local hl     = tab.is_current() and theme.current_tab or theme.tab
            local number = tab.number()
            -- Show jump key when in jump mode, otherwise ctrlspace label
            local label  = tab.in_jump_mode()
              and tab.jump_key()
              or get_tab_label(number)

            return {
              line.sep("", hl, theme.fill),
              tab.is_current() and "" or "󰆣",
              " " .. label .. " ",
              tab.close_btn(""),
              line.sep("", hl, theme.fill),
              hl     = hl,
              margin = " ",
            }
          end),

          -- Push windows to the right
          line.spacer(),

          -- Windows in the active tab
          line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
            return {
              line.sep("", theme.win, theme.fill),
              win.is_current() and "" or "",
              " ",
              win.buf_name(),
              " ",
              line.sep("", theme.win, theme.fill),
              hl     = theme.win,
              margin = " ",
            }
          end),

          -- Tail accent
          {
            line.sep("", theme.tail, theme.fill),
            { "  ", hl = theme.tail },
          },

          hl = theme.fill,
        }
      end,

      option = {
        tab_name = {
          -- When a tab has no ctrlspace label and no renamed name,
          -- fall back to the focused window's filename
          name_fallback = function(tabid)
            local wins  = vim.api.nvim_tabpage_list_wins(tabid)
            local top   = vim.api.nvim_tabpage_get_win(tabid)
            local bufid = vim.api.nvim_win_get_buf(
              vim.tbl_contains(wins, top) and top or wins[1]
            )
            return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufid), ":t")
          end,
        },
        buf_name = {
          mode = "unique", -- show shortest unique path component
        },
      },
    })

    -- ── Keymaps ───────────────────────────────────────────────────────────
    local map = vim.keymap.set
    local s   = { silent = true }
    local function o(desc) return vim.tbl_extend("force", s, { desc = desc }) end

    -- Tab navigation (native vim operations, just made explicit)
    map("n", "<leader><tab>n", "<cmd>tabnew<CR>",   o("New tab"))
    map("n", "<leader><tab>c", "<cmd>tabclose<CR>", o("Close tab"))
    map("n", "<leader><tab>]", "<cmd>tabnext<CR>",  o("Next tab"))
    map("n", "<leader><tab>[", "<cmd>tabprev<CR>",  o("Prev tab"))

    -- Tabby commands
    map("n", "<leader><tab>r", "<cmd>Tabby rename_tab<CR>",  o("Rename tab"))
    map("n", "<leader><tab>j", "<cmd>Tabby jump_to_tab<CR>", o("Jump to tab (label mode)"))
    map("n", "<leader><tab>w", "<cmd>Tabby pick_window<CR>", o("Pick window"))

    -- WhichKey group
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader><tab>",  group = "Tabs" },
        { "<leader><tab>n", desc  = "New tab" },
        { "<leader><tab>c", desc  = "Close tab" },
        { "<leader><tab>]", desc  = "Next tab" },
        { "<leader><tab>[", desc  = "Prev tab" },
        { "<leader><tab>r", desc  = "Rename tab" },
        { "<leader><tab>j", desc  = "Jump to tab" },
        { "<leader><tab>w", desc  = "Pick window" },
      })
    end
  end,
}
