--- Entry point for the plugin.
---
---@module "ergoterm.lazy"
local lazy = require("ergoterm.lazy")

---@module "ergoterm.autocommands"
local autocommands = lazy.require("ergoterm.autocommands")
---@module "ergoterm.commands"
local commands = lazy.require("ergoterm.commands")
---@module "ergoterm.config"
local config = lazy.require("ergoterm.config")

local M = {}

--- Setup the plugin.
---
--- @param user_prefs ErgoTermConfig
--- @return nil
function M.setup(user_prefs)
  local conf = config.set(user_prefs)
  commands.setup(conf)
  autocommands.setup()
  return nil
end

return M
