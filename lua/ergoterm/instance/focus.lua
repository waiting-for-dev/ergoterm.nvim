---@module "ergoterm.collection"
local on_buf_enter = require("ergoterm.events.on_buf_enter")

local M = {}

---@param term Terminal
---@param layout layout
function M.focus(term, layout)
  if not term:is_open() then term:open(layout) end
  if not M.is_focused(term) then
    vim.api.nvim_set_current_win(term._state.window)
    on_buf_enter(term)
  end
  return term
end

---@param term Terminal
function M.is_focused(term)
  return term._state.window == vim.api.nvim_get_current_win()
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.focus(...)
  end
})
