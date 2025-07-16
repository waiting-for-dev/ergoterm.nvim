local M = {}

---@alias selection_type "single_line" | "visual_lines" | "visual_selection" | "line" | "char"

---@param selection_type selection_type
function M.select(selection_type)
  local lines = {}
  -- Beginning of the selection: line number, column number
  local start_line, start_col
  if selection_type == "single_line" then
    start_line, start_col = unpack(vim.api.nvim_win_get_cursor(0))
    -- nvim_win_get_cursor uses 0-based indexing for columns, while we use 1-based indexing
    start_col = start_col + 1
    table.insert(lines, vim.fn.getline(start_line))
  else
    local res = nil
    if string.match(selection_type, "visual") then
      -- This calls vim.fn.getpos, which uses 1-based indexing for columns
      res = M._get_line_selection("visual")
    else
      -- This calls vim.fn.getpos, which uses 1-based indexing for columns
      res = M._get_line_selection("motion")
    end
    start_line, start_col = unpack(res.start_pos)
    -- char, line and block are used for motion/operatorfunc. 'block' is ignored
    if selection_type == "visual_lines" or selection_type == "line" then
      lines = res.selected_lines
    elseif selection_type == "visual_selection" or selection_type == "char" then
      lines = M._get_visual_selection(res, true)
    end
  end
  if not lines or not next(lines) then
    return
  else
    return lines
  end
end

function M._get_visual_selection(res, motion)
  motion = motion or false
  local mode = vim.fn.visualmode()
  if motion then mode = "v" end

  -- line-visual
  -- return lines encompassed by the selection; already in res object
  if mode == "V" then return res.selected_lines end

  if mode == "v" then
    -- regular-visual
    -- return the buffer text encompassed by the selection
    local start_line, start_col = unpack(res.start_pos)
    local end_line, end_col = unpack(res.end_pos)
    -- exclude the last char in text if "selection" is set to "exclusive"
    if vim.opt.selection:get() == "exclusive" then end_col = end_col - 1 end
    return vim.api.nvim_buf_get_text(0, start_line - 1, start_col - 1, end_line - 1, end_col, {})
  end

  -- block-visual
  -- return the lines encompassed by the selection, each truncated by the start and end columns
  if mode == string.char(22) then
    local _, start_col = unpack(res.start_pos)
    local _, end_col = unpack(res.end_pos)
    -- exclude the last col of the block if "selection" is set to "exclusive"
    if vim.opt.selection:get() == "exclusive" then end_col = end_col - 1 end
    -- exchange start and end columns for proper substring indexing if needed
    -- e.g. instead of str:sub(10, 5), do str:sub(5, 10)
    if start_col > end_col then
      start_col, end_col = end_col, start_col
    end
    -- iterate over lines, truncating each one
    return vim.tbl_map(function(line) return line:sub(start_col, end_col) end, res.selected_lines)
  end
end

function M._get_line_selection(mode)
  local start_char, end_char = unpack(({
    visual = { "'<", "'>" },
    motion = { "'[", "']" },
  })[mode])
  -- '< marks are only updated when one leaves visual mode.
  -- When calling lua functions directly from a mapping, need to
  -- explicitly exit visual with the escape key to ensure those marks are
  -- accurate.
  vim.cmd("normal! ")

  -- Get the start and the end of the selection
  local start_line, start_col = unpack(vim.fn.getpos(start_char), 2, 3)
  local end_line, end_col = unpack(vim.fn.getpos(end_char), 2, 3)
  local selected_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  return {
    start_pos = { start_line, start_col },
    end_pos = { end_line, end_col },
    selected_lines = selected_lines,
  }
end

return M
