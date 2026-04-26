-- latex-zk.nvim
-- Zettelkasten workflow helpers for LaTeX notes in Neovim
-- Requires: fzf-lua
-- Optional: which-key.nvim (group label registered automatically if present)
--
-- With Lazy.nvim, load this as a local plugin — see README for the spec.
--
-- Default keymaps:
--   <leader>zl  (visual) → Link selected text to a note via fzf-lua grep
--   <leader>ze  (visual) → Extract selected text into a new Zettelkasten note
--   <leader>zt  (visual) → Wrap selection in a catchfilebetweentags transclusion tag
--   <leader>zi  (normal) → Insert \ExecuteMetaData by searching existing tags
--   <leader>zm  (visual) → Move selection into an existing note as a sub/subsubsection
--   <leader>zr  (normal) → Rename current note and update all \href references
--   <leader>zn  (normal) → Browse related notes (incoming + outgoing links)

local M = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Default configuration
-- Override any key via require("latex-zk").setup({ ... })
-- ─────────────────────────────────────────────────────────────────────────────
M.config = {
  -- Root directory that contains all your .tex notes.
  notes_dir = vim.fn.expand("~/Knowledgebase/TEXZK"),

  -- Prefix used when scanning for the highest existing note number.
  -- Scans for files matching  <prefix>-NNNN.tex
  filename_prefix = "aaa",

  -- LaTeX command used to pull the new note into the source document.
  -- "\\subinput" works with the standalone + subpreambles setup.
  -- Change to "\\input" if you prefer plain \input.
  input_command = "\\subinput",

  -- Keymaps (set to false to disable a binding)
  keymaps = {
    link       = "<leader>zl",   -- (visual) link selection to a note
    extract    = "<leader>ze",   -- (visual) extract selection to a new note
    tag_wrap   = "<leader>zt",   -- (visual) wrap selection in a transclusion tag
    tag_insert = "<leader>zi",   -- (normal) insert \ExecuteMetaData from tag search
    move       = "<leader>zm",   -- (visual) move selection into an existing note
    rename     = "<leader>zr",   -- (normal) rename note + update all hrefs
    related    = "<leader>zn",   -- (normal) browse related notes
  },

  -- which-key group label shown for the <leader>z prefix.
  -- Set to false to skip which-key registration entirely.
  whichkey_label = "Zettelkasten",
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function get_notes_dir()
  return M.config.notes_dir
end

--- Get visually selected text after leaving Visual mode.
--- Returns: lines (table), start_row, start_col, end_row, end_col  (0-indexed)
local function get_visual_selection()
  local _, ls, cs = unpack(vim.fn.getpos("'<"))
  local _, le, ce = unpack(vim.fn.getpos("'>"))
  ls = ls - 1
  le = le - 1
  cs = cs - 1
  -- For linewise 'V' selections ce is a large sentinel — clamp to line length.
  local last_line = vim.api.nvim_buf_get_lines(0, le, le + 1, false)[1] or ""
  ce = math.min(ce, #last_line)
  local lines = vim.api.nvim_buf_get_text(0, ls, cs, le, ce, {})
  return lines, ls, cs, le, ce
end

--- Scan notes_dir and return the next zero-padded 4-digit number, e.g. "0235".
local function next_note_number(dir)
  local prefix = M.config.filename_prefix
  local max_n  = 0
  local handle = vim.loop.fs_scandir(dir)
  if handle then
    while true do
      local name, _ = vim.loop.fs_scandir_next(handle)
      if not name then break end
      local n = name:match("^" .. vim.pesc(prefix) .. "%-(%d+)%.tex$")
      if n then
        local num = tonumber(n)
        if num and num > max_n then max_n = num end
      end
    end
  end
  return string.format("%04d", max_n + 1)
end

--- Build a \href{filename_base}{display_text} link.
--- hyperref is always available via zk.sty.
local function make_href(filename_base, display_text)
  return string.format("\\href{%s}{%s}", filename_base, display_text)
end

--- Render a complete new note from the template.
local function render_note(title, filename_base, keywords, body_text)
  local body_lines = vim.split(body_text, "\n", { plain = true })
  local lines = {
    "\\documentclass[class=article, crop=false]{standalone}",
    "\\usepackage[subpreambles=true]{standalone}",
    "\\usepackage{zk}",
    "",
    "\\begin{document}",
    "",
    "\\section{" .. title .. "}",
    "\\label{" .. filename_base .. "-first}",
    "\\keywords{" .. keywords .. "}",
    "",
  }
  for _, l in ipairs(body_lines) do
    lines[#lines + 1] = l
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "\\end{document}"
  return table.concat(lines, "\n")
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Feature 1 — Link selected text to a note via fzf-lua grep
-- ─────────────────────────────────────────────────────────────────────────────
function M.link_selection()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("[latex-zk] fzf-lua is not installed.", vim.log.levels.ERROR)
    return
  end

  local sel_lines, ls, cs, le, ce = get_visual_selection()
  local selected_text = table.concat(sel_lines, "\n")
  local source_buf    = vim.api.nvim_get_current_buf()
  local dir           = get_notes_dir()

  fzf.grep({
    cwd    = dir,
    prompt = "Link to › ",
    search = selected_text,
    actions = {
      ["default"] = function(selected_entry, ctx)
        if not selected_entry or #selected_entry == 0 then return end

        -- Use fzf-lua's own path parser to get a clean absolute filepath.
        -- entry_to_file() handles ANSI stripping, padding, and cwd resolution
        -- internally — it's the same helper fzf-lua uses for its own actions.
        local entry    = fzf.path.entry_to_file(selected_entry[1], ctx)
        local filepath = entry and (entry.path or entry.filename)

        if not filepath or filepath == "" then
          vim.notify("[latex-zk] Could not resolve file path from selection.", vim.log.levels.ERROR)
          return
        end

        local filename_base = vim.fn.fnamemodify(filepath, ":t:r")
        local link          = make_href(filename_base, selected_text)

        vim.api.nvim_buf_set_text(source_buf, ls, cs, le, ce, { link })
        vim.notify("[latex-zk] Linked → " .. filename_base)
      end,
    },
  })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Feature 2 — Extract selected text into a new Zettelkasten note
-- ─────────────────────────────────────────────────────────────────────────────
function M.extract_selection()
  local sel_lines, ls, cs, le, ce = get_visual_selection()
  if #sel_lines == 0 then
    vim.notify("[latex-zk] Nothing selected.", vim.log.levels.WARN)
    return
  end

  local selected_text = table.concat(sel_lines, "\n")
  local source_buf    = vim.api.nvim_get_current_buf()
  local dir           = get_notes_dir()

  vim.ui.input({ prompt = "New note title: " }, function(title)
    if not title or title == "" then
      vim.notify("[latex-zk] Extraction cancelled (no title).", vim.log.levels.WARN)
      return
    end

    vim.ui.input({ prompt = "Keywords (comma-separated): " }, function(keywords)
      keywords = keywords or ""

      local num           = next_note_number(dir)
      local filename_base = M.config.filename_prefix .. "-" .. num
      local new_filepath  = dir .. "/" .. filename_base .. ".tex"

      local content = render_note(title, filename_base, keywords, selected_text)

      local f, err = io.open(new_filepath, "w")
      if not f then
        vim.notify("[latex-zk] Could not create file: " .. (err or "?"), vim.log.levels.ERROR)
        return
      end
      f:write(content)
      f:close()

      local link        = make_href(filename_base, title)
      local input_cmd   = M.config.input_command
      local replacement = link .. "\n" .. input_cmd .. "{" .. filename_base .. "}"
      local repl_lines  = vim.split(replacement, "\n", { plain = true })

      vim.api.nvim_buf_set_text(source_buf, ls, cs, le, ce, repl_lines)

      vim.cmd("vsplit " .. vim.fn.fnameescape(new_filepath))
      vim.notify("[latex-zk] Created " .. filename_base .. ".tex")
    end)
  end)
end


-- ─────────────────────────────────────────────────────────────────────────────
-- Feature 3 — Wrap selection in a catchfilebetweentags transclusion tag
-- ─────────────────────────────────────────────────────────────────────────────
function M.tag_wrap()
  local sel_lines, ls, cs, le, ce = get_visual_selection()
  if #sel_lines == 0 then
    vim.notify("[latex-zk] Nothing selected.", vim.log.levels.WARN)
    return
  end

  local source_buf = vim.api.nvim_get_current_buf()

  vim.ui.input({ prompt = "Transclusion tag name: " }, function(tag)
    if not tag or tag == "" then
      vim.notify("[latex-zk] Tag wrap cancelled (no tag name).", vim.log.levels.WARN)
      return
    end

    -- Retrieve the selected lines fresh so we work with full lines for clean
    -- insertion of the markers on their own lines.
    local content_lines = vim.api.nvim_buf_get_lines(source_buf, ls, le + 1, false)

    -- Trim the first line to the visual column selection start.
    -- For characterwise selections the markers wrap the whole lines — this is
    -- intentional: catchfilebetweentags works at line granularity anyway.
    local wrapped = {}
    wrapped[#wrapped + 1] = "%<*" .. tag .. ">"
    for _, l in ipairs(content_lines) do
      wrapped[#wrapped + 1] = l
    end
    wrapped[#wrapped + 1] = "%</" .. tag .. ">"

    -- Replace the selected line range with the wrapped version.
    vim.api.nvim_buf_set_lines(source_buf, ls, le + 1, false, wrapped)

    vim.notify('[latex-zk] Wrapped in tag "' .. tag .. '".')
  end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Feature 4 — Insert \ExecuteMetaData by searching existing transclusion tags
-- ─────────────────────────────────────────────────────────────────────────────
function M.tag_insert()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("[latex-zk] fzf-lua is not installed.", vim.log.levels.ERROR)
    return
  end

  local insert_buf = vim.api.nvim_get_current_buf()
  local insert_pos = vim.api.nvim_win_get_cursor(0)  -- {row (1-indexed), col}
  local dir        = get_notes_dir()

  -- Scan notes_dir ourselves and build a flat list of display strings.
  -- This avoids fzf.grep whose "file:line:text" entry format causes the
  -- previewer to mis-parse filenames (e.g. treating "ref-0023.tex:24" as
  -- a path called "ref-0023.tex-24").
  local entries = {}
  local meta    = {}   -- meta[i] = { filepath, tag }

  local scan = vim.loop.fs_scandir(dir)
  if scan then
    while true do
      local name, ftype = vim.loop.fs_scandir_next(scan)
      if not name then break end
      if (ftype == "file" or ftype == nil) and name:match("%.tex$") then
        local filepath = dir .. "/" .. name
        local f = io.open(filepath, "r")
        if f then
          local flines = {}
          for l in f:lines() do flines[#flines + 1] = l end
          f:close()
          for i, l in ipairs(flines) do
            local tag = l:match("^%%%<%*(.-)%>")
            if tag then
              local preview_parts = {}
              for j = i + 1, math.min(i + 5, #flines) do
                local pl = flines[j]:match("^%s*(.-)%s*$")
                if pl and pl ~= "" and not pl:match("^%%</") then
                  preview_parts[#preview_parts + 1] = pl
                end
              end
              local preview = #preview_parts > 0
                              and table.concat(preview_parts, "  \xc2\xb7  ")
                              or  "(empty)"
              local display = string.format("%-30s  [%s]  %s", name, tag, preview)
              entries[#entries + 1] = display
              meta[#meta + 1]       = { filepath = filepath, tag = tag }
            end
          end
        end
      end
    end
  end

  if #entries == 0 then
    vim.notify("[latex-zk] No transclusion tags found in " .. dir, vim.log.levels.WARN)
    return
  end

  fzf.fzf_exec(entries, {
    prompt    = "Transclusion tag \xe2\x80\xba ",
    previewer = false,
    actions = {
      ["default"] = function(selected_entry)
        if not selected_entry or #selected_entry == 0 then return end

        local selected = selected_entry[1]
        local found    = nil
        for i, e in ipairs(entries) do
          if e == selected then found = meta[i]; break end
        end

        if not found then
          vim.notify("[latex-zk] Could not match selection to a tag.", vim.log.levels.ERROR)
          return
        end

        local filename_base = vim.fn.fnamemodify(found.filepath, ":t:r")
        local insert_text   = "\\ExecuteMetaData[" .. filename_base .. ".tex]{" .. found.tag .. "}"

        local row = insert_pos[1]
        vim.api.nvim_buf_set_lines(insert_buf, row, row, false, { insert_text })
        vim.notify("[latex-zk] Inserted transclusion from "
                   .. filename_base .. " [" .. found.tag .. "]")
      end,
    },
  })
end


-- ─────────────────────────────────────────────────────────────────────────────
-- Shared helper — check if a file references a given base name (any pattern)
-- ─────────────────────────────────────────────────────────────────────────────

--- Return true if `content` contains any reference to `base` using the full
--- set of LaTeX patterns we care about. Uses exact-word boundaries so that
--- e.g. "aaa-0023" does not match "aaa-00230".
local function content_references(content, base)
  local escaped = vim.pesc(base)
  local patterns = {
    "\\href%{"        .. escaped .. "%}",          -- \href{base}{...}
    "\\input%{"       .. escaped .. "%}",          -- \input{base}
    "\\subinput%{"    .. escaped .. "%}",          -- \subinput{base}
    "\\ExecuteMetaData%[" .. escaped .. "%.tex%]", -- \ExecuteMetaData[base.tex]{tag}
    "\\externaldocument%{" .. escaped .. "%}",     -- \externaldocument{base}
    "\\label%{"       .. escaped .. "%-",          -- \label{base-suffix}
    "\\label%{"       .. escaped .. "%}",          -- \label{base}  (exact)
    "\\ref%{"         .. escaped .. "%-",          -- \ref{base-suffix}
    "\\ref%{"         .. escaped .. "%}",
    "\\autoref%{"     .. escaped .. "%-",          -- \autoref{base-suffix}
    "\\autoref%{"     .. escaped .. "%}",
  }
  for _, pat in ipairs(patterns) do
    if content:find(pat) then return true end
  end
  return false
end

--- Apply all rename substitutions: old_base → new_base throughout `content`.
--- Preserves suffixes on labels/refs.
local function apply_renames(content, old_base, new_base)
  local o = vim.pesc(old_base)
  local n = new_base
  local total = 0
  local function sub(pat, repl)
    local result, count = content:gsub(pat, repl)
    content = result
    total   = total + count
  end
  sub("\\href%{"         .. o .. "%}",           "\\href{"         .. n .. "}")
  sub("\\input%{"        .. o .. "%}",           "\\input{"        .. n .. "}")
  sub("\\subinput%{"     .. o .. "%}",           "\\subinput{"     .. n .. "}")
  sub("\\ExecuteMetaData%[" .. o .. "%.tex%]",   "\\ExecuteMetaData[" .. n .. ".tex]")
  sub("\\externaldocument%{" .. o .. "%}",       "\\externaldocument{" .. n .. "}")
  -- labels/refs with suffix: replace only the base part, keep the suffix
  sub("(\\label%{)"      .. o .. "(%-)",         "%1" .. n .. "%2")
  sub("(\\label%{)"      .. o .. "(%})",         "%1" .. n .. "%2")
  sub("(\\ref%{)"        .. o .. "(%-)",         "%1" .. n .. "%2")
  sub("(\\ref%{)"        .. o .. "(%})",         "%1" .. n .. "%2")
  sub("(\\autoref%{)"    .. o .. "(%-)",         "%1" .. n .. "%2")
  sub("(\\autoref%{)"    .. o .. "(%})",         "%1" .. n .. "%2")
  return content, total
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Feature 5 — Move selection into an existing note (section picker + new)
-- ─────────────────────────────────────────────────────────────────────────────

function M.move_selection()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("[latex-zk] fzf-lua is not installed.", vim.log.levels.ERROR)
    return
  end

  local sel_lines, ls, cs, le, ce = get_visual_selection()
  if #sel_lines == 0 then
    vim.notify("[latex-zk] Nothing selected.", vim.log.levels.WARN)
    return
  end

  local selected_text = table.concat(sel_lines, "\n")
  local source_buf    = vim.api.nvim_get_current_buf()
  local dir           = get_notes_dir()

  -- Find the nearest section heading above the selection in the source buffer.
  -- ls is 0-indexed; scan upward to line 0.
  local source_section = nil
  do
    local heading_pats = {
      "^\\section%{(.-)%}",
      "^\\subsection%{(.-)%}",
      "^\\subsubsection%{(.-)%}",
    }
    for row = ls, 0, -1 do
      local line = vim.api.nvim_buf_get_lines(source_buf, row, row + 1, false)[1] or ""
      for _, pat in ipairs(heading_pats) do
        local title = line:match(pat)
        if title then source_section = title; break end
      end
      if source_section then break end
    end
  end

  --- Write `block` lines into `dest_lines` at `insert_at`, save, reload, split.
  local function commit(filepath, dest_lines, insert_at, block, source_display, dest_base)
    for j, bl in ipairs(block) do
      table.insert(dest_lines, insert_at + j - 1, bl)
    end
    local wf, werr = io.open(filepath, "w")
    if not wf then
      vim.notify("[latex-zk] Cannot write destination: " .. (werr or "?"), vim.log.levels.ERROR)
      return
    end
    for _, l in ipairs(dest_lines) do wf:write(l .. "\n") end
    wf:close()

    -- Replace selection in source with \href
    local link = make_href(dest_base, source_display)
    vim.api.nvim_buf_set_text(source_buf, ls, cs, le, ce,
                              vim.split(link, "\n", { plain = true }))

    -- Reload dest buffer if open, then open in split
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf) == filepath then
        vim.api.nvim_buf_call(buf, function() vim.cmd("edit!") end)
        break
      end
    end
    vim.cmd("vsplit " .. vim.fn.fnameescape(filepath))
    vim.notify("[latex-zk] Moved \xe2\x86\x92 " .. dest_base .. " / " .. source_display)
  end

  --- Read dest file lines and find all heading positions.
  local function parse_dest(filepath)
    local df, derr = io.open(filepath, "r")
    if not df then
      vim.notify("[latex-zk] Cannot read destination: " .. (derr or "?"), vim.log.levels.ERROR)
      return nil
    end
    local dest_lines = {}
    for l in df:lines() do dest_lines[#dest_lines + 1] = l end
    df:close()

    -- Collect headings: { line_idx (1-based), level, title }
    local headings = {}
    for i, l in ipairs(dest_lines) do
      local level, title = l:match("^\\(section)%{(.-)%}")
      if not level then level, title = l:match("^\\(subsection)%{(.-)%}") end
      if not level then level, title = l:match("^\\(subsubsection)%{(.-)%}") end
      if level then
        headings[#headings + 1] = { idx = i, level = level, title = title }
      end
    end

    -- Find \end{document} line
    local end_doc = #dest_lines + 1
    for i = #dest_lines, 1, -1 do
      if dest_lines[i]:match("^\\end%{document%}") then
        end_doc = i
        break
      end
    end

    return dest_lines, headings, end_doc
  end

  -- ── Step 1: pick destination file via interactive live grep ────────────────
  fzf.live_grep({
    cwd    = dir,
    prompt = "Move into file \xe2\x80\xba ",
    actions = {
      ["default"] = function(selected_entry, ctx)
        if not selected_entry or #selected_entry == 0 then return end

        local entry    = fzf.path.entry_to_file(selected_entry[1], ctx)
        local filepath = entry and (entry.path or entry.filename)
        if not filepath or filepath == "" then
          vim.notify("[latex-zk] Could not resolve destination file.", vim.log.levels.ERROR)
          return
        end
        if not filepath:match("^/") then filepath = dir .. "/" .. filepath end

        local dest_base  = vim.fn.fnamemodify(filepath, ":t:r")
        local dest_lines, headings, end_doc = parse_dest(filepath)
        if not dest_lines then return end

        -- ── Step 2: choose existing section or [New section] ─────────────────
        local section_items = {}
        local heading_map   = {}  -- item label → heading entry

        -- Level prefix for readability
        local level_prefix = { section = "§ ", subsection = "  § ", subsubsection = "    § " }
        for _, h in ipairs(headings) do
          local label = (level_prefix[h.level] or "") .. h.title
          section_items[#section_items + 1] = label
          heading_map[label] = h
        end
        section_items[#section_items + 1] = "[New section]"

        vim.ui.select(section_items, { prompt = "Insert into: " }, function(chosen)
          if not chosen then
            vim.notify("[latex-zk] Move cancelled.", vim.log.levels.WARN)
            return
          end

          if chosen ~= "[New section]" then
            -- ── Existing section path ─────────────────────────────────────────
            local h = heading_map[chosen]
            -- Find insert point: after this section's content, before next
            -- heading of equal or higher level or \end{document}
            local level_rank = { section = 1, subsection = 2, subsubsection = 3 }
            local my_rank    = level_rank[h.level]
            local insert_at  = end_doc  -- default: before \end{document}

            for _, other in ipairs(headings) do
              if other.idx > h.idx and level_rank[other.level] <= my_rank then
                insert_at = other.idx
                break
              end
            end

            -- Build block (double blank line gap, raw content)
            local content_lines = vim.split(selected_text, "\n", { plain = true })
            local block = { "", "" }
            for _, l in ipairs(content_lines) do block[#block + 1] = l end
            block[#block + 1] = ""

            commit(filepath, dest_lines, insert_at, block, h.title, dest_base)

          else
            -- ── New section path ──────────────────────────────────────────────
            vim.ui.select(
              { "\\subsection", "\\subsubsection", "Raw (no heading)" },
              { prompt = "Section depth: " },
              function(section_cmd)
                if not section_cmd then
                  vim.notify("[latex-zk] Move cancelled.", vim.log.levels.WARN)
                  return
                end

                local is_raw = (section_cmd == "Raw (no heading)")

                local function do_new_move(title)
                  local content_lines = vim.split(selected_text, "\n", { plain = true })
                  local block = { "", "" }
                  if not is_raw then
                    block[#block + 1] = section_cmd .. "{" .. title .. "}"
                    block[#block + 1] = ""
                  end
                  for _, l in ipairs(content_lines) do block[#block + 1] = l end
                  block[#block + 1] = ""

                  local display = is_raw and dest_base or title
                  commit(filepath, dest_lines, end_doc, block, display, dest_base)
                end

                if is_raw then
                  do_new_move(dest_base)
                else
                  vim.ui.input({ prompt = "Section title: " }, function(title)
                    if not title or title == "" then
                      vim.notify("[latex-zk] Move cancelled (no title).", vim.log.levels.WARN)
                      return
                    end
                    do_new_move(title)
                  end)
                end
              end
            )
          end
        end)
      end,
    },
  })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Feature 6 — Rename current note and update all references
-- ─────────────────────────────────────────────────────────────────────────────
function M.rename_note()
  local current_path = vim.api.nvim_buf_get_name(0)
  if current_path == "" then
    vim.notify("[latex-zk] Buffer has no file path.", vim.log.levels.ERROR)
    return
  end

  local current_base = vim.fn.fnamemodify(current_path, ":t:r")
  local dir          = get_notes_dir()

  vim.ui.input({ prompt = "Rename to: ", default = current_base }, function(new_base)
    if not new_base or new_base == "" or new_base == current_base then
      vim.notify("[latex-zk] Rename cancelled.", vim.log.levels.WARN)
      return
    end

    local new_path = dir .. "/" .. new_base .. ".tex"

    -- Rename file on disk
    local ok, err = os.rename(current_path, new_path)
    if not ok then
      vim.notify("[latex-zk] Rename failed: " .. (err or "?"), vim.log.levels.ERROR)
      return
    end

    -- Update all references across every .tex file in the knowledgebase
    local updated_files = 0
    local handle = vim.loop.fs_scandir(dir)
    if handle then
      while true do
        local name, ftype = vim.loop.fs_scandir_next(handle)
        if not name then break end
        if (ftype == "file" or ftype == nil) and name:match("%.tex$") then
          local fpath = dir .. "/" .. name
          local f = io.open(fpath, "r")
          if f then
            local content = f:read("*a")
            f:close()
            if content_references(content, current_base) then
              local new_content, count = apply_renames(content, current_base, new_base)
              if count > 0 then
                local wf = io.open(fpath, "w")
                if wf then
                  wf:write(new_content)
                  wf:close()
                  updated_files = updated_files + 1
                  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_get_name(buf) == fpath then
                      vim.api.nvim_buf_call(buf, function() vim.cmd("edit!") end)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    -- Point current buffer at the renamed file
    vim.cmd("keepalt file " .. vim.fn.fnameescape(new_path))
    vim.cmd("write!")
    vim.notify(string.format("[latex-zk] Renamed to %s.tex — %d file(s) updated.",
               new_base, updated_files))
  end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Feature 7 — Browse related notes (incoming + outgoing links)
-- ─────────────────────────────────────────────────────────────────────────────
function M.related_notes()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("[latex-zk] fzf-lua is not installed.", vim.log.levels.ERROR)
    return
  end

  local current_path = vim.api.nvim_buf_get_name(0)
  if current_path == "" then
    vim.notify("[latex-zk] Buffer has no file path.", vim.log.levels.ERROR)
    return
  end

  local current_base = vim.fn.fnamemodify(current_path, ":t:r")
  local dir          = get_notes_dir()

  -- Collect outgoing: any base referenced from the current file
  local outgoing = {}  -- base → filepath
  local cf = io.open(current_path, "r")
  if cf then
    local content = cf:read("*a")
    cf:close()
    -- Scan all .tex files in dir; check if current file references them
    local scan = vim.loop.fs_scandir(dir)
    if scan then
      while true do
        local name, ftype = vim.loop.fs_scandir_next(scan)
        if not name then break end
        if (ftype == "file" or ftype == nil) and name:match("%.tex$") then
          local base  = name:match("^(.-)%.tex$")
          local fpath = dir .. "/" .. name
          if base ~= current_base and content_references(content, base) then
            outgoing[base] = fpath
          end
        end
      end
    end
  end

  -- Collect incoming: files that reference the current file
  local incoming = {}  -- base → filepath
  local handle = vim.loop.fs_scandir(dir)
  if handle then
    while true do
      local name, ftype = vim.loop.fs_scandir_next(handle)
      if not name then break end
      if (ftype == "file" or ftype == nil) and name:match("%.tex$") then
        local base  = name:match("^(.-)%.tex$")
        local fpath = dir .. "/" .. name
        if base ~= current_base then
          local f = io.open(fpath, "r")
          if f then
            local content = f:read("*a")
            f:close()
            if content_references(content, current_base) then
              incoming[base] = fpath
            end
          end
        end
      end
    end
  end

  -- Build picker entries: outgoing first ([→]), then incoming ([←])
  local entries      = {}
  local entry_to_path = {}

  local function section_preview(fpath)
    -- Return the first \section title found, or first non-command line
    local pf = io.open(fpath, "r")
    if not pf then return "" end
    local preview = ""
    for l in pf:lines() do
      local title = l:match("^\\section%{(.-)%}")
      if title then preview = title; break end
      local trimmed = l:match("^%s*(.-)%s*$")
      if trimmed ~= "" and not trimmed:match("^\\") and preview == "" then
        preview = trimmed
      end
    end
    pf:close()
    return preview
  end

  local outgoing_entries = {}
  for base, fpath in pairs(outgoing) do
    local preview = section_preview(fpath)
    outgoing_entries[#outgoing_entries + 1] = {
      display = string.format("[\xe2\x86\x92] %-25s  %s", base, preview),
      fpath   = fpath,
    }
  end
  table.sort(outgoing_entries, function(a, b) return a.display < b.display end)

  local incoming_entries = {}
  for base, fpath in pairs(incoming) do
    local preview = section_preview(fpath)
    incoming_entries[#incoming_entries + 1] = {
      display = string.format("[\xe2\x86\x90] %-25s  %s", base, preview),
      fpath   = fpath,
    }
  end
  table.sort(incoming_entries, function(a, b) return a.display < b.display end)

  -- Outgoing first, then incoming
  for _, e in ipairs(outgoing_entries) do
    entries[#entries + 1]        = e.display
    entry_to_path[e.display]     = e.fpath
  end
  for _, e in ipairs(incoming_entries) do
    entries[#entries + 1]        = e.display
    entry_to_path[e.display]     = e.fpath
  end

  if #entries == 0 then
    vim.notify("[latex-zk] No related notes found for " .. current_base, vim.log.levels.INFO)
    return
  end

  fzf.fzf_exec(entries, {
    prompt    = "Related notes \xe2\x80\xba ",
    previewer = false,
    fzf_opts  = {
      ["--multi"]  = true,
      ["--header"] = "[\xe2\x86\x92] outgoing  [\xe2\x86\x90] incoming  |  <tab> multi-select  <enter> open splits",
    },
    actions = {
      ["default"] = function(selected_entries)
        if not selected_entries or #selected_entries == 0 then return end
        for _, sel in ipairs(selected_entries) do
          local fpath = entry_to_path[sel]
          if fpath then
            vim.cmd("vsplit " .. vim.fn.fnameescape(fpath))
          end
        end
      end,
    },
  })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- which-key registration
-- ─────────────────────────────────────────────────────────────────────────────

--- Derive the shared key prefix from the configured keymaps.
--- e.g. "<leader>zl" + "<leader>ze"  →  "<leader>z"
local function shared_prefix(keymaps)
  local keys = {}
  for _, v in pairs(keymaps) do
    if type(v) == "string" then keys[#keys + 1] = v end
  end
  if #keys == 0 then return nil end
  if #keys == 1 then return keys[1]:sub(1, -2) end
  local ref = keys[1]
  local len = #ref
  for _, k in ipairs(keys) do
    local i = 1
    while i <= len and i <= #k and ref:sub(i, i) == k:sub(i, i) do
      i = i + 1
    end
    len = i - 1
  end
  local prefix = ref:sub(1, len)
  -- Trim any trailing non-word character so we land on a clean prefix.
  return (prefix:match("^(.-)%W*$") ~= "") and prefix:match("^(.-)%W*$") or nil
end

local function register_whichkey()
  local label = M.config.whichkey_label
  if not label then return end

  local ok, wk = pcall(require, "which-key")
  if not ok then return end

  local prefix = shared_prefix(M.config.keymaps)
  if not prefix then return end

  -- which-key v3+ uses wk.add(); fall back to wk.register() for v2.
  if wk.add then
    wk.add({
      { prefix,                          group = label,                            mode = "v" },
      { prefix,                          group = label,                            mode = "n" },
      { M.config.keymaps.link,       desc = "Link selection to note",          mode = "v", icon = "🔗" },
      { M.config.keymaps.extract,    desc = "Extract selection to new note",   mode = "v", icon = "✂️"  },
      { M.config.keymaps.tag_wrap,   desc = "Wrap selection in tag",           mode = "v", icon = "🏷️"  },
      { M.config.keymaps.tag_insert, desc = "Insert transclusion (ExecuteMetaData)", mode = "n", icon = "📥" },
      { M.config.keymaps.move,       desc = "Move selection into existing note",     mode = "v", icon = "➡️"  },
      { M.config.keymaps.rename,     desc = "Rename note + update hrefs",            mode = "n", icon = "✏️"  },
      { M.config.keymaps.related,    desc = "Browse related notes",                  mode = "n", icon = "🕸️" },
    })
  else
    -- which-key v2 legacy API
    local link_key       = M.config.keymaps.link:sub(#prefix + 1)
    local extract_key    = M.config.keymaps.extract:sub(#prefix + 1)
    local tag_wrap_key   = M.config.keymaps.tag_wrap:sub(#prefix + 1)
    local tag_insert_key = M.config.keymaps.tag_insert:sub(#prefix + 1)
    local move_key       = M.config.keymaps.move:sub(#prefix + 1)
    local rename_key     = M.config.keymaps.rename:sub(#prefix + 1)
    local related_key    = M.config.keymaps.related:sub(#prefix + 1)
    wk.register({
      [prefix] = {
        name = label,
        [link_key]       = { M.link_selection,    "Link selection to note" },
        [extract_key]    = { M.extract_selection, "Extract selection to new note" },
        [tag_wrap_key]   = { M.tag_wrap,          "Wrap selection in tag" },
        [tag_insert_key] = { M.tag_insert,        "Insert transclusion (ExecuteMetaData)" },
        [move_key]       = { M.move_selection,    "Move selection into existing note" },
      },
    }, { mode = "v" })
    wk.register({
      [prefix] = {
        name = label,
        [tag_insert_key] = { M.tag_insert,      "Insert transclusion (ExecuteMetaData)" },
        [rename_key]     = { M.rename_note,      "Rename note + update hrefs" },
        [related_key]    = { M.related_notes,    "Browse related notes" },
      },
    }, { mode = "n" })
  end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Setup
-- ─────────────────────────────────────────────────────────────────────────────
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local km = M.config.keymaps

  local function vmap(lhs, fn, desc)
    if lhs then
      vim.keymap.set("v", lhs, function()
        -- Commit '< and '> by exiting Visual mode before calling the function.
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
          "x", false
        )
        fn()
      end, { noremap = true, silent = true, desc = desc })
    end
  end

  vmap(km.link,    M.link_selection,    "Link selection to note")
  vmap(km.extract, M.extract_selection, "Extract selection to new note")
  vmap(km.tag_wrap, M.tag_wrap,         "Wrap selection in transclusion tag")
  vmap(km.move,     M.move_selection,   "Move selection into existing note")

  -- Normal-mode mappings
  local function nmap(lhs, fn, desc)
    if lhs then
      vim.keymap.set("n", lhs, fn, { noremap = true, silent = true, desc = desc })
    end
  end
  nmap(km.tag_insert, M.tag_insert,    "Insert transclusion (ExecuteMetaData)")
  nmap(km.rename,     M.rename_note,   "Rename note + update hrefs")
  nmap(km.related,    M.related_notes, "Browse related notes")

  -- Defer which-key registration so it runs after all plugins are loaded.
  vim.schedule(register_whichkey)
end

return M
