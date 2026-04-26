-- ~/.config/nvim/lua/plugins/vim-qf.lua
-- vim-qf — Quickfix UX polish: smarter navigation, filtering, toggle, jump-and-close.
-- Works alongside trouble.nvim: trouble owns the pretty UI, vim-qf owns the raw qf keybindings.
-- All bindings are whichkey-registered under \q (quickfix group).

return {
  "romainl/vim-qf",
  event = "QuickFixCmdPost",  -- load only when a qf list is actually populated

  init = function()
    -- vim-qf configuration lives in g: vars, set before plugin loads
    vim.g.qf_mapping_ack_style = 1   -- ack-style: o=open, O=open+close, go=preview, t=tab, T=tab-silent, v=vsplit, gv=vsplit-silent
    vim.g.qf_auto_open_quickfix = 0  -- don't auto-open; we control this manually
    vim.g.qf_auto_open_loclist  = 0
    vim.g.qf_auto_quit          = 1  -- close qf window when last item is selected
    vim.g.qf_window_bottom      = 1  -- qf opens at the bottom
    vim.g.qf_loclist_window_bottom = 1
    vim.g.qf_max_height         = 12 -- cap the qf window height
    vim.g.qf_shorten_path       = 3  -- shorten paths for readability
  end,

  config = function()
    local map = vim.keymap.set
    local opts = { silent = true }

    -- ── Navigation ─────────────────────────────────────────────────────────────
    -- Wrapping next/prev (vim-qf makes these wrap around automatically)
    map("n", "]q", "<Plug>(qf_qf_next)",      vim.tbl_extend("force", opts, { desc = "Next quickfix item" }))
    map("n", "[q", "<Plug>(qf_qf_previous)",  vim.tbl_extend("force", opts, { desc = "Prev quickfix item" }))
    map("n", "]l", "<Plug>(qf_loc_next)",     vim.tbl_extend("force", opts, { desc = "Next loclist item" }))
    map("n", "[l", "<Plug>(qf_loc_previous)", vim.tbl_extend("force", opts, { desc = "Prev loclist item" }))

    -- ── Toggle ──────────────────────────────────────────────────────────────────
    map("n", "<leader>qq", "<Plug>(qf_qf_toggle)",      vim.tbl_extend("force", opts, { desc = "Toggle quickfix" }))
    map("n", "<leader>ql", "<Plug>(qf_loc_toggle)",     vim.tbl_extend("force", opts, { desc = "Toggle loclist" }))
    map("n", "<leader>qQ", "<Plug>(qf_qf_toggle_stay)", vim.tbl_extend("force", opts, { desc = "Toggle quickfix (stay)" }))
    map("n", "<leader>qL", "<Plug>(qf_loc_toggle_stay)",vim.tbl_extend("force", opts, { desc = "Toggle loclist (stay)" }))

    -- ── Filtering (narrow the qf list) ─────────────────────────────────────────
    -- \qf  → keep only lines matching a pattern
    -- \qF  → remove lines matching a pattern
    map("n", "<leader>qf", function()
      local pat = vim.fn.input("Keep lines matching: ")
      if pat ~= "" then vim.cmd("Cfilter " .. pat) end
    end, vim.tbl_extend("force", opts, { desc = "Filter quickfix (keep)" }))

    map("n", "<leader>qF", function()
      local pat = vim.fn.input("Remove lines matching: ")
      if pat ~= "" then vim.cmd("Cfilter! " .. pat) end
    end, vim.tbl_extend("force", opts, { desc = "Filter quickfix (remove)" }))

    map("n", "<leader>qr", "<cmd>Crestore<CR>", vim.tbl_extend("force", opts, { desc = "Restore qf (undo filter)" }))

    -- ── Jump and close ──────────────────────────────────────────────────────────
    -- Inside the qf window, <CR> jumps and closes the window
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "qf",
      callback = function(ev)
        vim.keymap.set("n", "<CR>", function()
          -- open the entry then close qf
          vim.cmd("normal! \r")
          vim.cmd("cclose")
        end, { buffer = ev.buf, desc = "Jump and close quickfix" })

        -- also wire up preview without closing
        vim.keymap.set("n", "p", function()
          vim.cmd("normal! \r")
          vim.cmd("wincmd p") -- jump back to qf window
        end, { buffer = ev.buf, desc = "Preview entry (stay in qf)" })
      end,
    })

    -- ── WhichKey group ──────────────────────────────────────────────────────────
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>q",  group = "Quickfix / Loclist" },
        { "]q",         desc  = "Next quickfix item" },
        { "[q",         desc  = "Prev quickfix item" },
        { "]l",         desc  = "Next loclist item" },
        { "[l",         desc  = "Prev loclist item" },
      })
    end
  end,
}
