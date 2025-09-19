---Configuration

---@class PickerCallbackDefinition
---@field fn fun(term: Terminal) the function to run when the user selects a terminal
---@field desc string the description of the action

---@class Picker
---@field select fun(terminals: Terminal[], prompt: string, callbacks: table<string, PickerCallbackDefinition>): any

---@alias PickerName "fzf-lua" | "telescope" | "vim-ui-select"
---@alias PickerOption Picker | PickerName | nil

local M = {}

M.NULL_CALLBACK = function(...) end

---@alias layout "window" | "below" | "left" | "right" | "tab" | "above" | "float"
---@alias on_close fun(term: Terminal)
---@alias on_create fun(term: Terminal)
---@alias on_focus fun(term: Terminal)
---@alias on_job_exit fun(t: Terminal, job: number, exit_code: number, event: string)
---@alias on_job_stdout fun(t: Terminal, channel_id: number, data: string[], name: string)
---@alias on_job_stderr fun(t: Terminal, channel_id: number, data: string[], name: string)
---@alias on_open fun(term: Terminal)
---@alias on_stop fun(term: Terminal)
---@alias on_start fun(term: Terminal)

---@class FloatOpts
---@field title_pos? string
---@field width? number
---@field height? number
---@field relative? string
---@field border? string
---@field zindex? number
---@field title? string
---@field row? number
---@field col? number

---@class SizeOpts
---@field below? string|number
---@field above? string|number
---@field left? string|number
---@field right? string|number

---@class TerminalDefaults
---@field auto_scroll boolean?
---@field watch_files boolean?
---@field clear_env boolean?
---@field cleanup_on_success boolean?
---@field cleanup_on_failure boolean?
---@field layout layout?
---@field float_opts FloatOpts?
---@field float_winblend number?
---@field on_close on_close?
---@field on_create on_create?
---@field on_focus on_focus?
---@field on_job_exit on_job_exit?
---@field on_job_stdout on_job_stdout?
---@field on_job_stderr on_job_stderr?
---@field on_open on_open?
---@field on_stop on_stop?
---@field on_start on_start?
---@field persist_mode boolean?
---@field shell string|fun():string?
---@field selectable boolean?
---@field size SizeOpts?
---@field start_in_insert boolean?
---@field sticky boolean?
---@field tags string[]?

---@class PickerConfig
---@field picker PickerOption?
---@field select_actions table<string, PickerCallbackDefinition>?
---@field extra_select_actions table<string, PickerCallbackDefinition>?

---@class ErgoTermConfig
---@field terminal_defaults TerminalDefaults?
---@field picker PickerConfig?

---@type ErgoTermConfig
local config = {
  terminal_defaults = {
    auto_scroll = false,
    watch_files = false,
    clear_env = false,
    cleanup_on_success = true,
    cleanup_on_failure = false,
    layout = "below",
    float_opts = {
      title_pos = "left",
      relative = "editor",
      border = "single",
      zindex = 50
    },
    float_winblend = 10,
    persist_mode = false,
    selectable = true,
    sticky = false,
    size = {
      below = "50%",
      above = "50%",
      left = "50%",
      right = "50%"
    },
    on_close = M.NULL_CALLBACK,
    on_create = M.NULL_CALLBACK,
    on_focus = M.NULL_CALLBACK,
    on_job_exit = M.NULL_CALLBACK,
    on_open = M.NULL_CALLBACK,
    on_stop = M.NULL_CALLBACK,
    on_start = M.NULL_CALLBACK,
    on_job_stderr = M.NULL_CALLBACK,
    on_job_stdout = M.NULL_CALLBACK,
    shell = vim.o.shell,
    start_in_insert = true,
    tags = {},
  },
  picker = {
    picker = nil,
    select_actions = {
      default = { fn = function(term) term:focus() end, desc = "Open" },
      ["<C-s>"] = { fn = function(term) term:focus("below") end, desc = "Open in horizontal split" },
      ["<C-v>"] = { fn = function(term) term:focus("right") end, desc = "Open in vertical split" },
      ["<C-t>"] = { fn = function(term) term:focus("tab") end, desc = "Open in tab" },
      ["<C-f>"] = { fn = function(term) term:focus("float") end, desc = "Open in float window" }
    },
    extra_select_actions = {}
  }
}

---Get the picker to select terminals
---
---If the `picker.picker` field is set in the config, it will return that.
---
---@param conf ErgoTermConfig
---
---@return Picker
function M.build_picker(conf)
  local picker_option = conf.picker.picker
  if picker_option == nil then
    return M._detect_picker()
  elseif type(picker_option) == "string" then
    return M._get_picker_by_name(picker_option)
  else
    ---@diagnostic disable-next-line: return-type-mismatch
    return picker_option
  end
end

function M._detect_picker()
  if pcall(require, "telescope") then
    return require("ergoterm.pickers.p_telescope")
  elseif pcall(require, "fzf-lua") then
    return require("ergoterm.pickers.p_fzf_lua")
  else
    return require("ergoterm.pickers.p_vim_ui_select")
  end
end

--- @private
function M._get_picker_by_name(name)
  if name == "telescope" then
    return require("ergoterm.pickers.p_telescope")
  elseif name == "fzf-lua" then
    return require("ergoterm.pickers.p_fzf_lua")
  elseif name == "vim-ui-select" then
    return require("ergoterm.pickers.p_vim_ui_select")
  else
    error("Unknown picker name: " .. name)
  end
end

--- get the full user config or just a specified value
---@param key string?
---@return any
function M.get(key)
  if not key then return config end
  local parts = vim.split(key, ".", { plain = true })
  local current = config

  for _, part in ipairs(parts) do
    if type(current) == "table" and current[part] ~= nil then
      current = current[part]
    else
      return nil
    end
  end

  return current
end

---@param user_conf ErgoTermConfig
---@return ErgoTermConfig
function M.set(user_conf)
  user_conf = user_conf or {}
  config = vim.tbl_deep_extend("force", config, user_conf)
  return config
end

---@return ErgoTermConfig
return setmetatable(M, {
  __index = function(_, k) return config[k] end,
})
