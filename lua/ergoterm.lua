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
---@module "ergoterm.collection"
local collection = require("ergoterm.collection")
---@module "ergoterm.instance"
local instance = require("ergoterm.instance")

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

M.find = collection.find
M.get_focused = collection.get_focused
M.identify = collection.identify
M.get_last_focused = collection.get_last_focused
M.get = collection.get
M.get_by_name = collection.get_by_name
M.filter = collection.filter
M.get_all = collection.get_all
M.filter_by_tag = collection.filter_by_tag
M.select = collection.select
M.select_started = collection.select_started
M.cleanup_all = collection.cleanup_all
M.get_state = collection.get_state
M.toggle_universal_selection = collection.toggle_universal_selection
M.reset_ids = collection.reset_ids

M.Terminal = instance.Terminal

M.text_decorators = require("ergoterm.instance.send.text_decorators")

--- Create a new terminal instance.
---
--- @param args TerminalCreateSettings?
--- @return Terminal
function M:new(args)
  return instance.Terminal:new(args)
end

--- Create a factory for terminals with default settings.
---
--- @param custom_defaults TerminalCreateSettings Default settings for terminals created by the factory.
--- @return table A factory with a `new` method to create terminals with the specified defaults
function M.with_defaults(custom_defaults)
  return {
    new = function(_, args)
      args = args or {}
      local merged_args = vim.tbl_deep_extend("force", custom_defaults, args)
      return instance.Terminal:new(merged_args)
    end
  }
end

return M
