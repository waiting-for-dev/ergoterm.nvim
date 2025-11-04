---@diagnostic disable: invisible

---@module "ergoterm.events.on_win_leave"
local on_win_leave = require("ergoterm.events.on_win_leave")

local M = {}

---@param term Terminal
---@param win_id number?
function M.unfocus(term, win_id)
  if term:is_focused() then
    on_win_leave(term)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_set_current_win(win_id)
    end
  end
  return term
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.unfocus(...)
  end
})
