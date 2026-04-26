return {
  "quarto-dev/quarto-nvim",
  dependencies = {
    "jmbuhr/otter.nvim",
    "nvim-treesitter/nvim-treesitter",
    "jpalardy/vim-slime",
  },
  ft = { "quarto", "markdown" },
  config = function()
    local quarto = require("quarto")

    quarto.setup({
      debug = false,
      closePreviewOnExit = true,

      lspFeatures = {
        enabled = true,
        languages = { "python", "r", "lua", "bash", "javascript", "typescript", "julia" },
        chunks = "all",
        diagnostics = {
          enabled = true,
          triggers = { "BufWritePost", "InsertLeave", "TextChanged" },
        },
        completion = {
          enabled = true,
        },
      },

      codeRunner = {
        enabled = true,
        default_method = "slime",
        never_run = { "yaml" },
      },
    })

    -- ── conform.nvim formatting ──────────────────────────────────────────
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "quarto", "markdown" },
      callback = function()
        -- <leader>qF  →  format whole buffer via conform
        vim.keymap.set("n", "<leader>qF", function()
          require("conform").format({
            bufnr = 0,
            async = true,
            lsp_fallback = true,
          })
        end, { buffer = true, desc = "Format buffer (conform)" })

        -- <leader>qfc  →  format only the current chunk's content
        vim.keymap.set("n", "<leader>qfc", function()
          local cursor = vim.api.nvim_win_get_cursor(0)
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local start_l, end_l, lang

          for i = cursor[1], 1, -1 do
            local m = lines[i]:match("^```{(%a+)")
            if m then start_l = i; lang = m; break end
          end
          for i = cursor[1], #lines do
            if lines[i]:match("^```%s*$") and i > (start_l or 0) then
              end_l = i; break
            end
          end

          if not (start_l and end_l and lang) then
            vim.notify("Not inside a code chunk", vim.log.levels.WARN)
            return
          end

          local chunk_lines = vim.list_slice(lines, start_l + 1, end_l - 1)
          local tmp = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_lines(tmp, 0, -1, false, chunk_lines)
          vim.bo[tmp].filetype = lang

          require("conform").format({
            bufnr = tmp,
            async = false,
            lsp_fallback = false,
          })

          local formatted = vim.api.nvim_buf_get_lines(tmp, 0, -1, false)
          vim.api.nvim_buf_delete(tmp, { force = true })
          vim.api.nvim_buf_set_lines(0, start_l, end_l - 1, false, formatted)
          vim.notify("Chunk formatted (" .. lang .. ")", vim.log.levels.INFO)
        end, { buffer = true, desc = "Format current chunk (conform)" })
      end,
    })

    -- ── fzf-lua integration ──────────────────────────────────────────────
    local function fzf_quarto_headings()
      local ok, fzf = pcall(require, "fzf-lua")
      if not ok then return end
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local items = {}
      for i, line in ipairs(lines) do
        if line:match("^#+%s") or line:match("^```{") then
          table.insert(items, string.format("%4d\t%s", i, line))
        end
      end
      fzf.fzf_exec(items, {
        prompt = "Sections & chunks > ",
        actions = {
          ["default"] = function(selected)
            if selected and selected[1] then
              local lnum = tonumber(selected[1]:match("^%s*(%d+)"))
              if lnum then
                vim.api.nvim_win_set_cursor(0, { lnum, 0 })
                vim.cmd("normal! zz")
              end
            end
          end,
        },
      })
    end

    -- ── which-key registrations ──────────────────────────────────────────
    local ok_wk, wk = pcall(require, "which-key")
    if ok_wk then
      wk.add({
        {
          "<leader>q",
          group = "Quarto",
          buffer = true,
          cond = function()
            return vim.bo.filetype == "quarto"
          end,
        },

        -- Preview
        {
          "<leader>qp",
          function() quarto.quartoPreview() end,
          desc = "Preview document",
          buffer = true,
        },
        {
          "<leader>qP",
          function() quarto.quartoClosePreview() end,
          desc = "Close preview",
          buffer = true,
        },

        -- Runner
        { "<leader>qr",  group = "run",  buffer = true },
        {
          "<leader>qrr",
          function() require("quarto.runner").run_cell() end,
          desc = "Run cell",
          buffer = true,
        },
        {
          "<leader>qra",
          function() require("quarto.runner").run_above() end,
          desc = "Run cells above",
          buffer = true,
        },
        {
          "<leader>qrb",
          function() require("quarto.runner").run_below() end,
          desc = "Run cells below",
          buffer = true,
        },
        {
          "<leader>qrl",
          function() require("quarto.runner").run_all() end,
          desc = "Run all cells",
          buffer = true,
        },
        {
          "<leader>qrL",
          function() require("quarto.runner").run_all(true) end,
          desc = "Run all cells (all langs)",
          buffer = true,
        },
        {
          "<leader>qrs",
          "<Plug>SlimeRegionSend",
          desc = "Send selection (slime)",
          mode = "v",
          buffer = true,
        },

        -- Navigation via fzf-lua
        { "<leader>qf",  group = "find",  buffer = true },
        {
          "<leader>qff",
          fzf_quarto_headings,
          desc = "Find headings & chunks",
          buffer = true,
        },
        {
          "<leader>qfh",
          function()
            local ok, fzf = pcall(require, "fzf-lua")
            if ok then fzf.live_grep({ cwd = vim.fn.getcwd() }) end
          end,
          desc = "Live grep in project",
          buffer = true,
        },

        -- Formatting via conform
        {
          "<leader>qF",
          function()
            require("conform").format({ bufnr = 0, async = true, lsp_fallback = true })
          end,
          desc = "Format buffer (conform)",
          buffer = true,
        },
        {
          "<leader>qfc",
          desc = "Format current chunk (conform)",
          buffer = true,
        },

        -- Activate
        {
          "<leader>qa",
          function() quarto.activate() end,
          desc = "Activate quarto doc",
          buffer = true,
        },
      })
    end

    -- ── Chunk text objects ───────────────────────────────────────────────
    local function select_chunk(include_fences)
      local cursor = vim.api.nvim_win_get_cursor(0)
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local start_l, end_l
      for i = cursor[1], 1, -1 do
        if lines[i]:match("^```{") then start_l = i; break end
      end
      for i = cursor[1], #lines do
        if lines[i]:match("^```%s*$") and i > (start_l or 0) then end_l = i; break end
      end
      if not (start_l and end_l) then return end
      local s = include_fences and start_l or start_l + 1
      local e = include_fences and end_l   or end_l   - 1
      vim.api.nvim_win_set_cursor(0, { s, 0 })
      vim.cmd("normal! V")
      vim.api.nvim_win_set_cursor(0, { e, 0 })
    end

    vim.keymap.set("o", "ic", function() select_chunk(false) end,
      { buffer = true, desc = "inner chunk" })
    vim.keymap.set("o", "ac", function() select_chunk(true) end,
      { buffer = true, desc = "around chunk" })
    vim.keymap.set("x", "ic", function() select_chunk(false) end,
      { buffer = true, desc = "inner chunk" })
    vim.keymap.set("x", "ac", function() select_chunk(true) end,
      { buffer = true, desc = "around chunk" })
  end,
}
