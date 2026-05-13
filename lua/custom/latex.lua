local M = {}

-- ── Namespaces ────────────────────────────────────────────────────────────────
local ns_extern = vim.api.nvim_create_namespace("latex_externdoc")
local ns_dtm    = vim.api.nvim_create_namespace("latex_dtmdate")
local ns_table  = vim.api.nvim_create_namespace("latex_table")

-- ── Config ────────────────────────────────────────────────────────────────────

M.config = {
  table_cell_width = 15,
}

-- ── Date helpers ──────────────────────────────────────────────────────────────

local MONTHS = {
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
}

local function fmt_date(y, m, d)
  local month = MONTHS[tonumber(m)]
  if not month then return nil end
  return month .. " " .. tonumber(d) .. ", " .. y
end

-- ── File helpers ──────────────────────────────────────────────────────────────

local function get_first_section(filepath)
  local f = io.open(filepath, "r")
  if not f then return nil end
  for line in f:lines() do
    local title = line:match("\\section%*?%{(.-)%}")
    if title then
      f:close()
      return title
    end
  end
  f:close()
  return nil
end

-- ── Table helpers ─────────────────────────────────────────────────────────────

local function strip_latex(s)
  s = s:gsub("\\%w+%{(.-)%}", "%1")
  s = s:gsub("\\%w+%s*", "")
  s = s:gsub("%s+", " ")
  return s:match("^%s*(.-)%s*$")
end

local function fit(s, width)
  if #s > width then
    return s:sub(1, width - 1) .. "…"
  end
  return s .. string.rep(" ", width - #s)
end

local function split_cells(row)
  local cells = {}
  for cell in (row .. "&"):gmatch("(.-)&") do
    table.insert(cells, strip_latex(cell:match("^%s*(.-)%s*$")))
  end
  return cells
end

local function count_columns(spec)
  local count = 0
  for _ in spec:gmatch("[lcrp]") do
    count = count + 1
  end
  return count
end

-- ── Table concealment ─────────────────────────────────────────────────────────

local BOX = {
  h     = "─",
  v     = "│",
  tl    = "┌", tr    = "┐",
  bl    = "└", br    = "┘",
  ml    = "├", mr    = "┤",
  tm    = "┬", bm    = "┴",
  cross = "┼",
}

local HL = {
  border = "Comment",
  cell   = "Normal",
  header = "Title",
}

local function make_hline(n, w, left, mid, right)
  local inner = string.rep(BOX.h, w + 2)
  local parts = {}
  for i = 1, n do parts[i] = inner end
  return left .. table.concat(parts, mid) .. right
end

local function set_extmark(buf, ns, row, raw, virt)
  -- Conceal the raw line content
  vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
    end_row = row, end_col = #raw, conceal = "",
  })
  -- Overlay virtual text if provided
  if virt then
    vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
      virt_text     = virt,
      virt_text_pos = "overlay",
      hl_mode       = "combine",
    })
  end
end

