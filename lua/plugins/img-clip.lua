-- ~/.config/nvim/lua/plugins/img-clip.lua
-- img-clip.nvim — Paste clipboard images directly into buffers.
--
-- LaTeX:  images go to ~/Knowledgebase/TEXZK/assets/
--         filename derived from the current .tex filename, e.g.
--         aaa-0001.tex → aaa-0001-1.png, aaa-0001-2.png …
--
-- Julia:  images go to ./assets/ (or /docs/src/assets/ if that exists)
--
-- Trigger: \ip in normal mode (image paste group under \i)

return {
  "HakonHarnes/img-clip.nvim",
  commit = "b6ddfb97b5600d99afe3452d707444afda658aca",
  event = "BufEnter",
  keys = {
    { "<leader>ip", "<cmd>PasteImage<CR>", desc = "Paste image from clipboard" },
  },

  opts = {
    -- ── Global defaults ────────────────────────────────────────────────────────
    default = {
      debug              = false,
      insert_mode_after_paste = false, -- stay in normal mode after paste
      prompt_for_file_name = false,    -- auto-generate; no prompt

      -- Show a drag-and-drop hint in the embed path so you know what was inserted
      show_dir_path_in_embed = false,
    },

    -- ── Filetype overrides ─────────────────────────────────────────────────────
    filetypes = {

      -- ── LaTeX ────────────────────────────────────────────────────────────────
      tex = {
        prompt_for_file_name = false,

        -- Absolute asset directory for the TEXZK knowledge base
        dir_path = vim.fn.expand("~/Knowledgebase/TEXZK/assets"),

        -- Derive filename from the current tex file stem + sequential index.
        -- e.g. editing aaa-0001.tex produces aaa-0001-1.png, aaa-0001-2.png …
        file_name = function()
          local stem = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
          -- Count existing images with this stem to find the next index
          local pattern = vim.fn.expand("~/Knowledgebase/TEXZK/assets/") .. stem .. "-*.png"
          local existing = vim.fn.glob(pattern, false, true)
          local idx = #existing + 1
          return stem .. "-" .. idx
        end,

        -- Standard LaTeX figure block
        template = [[
\begin{figure}[htbp]
  \centering
  \includegraphics[width=0.8\linewidth]{$FILE_PATH}
  \caption{$CURSOR}
  \label{fig:$LABEL}
\end{figure}]],

        -- $LABEL gets the filename stem (minus extension) for \label
        label = function()
          local stem = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
          local pattern = vim.fn.expand("~/Knowledgebase/TEXZK/assets/") .. stem .. "-*.png"
          local existing = vim.fn.glob(pattern, false, true)
          return stem .. "-" .. (#existing + 1)
        end,
      },

      -- ── Julia / Markdown (Documenter.jl) ────────────────────────────────────
      julia = {
        prompt_for_file_name = false,

        -- Prefer /docs/src/assets if it exists, otherwise ./assets
        dir_path = function()
          local docs_assets = vim.fn.getcwd() .. "/docs/src/assets"
          if vim.fn.isdirectory(docs_assets) == 1 then
            return docs_assets
          end
          return vim.fn.getcwd() .. "/assets"
        end,

        file_name = function()
          local stem = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
          local dir = (function()
            local docs_assets = vim.fn.getcwd() .. "/docs/src/assets"
            return vim.fn.isdirectory(docs_assets) == 1
              and docs_assets
              or (vim.fn.getcwd() .. "/assets")
          end)()
          local pattern = dir .. "/" .. stem .. "-*.png"
          local existing = vim.fn.glob(pattern, false, true)
          return stem .. "-" .. (#existing + 1)
        end,

        -- Documenter.jl / Literate.jl image markdown syntax
        template = "![$CURSOR]($FILE_PATH)",
      },

      -- ── Plain Markdown (fallback) ────────────────────────────────────────────
      markdown = {
        prompt_for_file_name = false,
        dir_path = "assets",
        file_name = function()
          local stem = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
          local pattern = "assets/" .. stem .. "-*.png"
          local existing = vim.fn.glob(pattern, false, true)
          return stem .. "-" .. (#existing + 1)
        end,
        template = "![$CURSOR]($FILE_PATH)",
      },
    },
  },

  config = function(_, opts)
    require("img-clip").setup(opts)

    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>i",  group = "Image" },
        { "<leader>ip", desc  = "Paste image from clipboard" },
      })
    end
  end,
}
