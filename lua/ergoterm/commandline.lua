---@module "ergoterm.utils"
local utils = require("ergoterm.utils")
---@module "ergoterm.config"
local config = require("ergoterm.config")
---@module "ergoterm.collection"
local collection = require("ergoterm.collection")

local M = {}

local p = {
  single = "'(.-)'",
  double = '"(.-)"',
}

M.nested_table_settings = {
  size = { "below", "above", "left", "right" },
  float_opts = { "title_pos", "width", "height", "relative", "border", "zindex", "title", "row", "col" },
  meta = {}
}

M.list_settings = {
  tags = true
}

function M._is_nested_setting(key)
  local parts = vim.split(key, ".", { plain = true })
  if #parts == 2 then
    return M.nested_table_settings[parts[1]] ~= nil
  end
  return false
end

function M.is_list_setting(key)
  return M.list_settings[key] == true
end

---@class ParsedArgs
---@field layout string?
---@field cmd string?
---@field dir string?
---@field name string?
---@field target string?
---@field action string?
---@field decorator string?
---@field trim boolean?
---@field new_line boolean?
---@field auto_scroll boolean?
---@field bang_target boolean?
---@field watch_files boolean?
---@field persist_mode boolean?
---@field persist_size boolean?
---@field auto_list boolean?
---@field start_in_insert boolean?
---@field sticky boolean?
---@field cleanup_on_success boolean?
---@field cleanup_on_failure boolean?
---@field scrollback number?
---@field show_on_success boolean?
---@field show_on_failure boolean?
---@field text string?
---@field trailing string?
---@field size Size?
---@field float_opts FloatOpts?
---@field tags string[]?
---@field meta table<string, string|number>?

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

    local boolean_options = {
      trim = true,
      new_line = true,
      auto_scroll = true,
      bang_target = true,
      watch_files = true,
      persist_mode = true,
      persist_size = true,
      auto_list = true,
      start_in_insert = true,
      sticky = true,
      cleanup_on_success = true,
      cleanup_on_failure = true,
      show_on_success = true,
      show_on_failure = true
    }

    local parts_list = vim.split(args, " ")
    local last_key_value_index = 0

    for i, part in ipairs(parts_list) do
      if #part > 1 and part:match("=") then
        last_key_value_index = i
        local arg = vim.split(part, "=")
        local key, value = arg[1], arg[2]
        if boolean_options[key] then
          value = M._toboolean(value)
        end

        if M.is_list_setting(key) then
          result[key] = vim.split(value, ",")
        elseif M._is_nested_setting(key) then
          local parts = vim.split(key, ".", { plain = true })
          local top_key = parts[1]
          local nested_key = parts[2]
          result[top_key] = result[top_key] or {}
          result[top_key][nested_key] = tonumber(value) or value
        else
          result[key] = value
        end
      end
    end

    if last_key_value_index > 0 and last_key_value_index < #parts_list then
      local trailing_parts = {}
      for i = last_key_value_index + 1, #parts_list do
        table.insert(trailing_parts, parts_list[i])
      end
      if #trailing_parts > 0 then
        result.trailing = table.concat(trailing_parts, " ")
      end
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

---@return string[]
function M._boolean_options()
  return { "true", "false" }
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

  target = function(typed_name)
    local terminals = collection.get_all()
    local names = vim.tbl_map(function(term) return term.name end, terminals)
    if utils.str_is_empty(typed_name) then return names end
    return vim.tbl_filter(
      function(name) return name:match("^" .. vim.pesc(typed_name)) ~= nil end,
      names
    )
  end,

  action = function(typed_action)
    local actions = {
      "focus",
      "open",
      "start"
    }
    if utils.str_is_empty(typed_action) then return actions end
    return vim.tbl_filter(
      function(action) return action:match("^" .. typed_action .. "*") ~= nil end,
      actions
    )
  end,

  decorator = function(typed_decorator)
    local decorators = vim.tbl_keys(config.get_text_decorators())
    if utils.str_is_empty(typed_decorator) then return decorators end
    return vim.tbl_filter(
      function(decorator) return decorator:match("^" .. typed_decorator .. "*") ~= nil end,
      decorators
    )
  end,

  trim = M._boolean_options,

  new_line = M._boolean_options,

  auto_scroll = M._boolean_options,

  bang_target = M._boolean_options,

  watch_files = M._boolean_options,

  persist_mode = M._boolean_options,

  persist_size = M._boolean_options,

  auto_list = M._boolean_options,

  start_in_insert = M._boolean_options,

  sticky = M._boolean_options,

  cleanup_on_success = M._boolean_options,

  cleanup_on_failure = M._boolean_options,

  scrollback = function() return {} end,

  show_on_success = M._boolean_options,

  show_on_failure = M._boolean_options,

  ["size.below"] = function() return {} end,

  ["size.above"] = function() return {} end,

  ["size.left"] = function() return {} end,

  ["size.right"] = function() return {} end,

  ["float_opts.title_pos"] = function(typed_value)
    local positions = { "left", "center", "right" }
    if utils.str_is_empty(typed_value) then return positions end
    return vim.tbl_filter(
      function(pos) return pos:match("^" .. typed_value .. "*") ~= nil end,
      positions
    )
  end,

  ["float_opts.width"] = function() return {} end,

  ["float_opts.height"] = function() return {} end,

  ["float_opts.relative"] = function(typed_value)
    local relatives = { "editor", "win", "cursor", "mouse", "laststatus", "tabline" }
    if utils.str_is_empty(typed_value) then return relatives end
    return vim.tbl_filter(
      function(rel) return rel:match("^" .. typed_value .. "*") ~= nil end,
      relatives
    )
  end,

  ["float_opts.border"] = function(typed_value)
    local borders = { "none", "single", "double", "rounded", "solid", "shadow", "bold" }
    if utils.str_is_empty(typed_value) then return borders end
    return vim.tbl_filter(
      function(border) return border:match("^" .. typed_value .. "*") ~= nil end,
      borders
    )
  end,

  ["float_opts.zindex"] = function() return {} end,

  ["float_opts.title"] = function() return {} end,

  ["float_opts.row"] = function() return {} end,

  ["float_opts.col"] = function() return {} end,

  tags = function() return {} end,

  ["meta."] = function() return {} end
}