function M.conceal_tables(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, ns_table, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local cw    = M.config.table_cell_width

  -- ── Pass 1: collect tabular blocks ───────────────────────────────────────
  local blocks  = {}
  local current = nil

  for i, line in ipairs(lines) do
    local row  = i - 1
    local spec = line:match("\\begin%{tabular%}%{(.-)%}")
    if spec then
      current = {
        begin_row = row,
        end_row   = nil,
        col_count = count_columns(spec),
        hlines    = {},   -- list of 0-based row indices for \hline
        data      = {},   -- list of { row, line } for data rows
      }
    elseif current and line:match("\\end%{tabular%}") then
      current.end_row = row
      table.insert(blocks, current)
      current = nil
    elseif current then
      if line:match("^%s*\\hline%s*$") then
        table.insert(current.hlines, row)
      elseif line:match("&") or line:match("\\\\") then
        table.insert(current.data, { row = row, line = line })
      end
    end
  end

  -- ── Pass 2: render each block ─────────────────────────────────────────────
  for _, block in ipairs(blocks) do
    local n      = block.col_count
    local hlines = block.hlines

    -- The last \hline becomes the bottom border (└┴┘), all others are mid (├┼┤)
    local last_hline = hlines[#hlines]

    -- \begin{tabular} → top border (┌┬┐)
    local brow = block.begin_row
    set_extmark(buf, ns_table, brow, lines[brow + 1],
      n > 0 and { { make_hline(n, cw, BOX.tl, BOX.tm, BOX.tr), HL.border } } or nil)

    -- \end{tabular} → conceal only (bottom border already drawn by last \hline)
    if block.end_row then
      set_extmark(buf, ns_table, block.end_row, lines[block.end_row + 1], nil)
    end

    -- \hline rows
    for _, hrow in ipairs(hlines) do
      local raw     = lines[hrow + 1]
      local hl_str  = (hrow == last_hline)
        and make_hline(n, cw, BOX.bl, BOX.bm, BOX.br)   -- bottom border
        or  make_hline(n, cw, BOX.ml, BOX.cross, BOX.mr) -- mid separator
      set_extmark(buf, ns_table, hrow, raw, { { hl_str, HL.border } })
    end

    -- Data rows
    for di, entry in ipairs(block.data) do
      local drow   = entry.row
      local raw    = entry.line
      local cells  = split_cells(raw:gsub("\\\\%s*$", ""))
      local hl     = (di == 1) and HL.header or HL.cell
      local parts  = { { BOX.v .. " ", HL.border } }
      for ci = 1, n do
        table.insert(parts, { fit(cells[ci] or "", cw), hl })
        table.insert(parts, { " " .. BOX.v .. " ", HL.border })
      end
      set_extmark(buf, ns_table, drow, raw, parts)
    end
  end
end

-- ── DTMdisplaydate concealment ────────────────────────────────────────────────

function M.conceal_dtmdates(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, ns_dtm, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for i, line in ipairs(lines) do
    local start_pos = 1
    while true do
      local s, e, y, m, d = line:find(
        "\\DTMdisplaydate%{(%d+)%}%{(%d+)%}%{(%d+)%}%{.-}",
        start_pos
      )
      if not s then break end

      local display = fmt_date(y, m, d)
      if display then
        vim.api.nvim_buf_set_extmark(buf, ns_dtm, i - 1, s - 1, {
          end_row = i - 1, end_col = e, conceal = "",
        })
        vim.api.nvim_buf_set_extmark(buf, ns_dtm, i - 1, s - 1, {
          virt_text     = { { display, "Comment" } },
          virt_text_pos = "inline",
          hl_mode       = "combine",
        })
      end
      start_pos = e + 1
    end
  end
end

-- ── externaldocument concealment ──────────────────────────────────────────────

function M.conceal_externdocs(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, ns_extern, 0, -1)

  local bufpath = vim.api.nvim_buf_get_name(buf)
  local dir     = bufpath:match("^(.*)/[^/]*$") or "."
  local lines   = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for i, line in ipairs(lines) do
    local docname = line:match("^\\externaldocument%{(.-)%}")
    if docname then
      local filepath = dir .. "/" .. docname .. ".tex"
      local title    = get_first_section(filepath)
      if title then
        local display = "[" .. docname .. "] " .. title
        vim.api.nvim_buf_set_extmark(buf, ns_extern, i - 1, 0, {
          end_row = i - 1, end_col = #line, conceal = "",
        })
        vim.api.nvim_buf_set_extmark(buf, ns_extern, i - 1, 0, {
          virt_text     = { { display, "Comment" } },
          virt_text_pos = "overlay",
          hl_mode       = "combine",
        })
      end
    end
  end
end

-- ── Combined refresh ──────────────────────────────────────────────────────────

function M.conceal_all(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  M.conceal_externdocs(buf)
  M.conceal_dtmdates(buf)
  M.conceal_tables(buf)
end

-- Clear all concealment on a single 0-based row
local function clear_row(buf, row)
  vim.api.nvim_buf_clear_namespace(buf, ns_extern, row, row + 1)
  vim.api.nvim_buf_clear_namespace(buf, ns_dtm,    row, row + 1)
  vim.api.nvim_buf_clear_namespace(buf, ns_table,  row, row + 1)
end

-- ── Setup ─────────────────────────────────────────────────────────────────────

function M.setup(user_config)
  if user_config then
    M.config = vim.tbl_extend("force", M.config, user_config)
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern  = "tex",
    callback = function(ev)
      local buf = ev.buf

      -- Initial render after filetype detection settles
      vim.defer_fn(function() M.conceal_all(buf) end, 50)

      -- Normal mode changes: undo, dd, paste, etc.
      vim.api.nvim_create_autocmd("TextChanged", {
        buffer   = buf,
        callback = function()
          vim.schedule(function() M.conceal_all(buf) end)
        end,
      })

      -- Entering insert: reveal only the line the cursor is on
      vim.api.nvim_create_autocmd("InsertEnter", {
        buffer   = buf,
        callback = function()
          local row = vim.api.nvim_win_get_cursor(0)[1] - 1
          clear_row(buf, row)
        end,
      })

      -- Moving between lines while in insert mode: re-conceal everything,
      -- then un-conceal only the new cursor line
      vim.api.nvim_create_autocmd("CursorMovedI", {
        buffer   = buf,
        callback = function()
          local row = vim.api.nvim_win_get_cursor(0)[1] - 1
          M.conceal_all(buf)
          clear_row(buf, row)
        end,
      })

      -- Typing in insert mode: re-render the full buffer so structure stays
      -- correct (e.g. new rows), then re-reveal only the cursor line
      vim.api.nvim_create_autocmd("TextChangedI", {
        buffer   = buf,
        callback = function()
          local row = vim.api.nvim_win_get_cursor(0)[1] - 1
          vim.schedule(function()
            M.conceal_all(buf)
            clear_row(buf, row)
          end)
        end,
      })

      -- Leaving insert: schedule so Neovim fully exits insert before we
      -- re-draw, preventing a race that left the cursor line un-concealed
      vim.api.nvim_create_autocmd("InsertLeave", {
        buffer   = buf,
        callback = function()
          vim.schedule(function() M.conceal_all(buf) end)
        end,
      })
    end,
  })
end

return M
