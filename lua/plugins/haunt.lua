-- ~/.config/nvim/lua/plugins/haunt.lua
-- haunt.nvim — Ghost-text bookmarks with annotations.
-- Bookmarks are git-branch-scoped by default.
-- Picker: fzf-lua.
-- WhichKey group: \h (haunt)

return {
  "TheNoeTrevino/haunt.nvim",
  event = "VeryLazy",
  dependencies = { "ibhagwan/fzf-lua" },

  opts = {
    -- Visual style
    sign         = "󱙝",
    sign_hl      = "DiagnosticInfo",
    virt_text_hl = "HauntAnnotation",  -- links to DiagnosticVirtualTextHint
    annotation_prefix = " 󰆉 ",
    annotation_suffix = "",
    virt_text_pos = "eol",

    -- Scope bookmarks per git branch (highly recommended)
    per_branch_bookmarks = true,

    -- Use fzf-lua as the picker
    picker = "fzf",

    picker_keys = {
      delete          = { key = "d", mode = { "n" } },
      edit_annotation = { key = "a", mode = { "n" } },
    },
  },

  config = function(_, opts)
    require("haunt").setup(opts)

    local haunt        = require("haunt.api")
    local haunt_picker = require("haunt.picker")
    local map          = vim.keymap.set
    local silent       = { silent = true }

    -- ── Annotations ────────────────────────────────────────────────────────────
    map("n", "<leader>ha", function() haunt.annotate() end,
      vim.tbl_extend("force", silent, { desc = "Annotate / edit annotation" }))

    map("n", "<leader>ht", function() haunt.toggle_annotation() end,
      vim.tbl_extend("force", silent, { desc = "Toggle annotation visibility" }))

    map("n", "<leader>hT", function() haunt.toggle_all_lines() end,
      vim.tbl_extend("force", silent, { desc = "Toggle ALL annotations" }))

    map("n", "<leader>hd", function() haunt.delete() end,
      vim.tbl_extend("force", silent, { desc = "Delete bookmark on this line" }))

    map("n", "<leader>hD", function() haunt.clear_all() end,
      vim.tbl_extend("force", silent, { desc = "Clear ALL bookmarks" }))

    -- ── Navigation ─────────────────────────────────────────────────────────────
    map("n", "<leader>hn", function() haunt.next() end,
      vim.tbl_extend("force", silent, { desc = "Next bookmark" }))

    map("n", "<leader>hp", function() haunt.prev() end,
      vim.tbl_extend("force", silent, { desc = "Previous bookmark" }))

    -- Also wire to ]h / [h for vim-style navigation consistency
    map("n", "]h", function() haunt.next() end,
      vim.tbl_extend("force", silent, { desc = "Next haunt bookmark" }))
    map("n", "[h", function() haunt.prev() end,
      vim.tbl_extend("force", silent, { desc = "Prev haunt bookmark" }))

    -- ── Picker ─────────────────────────────────────────────────────────────────
    map("n", "<leader>hl", function() haunt_picker.show() end,
      vim.tbl_extend("force", silent, { desc = "List bookmarks (fzf)" }))

    -- ── Quickfix integration ────────────────────────────────────────────────────
    map("n", "<leader>hq", function() haunt.to_quickfix() end,
      vim.tbl_extend("force", silent, { desc = "Send bookmarks → quickfix (all)" }))

    map("n", "<leader>hQ", function() haunt.to_quickfix({ current_buffer = true }) end,
      vim.tbl_extend("force", silent, { desc = "Send bookmarks → quickfix (buffer)" }))

    -- ── Clipboard yank ─────────────────────────────────────────────────────────
    map("n", "<leader>hy", function() haunt.yank_locations() end,
      vim.tbl_extend("force", silent, { desc = "Yank bookmark locations (all)" }))

    map("n", "<leader>hY", function() haunt.yank_locations({ current_buffer = true }) end,
      vim.tbl_extend("force", silent, { desc = "Yank bookmark locations (buffer)" }))

    -- ── WhichKey group ──────────────────────────────────────────────────────────
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>h",  group = "Haunt bookmarks" },
        { "]h",         desc  = "Next haunt bookmark" },
        { "[h",         desc  = "Prev haunt bookmark" },
      })
    end
  end,
}
