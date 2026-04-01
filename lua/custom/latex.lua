local M = {}

-- ── Namespaces ────────────────────────────────────────────────────────────────
local ns_extern = vim.api.nvim_create_namespace("latex_externdoc")
local ns_dtm    = vim.api.nvim_create_namespace("latex_dtmdate")

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

-- ── DTMdisplaydate concealment ────────────────────────────────────────────────

function M.conceal_dtmdates(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, ns_dtm, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for i, line in ipairs(lines) do
    -- Match \DTMdisplaydate{year}{month}{day}{dow} anywhere in the line
    local start_pos = 1
    while true do
      local s, e, y, m, d = line:find(
        "\\DTMdisplaydate%{(%d+)%}%{(%d+)%}%{(%d+)%}%{.-}",
        start_pos
      )
      if not s then break end

      local display = fmt_date(y, m, d)
      if display then
        -- Hide the raw \DTMdisplaydate{...}{...}{...}{...} span
        vim.api.nvim_buf_set_extmark(buf, ns_dtm, i - 1, s - 1, {
          end_row  = i - 1,
          end_col  = e,
          conceal  = "",
        })
        -- Insert the formatted date as inline virtual text at the same position
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
  local dir = bufpath:match("^(.*)/[^/]*$") or "."
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for i, line in ipairs(lines) do
    local docname = line:match("^\\externaldocument%{(.-)%}")
    if docname then
      local filepath = dir .. "/" .. docname .. ".tex"
      local title = get_first_section(filepath)
      if title then
        local display = "[" .. docname .. "] " .. title
        vim.api.nvim_buf_set_extmark(buf, ns_extern, i - 1, 0, {
          end_row = i - 1,
          end_col = #line,
          conceal = "",
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
end

local function clear_line(buf, row)
  vim.api.nvim_buf_clear_namespace(buf, ns_extern, row, row + 1)
  vim.api.nvim_buf_clear_namespace(buf, ns_dtm,    row, row + 1)
end

-- ── Setup ─────────────────────────────────────────────────────────────────────

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern  = "tex",
    callback = function(ev)
      local buf = ev.buf

      vim.defer_fn(function()
        M.conceal_all(buf)
      end, 50)

      -- Reveal only current line in insert mode
      vim.api.nvim_create_autocmd("CursorMovedI", {
        buffer   = buf,
        callback = function()
          M.conceal_all(buf)
          local row = vim.api.nvim_win_get_cursor(0)[1] - 1
          clear_line(buf, row)
        end,
      })

      vim.api.nvim_create_autocmd("InsertEnter", {
        buffer   = buf,
        callback = function()
          local row = vim.api.nvim_win_get_cursor(0)[1] - 1
          clear_line(buf, row)
        end,
      })

      vim.api.nvim_create_autocmd("InsertLeave", {
        buffer   = buf,
        callback = function()
          M.conceal_all(buf)
        end,
      })

      vim.keymap.set("i", "<C-c>", function()
        vim.cmd("stopinsert")
        M.conceal_all(buf)
      end, { buffer = buf, desc = "Exit insert and restore conceal" })
    end,
  })

  vim.keymap.set("n", "<leader>te", function()
    M.conceal_all()
  end, { desc = "Refresh LaTeX concealment" })
end

return M
