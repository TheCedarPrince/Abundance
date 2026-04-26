return {
  "jmbuhr/otter.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  ft = { "quarto", "markdown", "rmd" },
  opts = {
    lsp = {
      -- Hover doc keymaps are forwarded to the embedded language LSP.
      -- hover = { border = "rounded" },
      diagnostic_update_events = { "BufWritePost", "InsertLeave", "TextChanged" },
    },
    buffers = {
      -- Keep otter buffers hidden so fzf-lua doesn't surface them.
      set_filetype = true,
      write_to_disk = false,
    },
    strip_wrapping_quote_characters = { "'", '"', "`" },
  },
  config = function(_, opts)
    local otter = require("otter")
    otter.setup(opts)

    -- Activate otter automatically for supported filetypes.
    -- Languages listed here must have an LSP server already attached
    -- (e.g. pyright, lua_ls, ts_ls) via your built-in LSP config.
    local function activate()
      otter.activate(
        { "python", "r", "lua", "bash", "javascript", "typescript", "julia" },
        true,   -- completion
        true,   -- diagnostics
        nil     -- tsquery override (nil = use otter default)
      )
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "quarto", "markdown", "rmd" },
      callback = activate,
      desc = "Activate otter embedded LSP",
    })

    -- which-key registrations (requires which-key to be loaded first)
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        -- Buffer-local, only active in quarto/markdown buffers
        { "o", group = "otter", buffer = true },
        {
          "oa",
	  function() otter.activate({ "python", "r", "lua", "bash", "julia" }, true, true) end,
          desc = "Activate otter LSP",
          buffer = true,
        },
        {
          "od",
          function() otter.deactivate() end,
          desc = "Deactivate otter LSP",
          buffer = true,
        },
        -- Otter-aware go-to: jumps into the virtual embedded buffer
        {
          "og",
          function() otter.ask_definition() end,
          desc = "Go to definition (otter)",
          buffer = true,
        },
        {
          "or",
          function() otter.ask_references() end,
          desc = "References (otter)",
          buffer = true,
        },
        {
          "oh",
          function() otter.ask_hover() end,
          desc = "Hover doc (otter)",
          buffer = true,
        },
        {
          "oR",
          function() otter.ask_rename() end,
          desc = "Rename symbol (otter)",
          buffer = true,
        },
        {
          "of",
          function() otter.ask_format() end,
          desc = "Format chunk (otter)",
          buffer = true,
        },
        {
          "oq",
          function() otter.ask_type_definition() end,
          desc = "Type definition (otter)",
          buffer = true,
        },
      })
    end
  end,
}

