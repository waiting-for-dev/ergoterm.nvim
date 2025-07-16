local M = {}

local utils = require("ergoterm.utils")

M.mocking_notify = function(callback)
  local result = nil
  local original_notify = utils.notify
  ---@diagnostic disable-next-line: duplicate-set-field
  utils.notify = function(msg, level)
    result = {
      msg = msg,
      level = level
    }
  end
  callback()
  utils.notify = original_notify
  return result
end

return M
