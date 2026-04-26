-- ~/.config/nvim/lua/plugins/julia.lua
--
-- All Julia-specific tooling in one place. Load order matters:
--   1. conform.nvim  — Runic.jl formatter (no LSP involvement)
--   2. julia-lsp     — julials (LanguageServer.jl) via native vim.lsp API
--
-- Completion (nvim-cmp + LuaSnip) lives in autocomplete.lua — it is
-- editor-global and not Julia-specific.
--   # LSP environment
--   julia --project=~/.julia/environments/nvim-lspconfig \
--     -e 'using Pkg; Pkg.add(["LanguageServer","SymbolServer","Revise"])'
--
--   # Sysimage (cuts cold-start from ~30s to ~5s)
--   julia --project=~/.julia/environments/nvim-lspconfig -e '
--     using PackageCompiler
--     create_sysimage([:LanguageServer, :StaticLint, :CSTParser, :JuliaFormatter];
--       sysimage_path = expanduser(
--         "~/.julia/environments/nvim-lspconfig/languageserver.so"),
--       project = expanduser("~/.julia/environments/nvim-lspconfig"))'
--
--   # Runic formatter (isolated in its own shared environment)
--   julia --project=@runic \
--     -e 'using Pkg; Pkg.add(url="https://github.com/fredrikekre/Runic.jl")'
--
-- Updating the sysimage (after upgrading Julia or LanguageServer.jl):
--   julia --project=~/.julia/environments/nvim-lspconfig \
--     -e 'using Pkg; Pkg.update()'
--   Then re-run the create_sysimage call above.

