-- ~/.config/nvim/lua/plugins/trouble.lua
-- trouble.nvim — Pretty list UI for diagnostics, LSP results, and quickfix.
-- Scope: LSP diagnostics + quickfix. vim-qf handles qf keybinding polish.
-- \x is the group prefix ("diagnostics / trouble").

return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Trouble",
  keys = {
    -- Document diagnostics
    { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>",  desc = "Document diagnostics" },
    -- Workspace diagnostics
    { "<leader>xX", "<cmd>Trouble diagnostics toggle<CR>",               desc = "Workspace diagnostics" },
    -- LSP: symbols outline for current buffer
    { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>",       desc = "Symbols (document)" },
    -- LSP references / definitions / implementations
    { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>", desc = "LSP definitions & refs" },
    -- Quickfix in Trouble's UI
    { "<leader>xq", "<cmd>Trouble qflist toggle<CR>",                    desc = "Quickfix (Trouble)" },
    -- Location list in Trouble's UI
    { "<leader>xL", "<cmd>Trouble loclist toggle<CR>",                   desc = "Location list (Trouble)" },
    -- Previous / next trouble item (wraps)
    { "[x", function()
        if require("trouble").is_open() then
          require("trouble").prev({ skip_groups = true, jump = true })
        else
          vim.cmd("cprev")
        end
      end, desc = "Previous trouble / qf item" },
    { "]x", function()
        if require("trouble").is_open() then
          require("trouble").next({ skip_groups = true, jump = true })
        else
          vim.cmd("cnext")
        end
      end, desc = "Next trouble / qf item" },
  },

  opts = {
    modes = {
      -- Default diagnostic view: document-scoped, right side panel
      diagnostics = {
        auto_close   = false,
        auto_preview = true,
        focus        = false,
        win = {
          position = "bottom",
          size     = 12,
        },
        filter = { severity = vim.diagnostic.severity.WARN },
        sort = {
          { key = "severity", order = "asc" },
          { key = "filename", order = "asc" },
          { key = "pos",      order = "asc" },
        },
      },

      -- Symbols panel: persistent right-side outline
      symbols = {
        focus = false,
        win = {
          position = "right",
          size     = 36,
        },
      },

      -- LSP references panel
      lsp = {
        focus = false,
        win = {
          position = "right",
          size     = 48,
        },
      },
    },

    -- Visual polish
    use_diagnostic_signs = true,  -- use your existing diagnostic signs
    icons = {
      indent = {
        fold_open   = " ",
        fold_closed = " ",
      },
      folder_closed = "",
      folder_open   = "",
    },
  },

  config = function(_, opts)
    require("trouble").setup(opts)

    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>x", group = "Diagnostics / Trouble" },
      })
    end
  end,
}
