local on_win_closed = require("ergoterm.events.on_win_closed")

local M = {}

--- @param term Terminal
function M.close(term)
  if term:is_open() then
    on_win_closed(term)
  end
  return term
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.close(...)
  end
})
