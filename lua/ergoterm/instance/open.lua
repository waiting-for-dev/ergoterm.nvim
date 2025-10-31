---@diagnostic disable: invisible

---@module "ergoterm.lazy"
local lazy = require("ergoterm.lazy")

---@module "ergoterm.utils"
local utils = lazy.require("ergoterm.utils")

local NEW_WINDOW_LAYOUTS = { "above", "below", "left", "right", "float" }
local TAB_LAYOUT = "tab"
local CURRENT_WINDOW_LAYOUT = "window"

local M = {}

---@param term Terminal
---@param layout layout?
function M.open(term, layout)
  if not term:is_started() then term:start() end
  return M.show(term, layout)
end

---@param term Terminal
function M.is_open(term)
  if not term._state.window then return false end
  for _, tab in pairs(vim.api.nvim_list_tabpages()) do
    for _, win in pairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.api.nvim_win_get_buf(win) == term._state.bufnr then
        return true
      end
    end
  end
  return false
end

---@param term Terminal
---@param layout layout?
function M.show(term, layout)
  if not M.is_open(term) then
    layout = layout or term._state.layout
    local window = nil
    if vim.tbl_contains(NEW_WINDOW_LAYOUTS, layout) then
      window = M._open_in_new_window(term, layout)
    elseif layout == TAB_LAYOUT then
      window = M._open_in_tab(term)
    elseif layout == CURRENT_WINDOW_LAYOUT then
      window = M._open_in_current_window(term)
    else
      utils.notify(
        string.format("Invalid layout option: %s", tostring(layout)),
        "error"
      )
      return term
    end
    term._state.layout = layout
    term._state.window = window
    term._state.tabpage = vim.api.nvim_win_get_tabpage(window)
    M._set_win_options(term)
    term:on_open()
  end
  return term
end

---@private
---@param term Terminal
---@param layout layout
function M._open_in_new_window(term, layout)
  local win_config = term:_compute_win_config(layout)
  return vim.api.nvim_open_win(term._state.bufnr, false, win_config)
end

---@private
---@param term Terminal
function M._open_in_tab(term)
  local current_window = vim.api.nvim_get_current_win()
  vim.cmd("tabnew")
  vim.bo.bufhidden = "wipe"
  vim.cmd("noautocmd call nvim_set_current_buf(" .. term._state.bufnr .. ")")
  local window = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(current_window)
  vim.defer_fn(function() vim.cmd("stopinsert") end, 100)
  return window
end

---@private
---@param term Terminal
function M._open_in_current_window(term)
  vim.api.nvim_set_current_buf(term._state.bufnr)
  return vim.api.nvim_get_current_win()
end

---@private
---@param term Terminal
function M._set_win_options(term)
  local window = term._state.window
  vim.api.nvim_set_option_value("number", false, { scope = "local", win = window })
  vim.api.nvim_set_option_value("signcolumn", "no", { scope = "local", win = window })
  vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = window })
  vim.api.nvim_set_option_value("foldmethod", "manual", { scope = "local", win = window })
  vim.api.nvim_set_option_value("foldtext", "foldtext()", { scope = "local", win = window })
  if term._state.layout == "float" then
    M._set_float_options(term)
  end
end

---@private
function M._set_float_options(term)
  local window = term._state.window
  vim.api.nvim_set_option_value("sidescrolloff", 0, { scope = "local", win = window })
  vim.api.nvim_set_option_value("winblend", term.float_winblend, { scope = "local", win = window })
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.open(...)
  end
})
