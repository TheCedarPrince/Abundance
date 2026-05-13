-- Lua formatter via conform.nvim + stylua.
-- Mirrors the structure of julia.lua — conform handles formatting only,
-- no LSP involvement here.
--
-- Install stylua via cargo or your package manager:
--   cargo install stylua
--   brew install stylua
--   pacman -S stylua
return {
  {
    "stevearc/conform.nvim",
    commit = "dca1a190aa85f9065979ef35802fb77131911106",
    ft = "lua",
    opts = {
      formatters = {
        stylua = {
          command = "stylua",
          args = {
            "--search-parent-directories", -- picks up stylua.toml if present
            "--stdin-filepath",
            "$FILENAME",                   -- gives stylua context for editorconfig
            "-",                           -- read from stdin
          },
          stdin = true,
        },
      },
      formatters_by_ft = {
        lua = { "stylua" },
      },
      default_format_opts = {
        timeout_ms = 3000, -- stylua is fast; no precompilation needed
      },
    },
  },
}
