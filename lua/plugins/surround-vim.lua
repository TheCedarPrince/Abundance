-- ~/.config/nvim/lua/plugins/vim-surround.lua
-- tpope/vim-surround — add, change, delete surrounding characters.
--
-- vim-surround needs no Lua setup() call. This file just:
--   1. declares it as a lazy.nvim plugin
--   2. registers all its operators with which-key so they're discoverable
--
-- ── How to use vim-surround ────────────────────────────────────────────────
--
--  NORMAL MODE — operators that take a motion or text object:
--
--  ys{motion}{char}  — "you surround": add surrounding around a motion
--    ysiw"           — surround inner word with "double quotes"
--    ys$)            — surround to end of line with (parentheses)
--    yss)            — surround entire line with (parentheses)
--    yst,)           — surround up to next comma with (parentheses)
--
--  cs{old}{new}      — "change surround": swap one surrounding for another
--    cs"'            — change "double quotes" to 'single quotes'
--    cs(<            — change (parens) to <angle brackets>
--    cs{[            — change {braces} to [brackets]
--
--  ds{char}          — "delete surround": remove a surrounding pair
--    ds"             — delete surrounding double quotes
--    ds(             — delete surrounding parentheses
--    dst             — delete surrounding HTML/XML tag
--
--  VISUAL MODE — select first, then wrap:
--
--  S{char}           — surround visual selection
--    viw then S"     — wrap inner word in double quotes
--    V then S<p>     — wrap line in <p></p> HTML tag
--
-- ── Surrounding character shortcuts ───────────────────────────────────────
--   )  or b  → (  )   parentheses (no spaces)
--   (        → (  )   parentheses (with inner spaces)
--   ]  or r  → [  ]   brackets
--   }  or B  → {  }   braces
--   >        → <  >   angle brackets
--   "  '  `  → matching quote pair
--   t        → <tag> (prompts for tag name)
--
-- ── With repeat.vim ────────────────────────────────────────────────────────
--   vim-surround operations are repeatable with . if tpope/vim-repeat
--   is installed (it is, as a dependency of leap.nvim in this config).

return {
  "tpope/vim-surround",
  commit = "3d188ed2113431cf8dac77be61b842acb64433d9",
  dependencies = { "tpope/vim-repeat" },
  event = "VeryLazy",

  config = function()
    -- vim-surround has no setup() function.
    -- Register operators with which-key for discoverability.
    local ok, wk = pcall(require, "which-key")
    if not ok then return end

    wk.add({
      -- ys operator
      { "ys",  desc = "Surround: add (ys{motion}{char})",  mode = "n" },
      { "yss", desc = "Surround: add around line",         mode = "n" },
      { "yS",  desc = "Surround: add, place on new lines", mode = "n" },
      { "ySS", desc = "Surround: add line, new lines",     mode = "n" },

      -- cs operator
      { "cs",  desc = "Surround: change (cs{old}{new})",   mode = "n" },

      -- ds operator
      { "ds",  desc = "Surround: delete (ds{char})",       mode = "n" },

      -- Visual S
      { "S",   desc = "Surround: wrap selection",          mode = "x" },
      { "gS",  desc = "Surround: wrap selection (newlines)", mode = "x" },
    })
  end,
}
