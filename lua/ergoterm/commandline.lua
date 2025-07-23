---@module "ergoterm.lazy"
local lazy = require("ergoterm.lazy")

---@module "ergoterm.utils"
local utils = lazy.require("ergoterm.utils")
---@module "ergoterm.text_decorators"
local text_decorators = lazy.require("ergoterm.text_decorators")

local M = {}

local p = {
  single = "'(.-)'",
  double = '"(.-)"',
}

---@class ParsedArgs
---@field layout string?
---@field cmd string?
---@field dir string?
---@field name string?
---@field action string?
---@field decorator string?
---@field trim boolean?
---@field new_line boolean?
---@field auto_scroll boolean?
---@field persist_mode boolean?
---@field selectable boolean?
---@field start_in_insert boolean?
---@field close_on_job_exit boolean?
---@field text string?
---@field trailing string?

---@see https://stackoverflow.com/a/27007701
---@param args string
---@return ParsedArgs
function M.parse(args)
  local result = {}
  if args then
    local quotes = args:match(p.single) and p.single or args:match(p.double) and p.double or nil
    if quotes then
      -- 1. extract the quoted command
      local pattern = "(%S+)=" .. quotes
      for key, value in args:gmatch(pattern) do
        -- Check if the current OS is Windows so we can determine if +shellslash
        -- exists and if it exists, then determine if it is enabled. In that way,
        -- we can determine if we should match the value with single or double quotes.
        if utils.is_windows() then
          quotes = not vim.opt.shellslash:get() and quotes or p.single
        else
          quotes = p.single
        end
        value = vim.fn.shellescape(value)
        result[vim.trim(key)] = vim.fn.expandcmd(value:match(quotes))
      end
      -- 2. then remove it from the rest of the argument string
      args = args:gsub(pattern, "")
    end

    for _, part in ipairs(vim.split(args, " ")) do
      if #part > 1 then
        local arg = vim.split(part, "=")
        local key, value = arg[1], arg[2]
        if key == "trim" or key == "new_line" or key == "auto_scroll" or key == "persist_mode" or key == "selectable" or key == "start_in_insert" or key == "close_on_job_exit" then
          value = M._toboolean(value)
        end
        result[key] = value
      end
    end

    -- capture trailing arguments as anything after the last key=value pair
    local trailing = args:match("%s+(.+)")
    if trailing then
      result.trailing = trailing
    end
  end
  return result
end

-- Get a valid base path for a user provided path
-- and an optional search term
---@param typed_path string
---@return string|nil, string|nil
function M._get_path_parts(typed_path)
  if vim.fn.isdirectory(typed_path ~= "" and typed_path or ".") == 1 then
    -- The string is a valid path, we just need to drop trailing slashes to
    -- ease joining the base path with the suggestions
    return typed_path:gsub("/$", ""), nil
  elseif typed_path:find("/", 2) ~= nil then
    -- Maybe the typed path is looking for a nested directory
    -- we need to make sure it has at least one slash in it, and that is not
    -- from a root path
    local base_path = vim.fn.fnamemodify(typed_path, ":h")
    local search_term = vim.fn.fnamemodify(typed_path, ":t")
    if vim.fn.isdirectory(base_path) then return base_path, search_term end
  end

  return nil, nil
end

