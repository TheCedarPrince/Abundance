return {
  dir = vim.fn.stdpath("config"),   -- points to ~/.config/nvim itself
  name = "latex-zk",
  ft = "tex",                        -- only loads when editing a .tex file
  dependencies = {
    "ibhagwan/fzf-lua",
    "folke/which-key.nvim",          -- optional, safe to remove if you don't use it
  },
  config = function()
    require("custom.latex-zk").setup({
      -- All options below are already the defaults; only include what you want to change.
      notes_dir       = vim.fn.expand("~/Knowledgebase/TEXZK"),
      filename_prefix = "aaa",
      input_command   = "\\subinput",
      keymaps = {
        link    = "<leader>zl",
        extract = "<leader>ze",
      },
      whichkey_label = "Zettelkasten",
    })
  end,
}