M._term_new_options = {
  cmd = M._all_options.cmd,
  dir = M._all_options.dir,
  layout = M._all_options.layout,
  name = M._all_options.name,
  auto_scroll = M._all_options.auto_scroll,
  bang_target = M._all_options.bang_target,
  watch_files = M._all_options.watch_files,
  persist_mode = M._all_options.persist_mode,
  persist_size = M._all_options.persist_size,
  auto_list = M._all_options.auto_list,
  start_in_insert = M._all_options.start_in_insert,
  sticky = M._all_options.sticky,
  cleanup_on_success = M._all_options.cleanup_on_success,
  cleanup_on_failure = M._all_options.cleanup_on_failure,
  scrollback = M._all_options.scrollback,
  show_on_success = M._all_options.show_on_success,
  show_on_failure = M._all_options.show_on_failure,
  ["size.below"] = M._all_options["size.below"],
  ["size.above"] = M._all_options["size.above"],
  ["size.left"] = M._all_options["size.left"],
  ["size.right"] = M._all_options["size.right"],
  ["float_opts.title_pos"] = M._all_options["float_opts.title_pos"],
  ["float_opts.width"] = M._all_options["float_opts.width"],
  ["float_opts.height"] = M._all_options["float_opts.height"],
  ["float_opts.relative"] = M._all_options["float_opts.relative"],
  ["float_opts.border"] = M._all_options["float_opts.border"],
  ["float_opts.zindex"] = M._all_options["float_opts.zindex"],
  ["float_opts.title"] = M._all_options["float_opts.title"],
  ["float_opts.row"] = M._all_options["float_opts.row"],
  ["float_opts.col"] = M._all_options["float_opts.col"],
  tags = M._all_options.tags,
  ["meta."] = M._all_options["meta."]
}

M._term_update_options = {
  target = M._all_options.target,
  layout = M._all_options.layout,
  name = M._all_options.name,
  auto_scroll = M._all_options.auto_scroll,
  bang_target = M._all_options.bang_target,
  watch_files = M._all_options.watch_files,
  persist_mode = M._all_options.persist_mode,
  persist_size = M._all_options.persist_size,
  auto_list = M._all_options.auto_list,
  start_in_insert = M._all_options.start_in_insert,
  sticky = M._all_options.sticky,
  cleanup_on_success = M._all_options.cleanup_on_success,
  cleanup_on_failure = M._all_options.cleanup_on_failure,
  show_on_success = M._all_options.show_on_success,
  show_on_failure = M._all_options.show_on_failure,
  ["size.below"] = M._all_options["size.below"],
  ["size.above"] = M._all_options["size.above"],
  ["size.left"] = M._all_options["size.left"],
  ["size.right"] = M._all_options["size.right"],
  ["float_opts.title_pos"] = M._all_options["float_opts.title_pos"],
  ["float_opts.width"] = M._all_options["float_opts.width"],
  ["float_opts.height"] = M._all_options["float_opts.height"],
  ["float_opts.relative"] = M._all_options["float_opts.relative"],
  ["float_opts.border"] = M._all_options["float_opts.border"],
  ["float_opts.zindex"] = M._all_options["float_opts.zindex"],
  ["float_opts.title"] = M._all_options["float_opts.title"],
  ["float_opts.row"] = M._all_options["float_opts.row"],
  ["float_opts.col"] = M._all_options["float_opts.col"],
  tags = M._all_options.tags,
  ["meta."] = M._all_options["meta."]
}

M._term_send_options = {
  target = M._all_options.target,
  text = M._all_options.cmd,
  action = M._all_options.action,
  decorator = M._all_options.decorator,
  trim = M._all_options.trim,
  new_line = M._all_options.new_line,
}

M._term_select_options = {
  target = M._all_options.target,
}

M._term_inspect_options = {
  target = M._all_options.target,
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

    if not utils.str_is_empty(lead) then
      available_options = vim.tbl_filter(
        function(option) return option:match("^" .. lead) ~= nil end,
        available_options
      )
    end

    table.sort(available_options)

    return vim.tbl_map(function(option) return option .. "=" end, available_options)
  end
end

M.term_send_complete = M._complete(M._term_send_options)

M.term_new_complete = M._complete(M._term_new_options)

M.term_update_complete = M._complete(M._term_update_options)

M.term_select_complete = M._complete(M._term_select_options)

M.term_inspect_complete = M._complete(M._term_inspect_options)

return M
