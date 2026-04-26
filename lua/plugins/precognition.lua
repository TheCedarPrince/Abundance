-- ~/.config/nvim/lua/plugins/precognition.lua
-- precognition.nvim — Virtual text + gutter signs showing available motions.
-- Starts visible. Toggle/peek on demand via \tp*.
--
-- Extended with plugin-aware hints for:
--   • tpope/vim-surround  (ys, cs, ds operators; S in visual)
--   • ggandor/leap.nvim   (s forward, S backward, gs remote)
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  HOW PRECOGNITION HINTS WORK                                            │
-- │                                                                         │
-- │  `hints` places symbols on the virtual text line at specific column     │
-- │  slots that precognition computes (next word boundary, matching pair,   │
-- │  line end, etc). You cannot add a freestanding hint at an arbitrary     │
-- │  column — you must attach it to an existing slot.                       │
-- │                                                                         │
-- │  Strategy used here:                                                    │
-- │  • Leap forward (s) → shown at the `w` slot (next word boundary)       │
-- │  • Leap backward (S) → shown at the `b` slot (prev word boundary)      │
-- │  • Surround (ys/cs/ds) → shown at the `%` slot (matching pair),        │
-- │    which is the most natural anchor for surround operations             │
-- │                                                                         │
-- │  `register_motions` overrides how positions are *computed*, not what    │
-- │  symbols are shown — so it isn't used for plugin integration here.      │
-- └─────────────────────────────────────────────────────────────────────────┘
--
-- ⚠  KEY CONFLICT: vim-surround and leap.nvim both claim `S` in Visual
--    mode. Resolve this in your leap config by freeing S in visual:
--
--      vim.keymap.del("x", "S")   -- let vim-surround keep S in visual
--      -- then remap leap's backward to gs or another key:
--      vim.keymap.set({"n","o"}, "S", "<Plug>(leap-backward)",
--        { desc = "Leap backward" })
--
--    The hints below assume vim-surround owns visual S.

return {
  "tris203/precognition.nvim",
  event = "VeryLazy",
  opts = {
    startVisible = true,
    showBlankVirtLine = false,

    highlightColor = { link = "Comment" },

    -- ── Hints (virtual text line) ──────────────────────────────────────────
    --
    -- Labels use · as a separator when multiple plugins share a slot.
    -- Format:  <native motion> · <plugin shortcut>
    --
    hints = {
      -- Line anchors — kept clean, no plugin overloads
      Caret  = { text = "^",   prio = 2 },
      Dollar = { text = "$",   prio = 1 },
      Zero   = { text = "0",   prio = 1 },

      -- w slot: next word boundary
      -- leap-forward (s) jumps to the same class of positions → show s alongside w
      w = { text = "w · s›",  prio = 10 },

      -- b slot: previous word boundary
      -- leap-backward (S) in normal mode goes to prev word starts → show S alongside b
      b = { text = "b · ‹S",  prio = 9 },

      -- e slot: end of current word — kept clean
      e = { text = "e",        prio = 8 },

      -- WORD variants — kept clean, leap doesn't distinguish big/small word
      W = { text = "W",        prio = 7 },
      B = { text = "B",        prio = 6 },
      E = { text = "E",        prio = 5 },

      -- % slot: matching pair — the natural anchor for surround operations.
      -- Shows all three surround operators as a reminder:
      --   ys  → "you surround"  (add surround around motion/text-object)
      --   cs  → "change surround"
      --   ds  → "delete surround"
      -- In Visual mode, S wraps the selection (no slot needed, it's mode-aware).
      MatchingPair = { text = "% ys·cs·ds", prio = 5 },
    },

    -- ── Gutter hints (sign column, vertical movement) ──────────────────────
    gutterHints = {
      G             = { text = "G",  prio = 10 },
      gg            = { text = "gg", prio = 9 },
      PrevParagraph = { text = "{",  prio = 8 },
      NextParagraph = { text = "}",  prio = 8 },
    },

    -- Suppress hints in UI / non-editing filetypes
    disabled_fts = {
      "alpha", "dashboard", "lazy", "mason", "neo-tree",
      "NvimTree", "TelescopePrompt", "trouble", "qf",
      "help", "man", "startify", "aerial",
    },
  },

  config = function(_, opts)
    require("precognition").setup(opts)

    -- ── Leap motions adapter shim ──────────────────────────────────────────
    --
    -- precognition's register_motions() API lets you override how position
    -- slots are *computed*. Leap doesn't expose a public Lua API for its
    -- label-position algorithm, so we can't hook it directly. The w·s and
    -- b·S labels in `hints` above are the integration point — they remind
    -- you that leap operates on the same word-boundary positions that the
    -- native w/b hints mark.
    --
    -- If a future version of leap exposes a public position API, wire it in
    -- here via require("precognition.motions").register_motions({ ... }).

    -- ── WhichKey ───────────────────────────────────────────────────────────
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>tp", group = "Precognition" },
      })
    end

    vim.keymap.set("n", "<leader>tpt", function()
      local visible = require("precognition").toggle()
      vim.notify("Precognition " .. (visible and "on" or "off"), vim.log.levels.INFO)
    end, { desc = "Toggle precognition hints" })

    vim.keymap.set("n", "<leader>tpp", function()
      require("precognition").peek()
    end, { desc = "Peek precognition (until cursor moves)" })

    vim.keymap.set("n", "<leader>tps", function()
      require("precognition").show()
    end, { desc = "Show precognition hints" })

    vim.keymap.set("n", "<leader>tph", function()
      require("precognition").hide()
    end, { desc = "Hide precognition hints" })
  end,
}