M._all_options = {
  --- Suggests commands
  ---@param typed_cmd string|nil
  cmd = function(typed_cmd)
    local paths = vim.split(vim.env.PATH, ":")
    local commands = {}

    for _, path in ipairs(paths) do
      local glob_str
      if string.match(path, "%s*") then
        --path with spaces
        glob_str = path:gsub(" ", "\\ ") .. "/" .. (typed_cmd or "") .. "*"
      else
        -- path without spaces
        glob_str = path .. "/" .. (typed_cmd or "") .. "*"
      end
      local dir_cmds = vim.split(vim.fn.glob(glob_str), "\n")

      for _, cmd in ipairs(dir_cmds) do
        if not utils.str_is_empty(cmd) then table.insert(commands, vim.fn.fnamemodify(cmd, ":t")) end
      end
    end

    return commands
  end,
  --- Suggests paths in the cwd
  ---@param typed_path string
  dir = function(typed_path)
    -- Read the typed path as the base for the directory search
    local base_path, search_term = M._get_path_parts(typed_path or "")
    local safe_path = base_path ~= "" and base_path or "."

    local paths = vim.fn.readdir(
      safe_path,
      function(entry) return vim.fn.isdirectory(safe_path .. "/" .. entry) end
    )

    if not utils.str_is_empty(search_term) then
      paths = vim.tbl_filter(
        function(path) return path:match("^" .. search_term .. "*") ~= nil end,
        paths
      )
    end

    return vim.tbl_map(
      function(path) return table.concat(utils.tbl_filter_empty({ base_path, path }), "/") end,
      paths
    )
  end,
  --- Suggests layouts for the term
  ---@param typed_layout string
  layout = function(typed_layout)
    local layouts = {
      "float",
      "left",
      "right",
      "above",
      "below",
      "tab",
      "window",
    }
    if utils.str_is_empty(typed_layout) then return layouts end
    return vim.tbl_filter(
      function(layout) return layout:match("^" .. typed_layout .. "*") ~= nil end,
      layouts
    )
  end,
  --- The name param takes in arbitrary strings, we keep this function only to
  --- match the signature of other options
  name = function() return {} end,

  action = function(typed_action)
    local actions = {
      "interactive",
      "silent",
      "visible"
    }
    if utils.str_is_empty(typed_action) then return actions end
    return vim.tbl_filter(
      function(action) return action:match("^" .. typed_action .. "*") ~= nil end,
      actions
    )
  end,

  decorator = function(typed_decorator)
    local decorators = vim.tbl_values(text_decorators.DECORATORS)
    if utils.str_is_empty(typed_decorator) then return decorators end
    return vim.tbl_filter(
      function(decorator) return decorator:match("^" .. typed_decorator .. "*") ~= nil end,
      decorators
    )
  end,

  trim = function() return { "true", "false" } end,

  new_line = function() return { "true", "false" } end,

  auto_scroll = function() return { "true", "false" } end,

  persist_mode = function() return { "true", "false" } end,

  selectable = function() return { "true", "false" } end,

  start_in_insert = function() return { "true", "false" } end,

  close_on_job_exit = function() return { "true", "false" } end,
}

M._term_new_options = {
  cmd = M._all_options.cmd,
  dir = M._all_options.dir,
  layout = M._all_options.layout,
  name = M._all_options.name,
  auto_scroll = M._all_options.auto_scroll,
  persist_mode = M._all_options.persist_mode,
  selectable = M._all_options.selectable,
  start_in_insert = M._all_options.start_in_insert,
  close_on_job_exit = M._all_options.close_on_job_exit,
}

M._term_update_options = {
  layout = M._all_options.layout,
  name = M._all_options.name,
  auto_scroll = M._all_options.auto_scroll,
  persist_mode = M._all_options.persist_mode,
  selectable = M._all_options.selectable,
  start_in_insert = M._all_options.start_in_insert,
  close_on_job_exit = M._all_options.close_on_job_exit,
}

M._term_send_options = {
  text = M._all_options.cmd,
  action = M._all_options.action,
  decorator = M._all_options.decorator,
  trim = M._all_options.trim,
  new_line = M._all_options.new_line,
}

---@param value string
---@return boolean?
function M._toboolean(value)
  if value == "true" then
    return true
  elseif value == "false" then
    return false
  else
    utils.notify("Invalid value for boolean option, expected 'true' or 'false'", "error")
  end
end

---@param options table a dictionary of key to function
---@return fun(lead: string, command: string, _: number)
function M._complete(options)
  ---@param lead string the leading portion of the argument currently being completed on
  ---@param command string the entire command line
  ---@param _ number the cursor position in it (byte index)
  return function(lead, command, _)
    local parts = vim.split(lead, "=")
    local key = parts[1]
    local value = parts[2]
    if options[key] then
      return vim.tbl_map(function(option) return key .. "=" .. option end, options[key](value))
    end

    local available_options = vim.tbl_filter(
      function(option) return command:match(" " .. option .. "=") == nil end,
      vim.tbl_keys(options)
    )

    table.sort(available_options)

    return vim.tbl_map(function(option) return option .. "=" end, available_options)
  end
end

M.term_send_complete = M._complete(M._term_send_options)

M.term_new_complete = M._complete(M._term_new_options)

M.term_update_complete = M._complete(M._term_update_options)

return M
