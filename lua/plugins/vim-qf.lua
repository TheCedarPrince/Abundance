-- ~/.config/nvim/lua/plugins/vim-qf.lua
-- vim-qf — quickfix UX polish: wrapping navigation, filtering, toggle.
--
-- How quickfix works with this setup:
--   Most tools (grep, LSP, build errors, telescope send-to-qf, etc.)
--   populate the quickfix list. Once populated:
--
--   \qq       toggle the raw quickfix window open/close
--   \xq       view the same list beautifully in Trouble (recommended)
--   ]q / [q   jump to next/prev item (wraps around, no more E553)
--   ]l / [l   jump to next/prev loclist item
--
--   Inside the quickfix window:
--   <CR>      jump to item AND close the qf window
--   p         preview item (stay in qf window)
--
--   Filtering the list (useful after a big grep):
--   \qf       keep only lines matching a pattern
--   \qF       remove lines matching a pattern
--   \qr       restore list (undo filter)

return {
  "romainl/vim-qf",
  commit = "7cafff6a9e0a1b54364b26a87f1efe749f8fb96b",
  event = "QuickFixCmdPost",

  init = function()
    vim.g.qf_mapping_ack_style  = 1  -- o=open, t=tab, v=vsplit, go=preview
    vim.g.qf_auto_open_quickfix = 0  -- don't auto-open; we control this
    vim.g.qf_auto_open_loclist  = 0
    vim.g.qf_auto_quit          = 1  -- close qf when last item is selected
    vim.g.qf_window_bottom      = 1  -- qf opens at bottom
    vim.g.qf_loclist_window_bottom = 1
    vim.g.qf_max_height         = 12
    vim.g.qf_shorten_path       = 3
  end,

  config = function()
    local map  = vim.keymap.set
    local s    = { silent = true }
    local function o(desc) return vim.tbl_extend("force", s, { desc = desc }) end

    -- ── Navigation (wrapping — no more hitting end and getting E553) ────────
    map("n", "]q", "<Plug>(qf_qf_next)",      o("Next quickfix item"))
    map("n", "[q", "<Plug>(qf_qf_previous)",  o("Prev quickfix item"))
    map("n", "]l", "<Plug>(qf_loc_next)",     o("Next loclist item"))
    map("n", "[l", "<Plug>(qf_loc_previous)", o("Prev loclist item"))

    -- ── Toggle quickfix / loclist ────────────────────────────────────────────
    map("n", "<leader>qq", "<Plug>(qf_qf_toggle)",       o("Toggle quickfix"))
    map("n", "<leader>ql", "<Plug>(qf_loc_toggle)",      o("Toggle loclist"))
    map("n", "<leader>qQ", "<Plug>(qf_qf_toggle_stay)",  o("Toggle quickfix (stay)"))
    map("n", "<leader>qL", "<Plug>(qf_loc_toggle_stay)", o("Toggle loclist (stay)"))

    -- ── Filtering ────────────────────────────────────────────────────────────
    map("n", "<leader>qf", function()
      local pat = vim.fn.input("Keep lines matching: ")
      if pat ~= "" then vim.cmd("Cfilter " .. pat) end
    end, o("Filter quickfix — keep matches"))

    map("n", "<leader>qF", function()
      local pat = vim.fn.input("Remove lines matching: ")
      if pat ~= "" then vim.cmd("Cfilter! " .. pat) end
    end, o("Filter quickfix — remove matches"))

    map("n", "<leader>qr", "<cmd>Crestore<CR>", o("Restore quickfix (undo filter)"))

    -- ── qf window: jump-and-close <CR>, preview p ───────────────────────────
    vim.api.nvim_create_autocmd("FileType", {
      pattern  = "qf",
      callback = function(ev)
        -- <CR> jumps to the item and closes the qf window
        map("n", "<CR>", function()
          local linenr = vim.fn.line(".")
          vim.cmd("cc " .. (vim.fn.getqflist({ idx = 0 }).idx or linenr))
          vim.cmd("cclose")
        end, { buffer = ev.buf, desc = "Jump to item and close qf" })

        -- p previews without closing (jump back to qf window)
        map("n", "p", function()
          local linenr = vim.fn.line(".")
          vim.cmd("cc " .. (vim.fn.getqflist({ idx = 0 }).idx or linenr))
          vim.cmd("wincmd p")
        end, { buffer = ev.buf, desc = "Preview item (stay in qf)" })
      end,
    })

    -- ── WhichKey ─────────────────────────────────────────────────────────────
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>q",  group = "Quickfix / Loclist" },
        { "<leader>qq", desc  = "Toggle quickfix" },
        { "<leader>ql", desc  = "Toggle loclist" },
        { "<leader>qQ", desc  = "Toggle quickfix (stay)" },
        { "<leader>qL", desc  = "Toggle loclist (stay)" },
        { "<leader>qf", desc  = "Filter — keep matches" },
        { "<leader>qF", desc  = "Filter — remove matches" },
        { "<leader>qr", desc  = "Restore (undo filter)" },
        { "]q",         desc  = "Next quickfix item" },
        { "[q",         desc  = "Prev quickfix item" },
        { "]l",         desc  = "Next loclist item" },
        { "[l",         desc  = "Prev loclist item" },
      })
    end
  end,
}
