---ErgoTerm vim commands

---@module "ergoterm.lazy"
local lazy = require("ergoterm.lazy")

---@module "ergoterm.commandline"
local commandline = lazy.require("ergoterm.commandline")
---@module "ergoterm.config"
local config = lazy.require("ergoterm.config")
---@module "ergoterm.terminal"
local terms = lazy.require("ergoterm.terminal")
---@module "ergoterm.utils"
local utils = lazy.require("ergoterm.utils")

local M = {}

---Creates and opens a new terminal with parsed arguments
---
---Parses command-line arguments to extract terminal configuration options.
---The terminal is automatically focused after creation. Arguments are validated
---before terminal creation.
---
---@param args string command-line arguments in "key=value" format
---@return Terminal the created and focused terminal
function M.new(args)
  local parsed = commandline.parse(args)
  vim.validate({
    cmd = { parsed.cmd, "string", true },
    dir = { parsed.dir, "string", true },
    layout = { parsed.layout, "string", true },
    name = { parsed.name, "string", true },
    auto_scroll = { parsed.auto_scroll, "boolean", true },
    bang_target = { parsed.bang_target, "boolean", true },
    watch_files = { parsed.watch_files, "boolean", true },
    persist_mode = { parsed.persist_mode, "boolean", true },
    selectable = { parsed.selectable, "boolean", true },
    start_in_insert = { parsed.start_in_insert, "boolean", true },
    sticky = { parsed.sticky, "boolean", true },
    cleanup_on_success = { parsed.cleanup_on_success, "boolean", true },
    cleanup_on_failure = { parsed.cleanup_on_failure, "boolean", true },
    open_on_success = { parsed.open_on_success, "boolean", true },
    open_on_failure = { parsed.open_on_failure, "boolean", true }
  })
  return terms.Terminal:new({
    cmd = parsed.cmd,
    dir = parsed.dir,
    layout = parsed.layout,
    name = parsed.name,
    auto_scroll = parsed.auto_scroll,
    bang_target = parsed.bang_target,
    watch_files = parsed.watch_files,
    persist_mode = parsed.persist_mode,
    selectable = parsed.selectable,
    start_in_insert = parsed.start_in_insert,
    sticky = parsed.sticky,
    cleanup_on_success = parsed.cleanup_on_success,
    cleanup_on_failure = parsed.cleanup_on_failure,
    open_on_success = parsed.open_on_success,
    open_on_failure = parsed.open_on_failure
  }):focus()
end

---Allows selection of a terminal
---
---Bang mode (!) focuses the last focused terminal directly.
---
---Without bang mode, it displays all available terminals in the configured picker interface.
---Available actions depend on the picker's `select_actions` configuration.
---
---@param bang boolean true to use last focused terminal
---@param picker Picker the picker implementation to use for selection
---@return boolean success status of the operation
function M.select(bang, picker)
  if bang then
    return M._execute_on_last_focused(function(t) t:focus() end)
  else
    return terms.select(nil, "Please select a terminal to open (or focus): ", nil, picker)
  end
end

---Sends text to a terminal with flexible input sources
---
---Text can be provided explicitly via the `text` argument, or automatically
---extracted based on context:
---• Normal mode: current line under cursor
---• Visual selection: selected text (character-wise or line-wise)
---
---Action modes control terminal behavior:
---• "interactive" - opens and focuses terminal (default)
---• "visible" - opens terminal but maintains current focus
---• "silent" - sends without changing terminal visibility
---
---Text processing options:
---• trim: removes leading/trailing whitespace (default: true)
---• new_line: appends newline for command execution (default: true)
---• decorator: transforms text before sending (identity, markdown_code)
---
---Bang mode (!) uses the last focused terminal directly, otherwise prompts
---for terminal selection via picker.
---
---@param args string command-line arguments with send options
---@param range number 0 for no range, >0 for visual range
---@param bang boolean true to use last focused terminal
---@param picker Picker interface for terminal selection
---@return boolean success status of the operation
function M.send(args, range, bang, picker)
  local parsed = commandline.parse(args)
  vim.validate({
    text = { parsed.text, "string", true },
    action = { parsed.action, "string", true },
    decorator = { parsed.decorator, "string", true },
    trim = { parsed.trim, "boolean", true },
    new_line = { parsed.new_line, "boolean", true },
  })
  local selection = range == 0 and "single_line" or
      (vim.fn.visualmode() == "V" and "visual_lines" or "visual_selection")
  local input = parsed.text and { parsed.text } or selection

  local send_to_terminal = function(t)
    t:send(input, {
      action = parsed.action,
      trim = parsed.trim,
      new_line = parsed.new_line,
      decorator = parsed.decorator
    })
  end
  if bang then
    return M._execute_on_last_focused(send_to_terminal)
  else
    return terms.select(nil, "Please select a terminal to send text: ",
      { default = { fn = send_to_terminal, desc = "send-text" } }, picker)
  end
