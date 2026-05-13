-- ~/.config/nvim/lua/plugins/trouble.lua
-- trouble.nvim — pretty list UI for diagnostics, LSP results, and quickfix.
--
-- How to use Trouble:
--   \xx  open document diagnostics  (errors/warnings in this file)
--   \xX  open workspace diagnostics (errors/warnings across the project)
--   \xq  open quickfix list in Trouble's UI
--   \xs  open LSP symbols outline (right panel)
--   \xl  open LSP definitions / references (right panel)
--   ]x / [x  jump to next/prev item in whatever Trouble list is open
--
-- Quickfix integration:
--   Any tool that populates the quickfix list (grep, LSP, make, etc.)
--   can be viewed beautifully with \xq instead of the raw :copen.
--   vim-qf (\qq) still works for toggling the native qf window directly.
--
-- Trouble opens at the bottom by default and auto-previews the item
-- under the cursor in your main window. Press <CR> to jump to it.
-- Press q or <Esc> to close.

return {
  "folke/trouble.nvim",
  commit = "bd67efe408d4816e25e8491cc5ad4088e708a69a",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Trouble",
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
      desc = "Document diagnostics" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle<CR>",
      desc = "Workspace diagnostics" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<CR>",
      desc = "Quickfix in Trouble" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<CR>",
      desc = "Loclist in Trouble" },
    { "<leader>xs", "<cmd>Trouble symbols toggle focus=false win.position=right<CR>",
      desc = "Symbols outline" },
    { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>",
      desc = "LSP definitions & refs" },

    -- Next/prev — works inside Trouble OR falls back to native qf
    { "]x", function()
        if require("trouble").is_open() then
          require("trouble").next({ skip_groups = true, jump = true })
        else
          local ok, _ = pcall(vim.cmd, "cnext")
          if not ok then vim.notify("No more quickfix items", vim.log.levels.INFO) end
        end
      end, desc = "Next trouble / quickfix item" },
    { "[x", function()
        if require("trouble").is_open() then
          require("trouble").prev({ skip_groups = true, jump = true })
        else
          local ok, _ = pcall(vim.cmd, "cprev")
          if not ok then vim.notify("No more quickfix items", vim.log.levels.INFO) end
        end
      end, desc = "Prev trouble / quickfix item" },
  },

  opts = {
    -- ── Window ──────────────────────────────────────────────────────────────
    win = {
      position = "bottom",
      size     = 14,
    },

    -- ── Behaviour ───────────────────────────────────────────────────────────
    auto_close    = false,  -- keep open until you explicitly close with q
    auto_preview  = true,   -- preview item under cursor in background
    auto_refresh  = true,
    focus         = false,  -- don't steal focus from your editing window

    -- Inside the Trouble window:
    --   <CR>  jump to item
    --   o     open in background (stay in Trouble)
    --   q     close Trouble
    --   r     refresh

    -- ── Visual ──────────────────────────────────────────────────────────────
    use_diagnostic_signs = true,

    modes = {
      -- Document diagnostics: show errors first, then warnings
      diagnostics = {
        sort = {
          { key = "severity", order = "asc" },
          { key = "filename", order = "asc" },
          { key = "pos",      order = "asc" },
        },
      },
      -- Symbols panel: persistent right-side outline, doesn't steal focus
      symbols = {
        focus = false,
        win = { position = "right", size = 36 },
      },
      -- LSP refs panel: right side
      lsp = {
        focus = false,
        win = { position = "right", size = 48 },
      },
    },
  },

  config = function(_, opts)
    require("trouble").setup(opts)

    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>x",  group = "Diagnostics / Trouble" },
        { "<leader>xx", desc  = "Document diagnostics" },
        { "<leader>xX", desc  = "Workspace diagnostics" },
        { "<leader>xq", desc  = "Quickfix in Trouble" },
        { "<leader>xL", desc  = "Loclist in Trouble" },
        { "<leader>xs", desc  = "Symbols outline (right)" },
        { "<leader>xl", desc  = "LSP defs & refs (right)" },
        { "]x",         desc  = "Next trouble/qf item" },
        { "[x",         desc  = "Prev trouble/qf item" },
      })
    end
  end,
}
