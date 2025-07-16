--- Lazy require a module.
---
--- Will only actually require the module when the first index is accessed.
--- Only works for modules that export a table.
---
--- @module "ergoterm.lazy"

local M = {}

--- Require on index.
---
---@param require_path string
---@return table
---@see ergoterm.lazy
M.require = function(require_path)
  return setmetatable({}, {
    __index = function(_, key) return require(require_path)[key] end,

    __newindex = function(_, key, value) require(require_path)[key] = value end,
  })
end

return M