return {

  -- ── 1. Formatter: Runic.jl ───────────────────────────────────────────
  -- conform.nvim is the standard neovim formatter plugin. We use it solely
  -- to run Runic.jl, which is opinionated and has no configuration (like
  -- gofmt). Runic reads from stdin and writes to stdout, so conform pipes
  -- the buffer through it without touching the file directly.
  --
  -- Keybind: <leader>lf (defined in LspAttach autocmd below)
  -- First run is slow (~10-30s) due to Julia precompilation. Subsequent
  -- runs are fast. The timeout_ms is set high to accommodate this.
  {
    "stevearc/conform.nvim",
    ft = "julia",
    opts = {
      formatters = {
        runic = (function()
          -- Use a Runic sysimage if one exists at this path.
          -- Build it with:
          --   julia --project=@runic -e '
          --     using PackageCompiler
          --     create_sysimage([:Runic];
          --       sysimage_path=expanduser("~/.julia/environments/runic/runic.so"),
          --       project=expanduser("~/.julia/environments/runic"))'
          local runic_sysimage = vim.fn.expand(
            "~/.julia/environments/runic/runic.so"
          )
          local args = {
            "--project=@runic",
            "--startup-file=no",  -- skip ~/.julia/config/startup.jl
          }
          if vim.fn.filereadable(runic_sysimage) == 1 then
            table.insert(args, "--sysimage=" .. runic_sysimage)
          end
          table.insert(args, "-e")
          table.insert(args, "using Runic; exit(Runic.main(ARGS))")
          return {
            command = "julia",
            args    = args,
            stdin   = true,  -- pipe buffer contents, don't write a temp file
          }
        end)(),
      },
      formatters_by_ft = {
        julia = { "runic" },
      },
      default_format_opts = {
        timeout_ms = 10000,  -- accommodate first-run precompilation
      },
    },
  },

  -- ── 2. Julia LSP: LanguageServer.jl ─────────────────────────────────
  -- Uses the native vim.lsp.config / vim.lsp.enable API (Neovim 0.11+)
  -- instead of the deprecated require('lspconfig') framework. This
  -- eliminates the deprecation warning and the lspconfig overhead entirely.
  --
  -- The virtual plugin entry (dir + name) is still used so lazy.nvim loads
  -- this block independently on ft=julia without needing a real plugin URL.
  {
    "julia-lsp",
    dir  = vim.fn.stdpath("config") .. "/lua/plugins",
    name = "julia-lsp",
    ft   = "julia",
    dependencies = {
      "folke/which-key.nvim",
    },
    config = function()

      -- Diagnostic display settings. Applied globally but only meaningful
      -- when an LSP is active.
      --   update_in_insert=false  — don't re-lint mid-keystroke (less noise)
      --   severity_sort=true      — errors above warnings in the float
      --   virtual_text min=WARN   — hints stay gutter-only, not inline
      --   source=true             — float shows which server raised the error
      vim.diagnostic.config({
        underline        = true,
        update_in_insert = false,
        severity_sort    = true,
        float = {
          border = "rounded",
          source = true,
          header = "",
          prefix = "",
        },
        virtual_text = {
          spacing  = 4,
          prefix   = "●",
          severity = { min = vim.diagnostic.severity.WARN },
        },
      })

      local lsp_env  = vim.fn.expand("~/.julia/environments/nvim-lspconfig")
      local sysimage = lsp_env .. "/languageserver.so"  -- .dylib on macOS

      -- Build the cmd table. Both flags are always present:
      --   --project  tells Julia where LanguageServer.jl lives
      --   --sysimage uses the precompiled image for fast startup (~5s vs ~30s)
      -- The Julia script (last element) is rewritten per-workspace by
      -- on_new_config below, replacing pwd() with the actual root path.
      local cmd = {
        "julia",
        "--startup-file=no",  -- skip ~/.julia/config/startup.jl
        "--history-file=no",  -- not a REPL session
        "--project=" .. lsp_env,
      }
      if vim.fn.filereadable(sysimage) == 1 then
        table.insert(cmd, "--sysimage=" .. sysimage)
      end
      table.insert(cmd, "-e")
      table.insert(cmd, [[
        using LanguageServer, Revise
        import SymbolServer
        env_path = pwd()
        server = LanguageServer.LanguageServerInstance(
          stdin, stdout, env_path, ""
        )
        server.runlinter = true
        run(server)
      ]])

      -- vim.lsp.config registers the server definition globally.
      -- root_markers replaces lspconfig's root_dir: neovim walks up from
      -- the current file and uses the first directory containing one of
      -- these as the workspace root.
      vim.lsp.config("julials", {
        cmd          = cmd,
        filetypes    = { "julia" },
        root_markers = { "Project.toml", "Manifest.toml", ".git" },
        -- on_new_config rewrites the Julia script in cmd to hardcode the
        -- resolved workspace root as env_path. This is necessary because
        -- --project sets Base.active_project() to the nvim-lspconfig LSP
        -- environment, not your project — so pwd() would be wrong.
        on_new_config = function(new_config, new_root_dir)
          new_config.cmd[#new_config.cmd] = string.format([[
            using LanguageServer, Revise
            import SymbolServer
            env_path = %q
            server = LanguageServer.LanguageServerInstance(
              stdin, stdout, env_path, ""
            )
            server.runlinter = true
            run(server)
          ]], new_root_dir)
        end,
        settings = {
          julia = {
            -- Inlay hints: variable types inline, parameter names off
            -- (too noisy). Toggle hints with <leader>lh.
            inlayHints = {
              static = {
                variableTypes  = { enabled = true  },
                parameterNames = { enabled = false },
              },
            },
            -- StaticLint.jl linter settings:
            --   missingrefs="all"  — warn on all unresolved references
            --   iter               — warn on iteration variable shadowing
            --   lazy               — warn on lazy evaluation issues
            --   modname            — warn on module name conflicts
            lint = {
              run         = true,
              missingrefs = "all",
              iter        = true,
              lazy        = true,
              modname     = true,
            },
            -- "qualify" shows fully-qualified names in completions
            -- (e.g. Base.sort instead of just sort) when ambiguous.
            completionmode = "qualify",
          },
        },
      })

      -- Activate julials for julia filetypes.
      vim.lsp.enable("julials")

      -- LspAttach fires once per buffer when julials connects.
      -- Scoped to *.jl so it doesn't affect other LSPs.
      -- All keymaps are buffer-local so they only appear in Julia files.
      vim.api.nvim_create_autocmd("LspAttach", {
        pattern  = "*.jl",
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "julials" then return end

          local bufnr = args.buf

          -- Register <leader>l as the LSP group in which-key.
          -- buffer=0 scopes it to this Julia buffer only.
          require("which-key").add({
            { "<leader>l", group = "LSP", icon = "", buffer = 0 },
          })

          -- Enable inlay hints. Toggle with <leader>lh.
          -- Requires Neovim 0.10+.
          if vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          end

          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, {
              buffer = bufnr,
              desc   = "LSP: " .. desc,
            })
          end

          -- Navigation
          map("<leader>ld", vim.lsp.buf.definition,       "Go to Definition")
          map("<leader>lD", vim.lsp.buf.declaration,      "Go to Declaration")
          map("<leader>lr", vim.lsp.buf.references,       "References")
          map("<leader>li", vim.lsp.buf.implementation,   "Implementation")
          map("<leader>ls", vim.lsp.buf.document_symbol,  "Document Symbols")
          map("<leader>lS", vim.lsp.buf.workspace_symbol, "Workspace Symbols")

          -- Editing
          map("<leader>lR", vim.lsp.buf.rename,           "Rename Symbol")
          map("<leader>la", vim.lsp.buf.code_action,      "Code Action")

          -- Formatting via conform.nvim → Runic.jl (not the LSP formatter).
          -- timeout_ms matches the conform default_format_opts above.
          map("<leader>lf", function()
            require("conform").format({ bufnr = bufnr, timeout_ms = 10000 })
          end,                                            "Format (Runic)")

          -- K is the vim standard for "help on word under cursor"
          map("K",          vim.lsp.buf.hover,            "Hover Docs")
          map("<leader>lk", vim.lsp.buf.signature_help,   "Signature Help")

          -- Diagnostics
          map("<leader>le", vim.diagnostic.open_float,    "Line Diagnostics")
          map("[d",         vim.diagnostic.goto_prev,     "Prev Diagnostic")
          map("]d",         vim.diagnostic.goto_next,     "Next Diagnostic")

          -- LSP utilities (native replacements for :LspInfo/:LspLog/:LspRestart)
          map("<leader>lI", function()
            vim.print(vim.lsp.get_clients({ bufnr = bufnr }))
          end,                                            "LSP Info")
          map("<leader>lL", function()
            vim.cmd.edit(vim.lsp.get_log_path())
          end,                                            "LSP Log")
          map("<leader>lR", function()
            vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = bufnr }))
            vim.defer_fn(function() vim.cmd.edit() end, 500)
          end,                                            "Restart LSP")

          -- Toggle inlay hints without restarting the server.
          map("<leader>lh", function()
            if vim.lsp.inlay_hint then
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end
          end,                                            "Toggle Inlay Hints")
        end,
      })
    end,
  },
}