end

---Updates terminal configuration after creation
---
---Allows modification of terminal settings without recreating the terminal.
---Updatable fields include layout, name, auto_scroll, persist_mode,
---selectable, and start_in_insert. Changes take effect immediately.
---
---Bang mode (!) targets the last focused terminal directly, otherwise
---prompts for terminal selection.
---
---@param args string command-line arguments with update options
---@param bang boolean true to use last focused terminal
---@param picker Picker interface for terminal selection
---@return boolean success status of the operation
function M.update(args, bang, picker)
  local parsed = commandline.parse(args)
  vim.validate({
    layout = { parsed.layout, "string", true },
    name = { parsed.name, "string", true },
    auto_scroll = { parsed.auto_scroll, "boolean", true },
    bang_target = { parsed.bang_target, "boolean", true },
    watch_files = { parsed.watch_files, "boolean", true },
    persist_mode = { parsed.persist_mode, "boolean", true },
    selectable = { parsed.selectable, "boolean", true },
    start_in_insert = { parsed.start_in_insert, "boolean", true },
    sticky = { parsed.sticky, "boolean", true },
    cleanup_on_success = { parsed.cleanup_on_success, "boolean", true },
    cleanup_on_failure = { parsed.cleanup_on_failure, "boolean", true },
    open_on_success = { parsed.open_on_success, "boolean", true },
    open_on_failure = { parsed.open_on_failure, "boolean", true }
  })
  local update_terminal = function(t)
    t:update(parsed)
  end
  if bang then
    return M._execute_on_last_focused(update_terminal)
  else
    return terms.select(nil, "Please select a terminal to update: ",
      { default = { fn = update_terminal, desc = "update-terminal" } }, picker)
  end
end

---Toggles universal selection mode
---
---When enabled, all terminals become selectable and can be set as last focused,
---regardless of their individual selectable setting. This provides a temporary
---override for accessing non-selectable terminals.
---
---@return boolean the new state after toggling
function M.toggle_universal_selection()
  local new_state = terms.toggle_universal_selection()
  local status = new_state and "enabled" or "disabled"
  utils.notify("Universal selection " .. status, "info")
  return new_state
end

---@private
M._execute_on_last_focused = function(action_fn)
  local term = terms.get_last_focused()
  if not term then
    utils.notify("No terminals are open", "error")
    return false
  else
    action_fn(term)
    return true
  end
end


---Registers ErgoTerm user commands with Neovim
---
---Creates the standard ErgoTerm commands (TermNew, TermSelect, TermSend, TermUpdate)
---with appropriate completion, range, and bang support. The picker is built from
---the provided configuration.
---
---@param conf ErgoTermConfig plugin configuration
function M.setup(conf)
  local command = vim.api.nvim_create_user_command
  local picker = config.build_picker(conf)

  command("TermNew", function(opts)
    M.new(opts.args)
  end, { complete = commandline.term_new_complete, nargs = "*" })

  command("TermSelect", function(opts)
    M.select(opts.bang, picker)
  end, { nargs = 0, bang = true })

  command("TermSend", function(opts)
    M.send(opts.args, opts.range, opts.bang, picker)
  end, { nargs = "?", complete = commandline.term_send_complete, range = true, bang = true })

  command("TermUpdate", function(opts)
    M.update(opts.args, opts.bang, picker)
  end, { nargs = 1, complete = commandline.term_update_complete, bang = true })

  command("TermToggleUniversalSelection", function()
    M.toggle_universal_selection()
  end, { nargs = 0 })
end

return M
