-- Add this to your lazy.nvim plugin specs
-- e.g. in ~/.config/nvim/lua/plugins/slime.lua

return {
  "jpalardy/vim-slime",
  commit = "2cfdc3b24e7ebaa64f5a1a04b00555600c622b79",
  init = function()
    -- Must be set in init (before plugin loads), not config

    -- Use "tmux" if you run Neovim inside tmux (most common)
    -- Other options: "neovim", "wezterm", "kitty", "zellij"
    vim.g.slime_target = "wezterm"

    -- Paste via a temp file (more reliable than bracketed paste for most REPLs)
    vim.g.slime_paste_file = vim.fn.tempname()

    -- Grab the pane ID of the most recently active WezTerm pane that isn't
    -- this one — equivalent to tmux's {last}. Falls back to pane 0 on error.
    local function last_wezterm_pane()
      local cur = tonumber(vim.env.WEZTERM_PANE) or -1
      local handle = io.popen("wezterm cli list --format json 2>/dev/null")
      if not handle then return 0 end
      local raw = handle:read("*a")
      handle:close()
      local ok, panes = pcall(vim.json.decode, raw)
      if not ok or not panes then return 0 end
      -- Walk panes newest-first; pick first one that isn't ours
      table.sort(panes, function(a, b)
        return (a.pane_id or 0) > (b.pane_id or 0)
      end)
      for _, p in ipairs(panes) do
        if p.pane_id ~= cur then
          return p.pane_id
        end
      end
      return 0
    end

    vim.g.slime_default_config = { pane_id = last_wezterm_pane() }

    -- Skip the confirmation prompt every time you send
    vim.g.slime_dont_ask_default = 1
  end,

  keys = {
    { "<leader>sl", "<Plug>SlimeSendCurrentLine", desc = "Send line" },
    { "<leader>sp", "<Plug>SlimeMotionSend",      desc = "Send motion" },
    { "<leader>sv", "<Plug>SlimeRegionSend",      mode = "x", desc = "Send selection" },
    { "<leader>sb", "<Plug>SlimeFileSend",        desc = "Send buffer" },
    { "<leader>sc", "<Plug>SlimeConfig",          desc = "Config" },
  },

  config = function()
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>s",  group = "slime" },
        { "<leader>sv", mode = "x" },  -- ensure visual entry is also registered
      })
    end
  end,
}
