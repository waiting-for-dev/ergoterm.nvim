---@diagnostic disable: invisible

---@module "ergoterm.size"
local size_utils = require("ergoterm.size_utils")

local SPLIT_LAYOUTS = { "above", "below", "left", "right" }

local M = {}

---@param term Terminal
function M.on_win_closed(term)
  if term.persist_size then
    M._persist_size(term)
  end
  M._close_window_or_replace_with_empty_buf_if_last(term)
  term:on_close()
end

---@private
---@param term Terminal
function M._close_window_or_replace_with_empty_buf_if_last(term)
  if #vim.api.nvim_list_wins() == 1 then
    local empty_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(term._state.window, empty_buf)
  else
    vim.api.nvim_win_close(term._state.window, true)
  end
end

---@private
---@param term Terminal
function M._persist_size(term)
  local layout = term._state.layout
  if not vim.tbl_contains(SPLIT_LAYOUTS, layout) then return end

  local current_axis_absolute_size
  local current_axis_size
  if size_utils.is_vertical(layout) then
    current_axis_absolute_size = vim.api.nvim_win_get_width(term._state.window)
  else
    current_axis_absolute_size = vim.api.nvim_win_get_height(term._state.window)
  end
  if size_utils.is_percentage(term.size[layout]) then
    current_axis_size = size_utils.absolute_to_percentage(current_axis_absolute_size, layout)
  else
    current_axis_size = current_axis_absolute_size
  end
  term._state.size[layout] = current_axis_size
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.on_win_closed(...)
  end
})
