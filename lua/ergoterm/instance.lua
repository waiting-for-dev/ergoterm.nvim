local M = {}

---@module "ergoterm.lazy"
local lazy = require("ergoterm.lazy")

---@module "ergoterm.collection"
local collection = require("ergoterm.collection")
---@module "ergoterm.config"
local config = lazy.require("ergoterm.config")
---@module "ergoterm.mode"
local mode = lazy.require("ergoterm.mode")
---@module "ergoterm.instance.open"
local open = require("ergoterm.instance.open")
---@module "ergoterm.instance.start"
local start = require("ergoterm.instance.start")
---@module "ergoterm.instance.stop"
local stop = require("ergoterm.instance.stop")
---@module "ergoterm.size"
local size_utils = lazy.require("ergoterm.size")
---@module "ergoterm.text_decorators"
local text_decorators = lazy.require("ergoterm.text_decorators")
---@module "ergoterm.text_selector"
local text_selector = lazy.require("ergoterm.text_selector")
---@module "ergoterm.instance.update"
local update = require("ergoterm.instance.update")
---@module "ergoterm.utils"
local utils = lazy.require("ergoterm.utils")

---@class TerminalState
---@field bufnr number?
---@field dir? string
---@field layout layout
---@field float_opts FloatOpts
---@field mode Mode
---@field job_id? number
---@field has_been_started boolean
---@field last_exit_code? number
---@field last_sent string[]
---@field on_job_exit on_job_exit
---@field on_job_stdout on_job_stdout
---@field on_job_stderr on_job_stderr
---@field size Size
---@field tabpage number?
---@field window number?

---@class TerminalCreateSettings : TerminalDefaultsFromConfig
---@field cmd string? command to run in the terminal
---@field dir string? the directory for the terminal
---@field env table<string, string>? environmental variables passed to jobstart()
---@field name string?
---@field meta table?
---@field tags string[]?

---@class Terminal
---@field id number
---@field cmd string
---@field dir string|string?
---@field env table<string, string>?
---@field auto_scroll boolean
---@field bang_target boolean
---@field watch_files boolean
---@field clear_env boolean
---@field cleanup_on_success boolean
---@field cleanup_on_failure boolean
---@field default_action default_action
---@field layout layout
---@field float_opts FloatOpts
---@field float_winblend number
---@field persist_mode boolean
---@field persist_size boolean
---@field selectable boolean
---@field size Size
---@field start_in_insert boolean
---@field sticky boolean
---@field name string
---@field on_close on_close
---@field on_focus on_focus
---@field on_job_exit on_job_exit
---@field on_job_stdout on_job_stdout
---@field on_job_stderr on_job_stderr
---@field on_open on_open
---@field on_start on_start
---@field on_stop on_stop
---@field show_on_success boolean
---@field show_on_failure boolean
---@field tags string[]
---@field meta table
---@field _state TerminalState
local Terminal = {}
Terminal.__index = Terminal

---Creates a new terminal instance with merged configuration
---
---Combines provided arguments with global configuration defaults.
---
---The terminal is registered in the module state but not started until `start()` is called.
---
---@param args TerminalCreateSettings?
---@return Terminal
function Terminal:new(args)
  local term = vim.deepcopy(args or {})
  setmetatable(term, self)
  term.auto_scroll = vim.F.if_nil(term.auto_scroll, config.get("terminal_defaults.auto_scroll"))
  term.bang_target = vim.F.if_nil(term.bang_target, config.get("terminal_defaults.bang_target"))
  term.watch_files = vim.F.if_nil(term.watch_files, config.get("terminal_defaults.watch_files"))
  term.cmd = term.cmd or config.get("terminal_defaults.shell")
  term.clear_env = vim.F.if_nil(term.clear_env, config.get("terminal_defaults.clear_env"))
  term.cleanup_on_success = vim.F.if_nil(term.cleanup_on_success, config.get("terminal_defaults.cleanup_on_success"))
  term.cleanup_on_failure = vim.F.if_nil(term.cleanup_on_failure, config.get("terminal_defaults.cleanup_on_failure"))
  term.default_action = vim.F.if_nil(term.default_action, config.get("terminal_defaults.default_action"))
  term.layout = term.layout or config.get("terminal_defaults.layout")
  term.env = term.env
  term.name = term.name or term.cmd
  term.meta = term.meta or {}
  term.float_opts = vim.tbl_deep_extend("keep", term.float_opts or {}, config.get("terminal_defaults.float_opts"))
  term.float_winblend = term.float_winblend or config.get("terminal_defaults.float_winblend")
  term.persist_mode = vim.F.if_nil(term.persist_mode, config.get("terminal_defaults.persist_mode"))
  term.persist_size = vim.F.if_nil(term.persist_size, config.get("terminal_defaults.persist_size"))
  term.selectable = vim.F.if_nil(term.selectable, config.get("terminal_defaults.selectable"))
  term.size = vim.tbl_deep_extend("keep", term.size or {}, config.get("terminal_defaults.size"))
  term.start_in_insert = vim.F.if_nil(term.start_in_insert, config.get("terminal_defaults.start_in_insert"))
  term.sticky = vim.F.if_nil(term.sticky, config.get("terminal_defaults.sticky"))
  term.on_close = vim.F.if_nil(term.on_close, config.get("terminal_defaults.on_close"))
  term.on_focus = vim.F.if_nil(term.on_focus, config.get("terminal_defaults.on_focus"))
  term.on_job_stderr = vim.F.if_nil(term.on_job_stderr, config.get("terminal_defaults.on_job_stderr"))
  term.on_job_stdout = vim.F.if_nil(term.on_job_stdout, config.get("terminal_defaults.on_job_stdout"))
  term.on_job_exit = vim.F.if_nil(term.on_job_exit, config.get("terminal_defaults.on_job_exit"))
  term.on_open = vim.F.if_nil(term.on_open, config.get("terminal_defaults.on_open"))
  term.on_start = vim.F.if_nil(term.on_start, config.get("terminal_defaults.on_start"))
  term.on_stop = vim.F.if_nil(term.on_stop, config.get("terminal_defaults.on_stop"))
  term.show_on_success = vim.F.if_nil(term.show_on_success, config.get("terminal_defaults.show_on_success"))
  term.show_on_failure = vim.F.if_nil(term.show_on_failure, config.get("terminal_defaults.show_on_failure"))
  term.tags = term.tags or vim.tbl_deep_extend("keep", {}, config.get("terminal_defaults.tags") or {})
  term.id = collection._compute_id()
  term:_initialize_state()
  collection._add_terminal_to_state(term)
  return term
end

---Updates terminal settings
---
---It'll override table settings instead of deep merging them, unless
---`opts.deep_merge` is true.
---
---It'll error if trying to update immutable properties like `cmd` or `dir`.
---
---@param settings TerminalCreateSettings properties to update
---@param opts? UpdateOptions options for updating
---
---@return Terminal?
function Terminal:update(settings, opts)
  return update(self, settings, opts)
end

---Initializes the terminal job and buffer
---
---It recomputes the directory before starting the job
---
---The job is called with the environment and exit and output handlers configured
---in the terminal instance.
---
---It also sets up buffer autocommands and triggers the `on_start` callback.
---
---@return Terminal
function Terminal:start()
  return start(self)
end

---Checks if the terminal job is running
---
---@return boolean
function Terminal:is_started()
  return start.is_started(self)
end

---Terminates the terminal job
---
---Stops the underlying job process and closes any open windows. Triggers the
---`on_stop` callback.
---
---@return Terminal
function Terminal:stop()
  return stop(self)
end

---Checks if the terminal has an active buffer
---
---A terminal will have an active buffer when started or if already stopped but not
--- yet cleaned up.
---
---@return boolean
function Terminal:is_active()
  return self._state.has_been_started and not self:is_cleaned_up()
end

---Creates a window for the terminal without focusing it
---
---Automatically starts the terminal if not already started. Uses the provided
---layout or falls back to the terminal's initial layout or last used layout if
---changed. Supported layouts:
---
---• "above" - horizontal split above current window
---• "below" - horizontal split below current window
---• "left" - vertical split to the left
---• "right" - vertical split to the right
---• "tab" - new tab page
---• "float" - floating window with configured dimensions
---• "window" - replace current window content
---
---It'll call the `on_open` callback after opening the window.
---
---@param layout layout? window layout override
---@return self
function Terminal:open(layout)
  return open(self, layout)
end

---Returns whether the terminal window is currently open
---
---@return boolean
function Terminal:is_open()
  return open.is_open(self)
end

---Closes the terminal window while keeping the job running
---
---The terminal can be reopened later with `open()` or `focus()`. Triggers the
---`on_close` callback. No-op if the terminal is not currently open.
---
---@return Terminal self for method chaining
function Terminal:close()
  if self:is_open() then
    self:on_close()
    if self.persist_size then
      self:_persist_size()
    end
    if #vim.api.nvim_list_wins() == 1 then
      local empty_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(self._state.window, empty_buf)
    else
      vim.api.nvim_win_close(self._state.window, true)
    end
  end
  return self
end

---Brings the terminal window into focus and switches to it
---
---Automatically starts and opens the terminal if needed. Switches to the
---terminal's tabpage and window, making it the active window. Sets up the
---appropriate terminal mode and triggers the `on_focus` callback.
---
---@param layout string? window layout to use if opening for the first time
---@return self for method chaining
function Terminal:focus(layout)
  if not self:is_open() then self:open(layout) end
  if not self:is_focused() then
    vim.api.nvim_set_current_win(self._state.window)
    self:_set_last_focused()
    self:_set_return_mode()
    self:on_focus()
  end
  return self
end

---Checks if this terminal is the currently active window
---
---@return boolean true if this terminal's window is the current window
function Terminal:is_focused()
  return self._state.window == vim.api.nvim_get_current_win()
end

---Cleans up the terminal and optionally deletes it from the session
---
---Always stops the terminal if running and cleans up resources. For sticky terminals,
---only deletes from the session registry if force is true, otherwise they remain
---available for future use. Non-sticky terminals are always deleted from the session.
---
---@param opts? CleanupOptions options for cleanup
function Terminal:cleanup(opts)
  opts = opts or {}
  local force = vim.F.if_nil(opts.force, false)

  if self:is_started() then
    self:stop()
  end
  if self:is_open() then
    self:close()
  end
  if self._state.bufnr then
    self._state.bufnr = nil
  end
  if collection._state.last_focused == self then
    collection._state.last_focused = nil
  end
  if collection._state.last_focused_bang_target == self then
    collection._state.last_focused_bang_target = nil
  end
  if not self.sticky or force then
    collection._state.terminals[self.id] = nil
  end
end

---@return boolean
function Terminal:is_cleaned_up()
  return self._state.has_been_started and self._state.bufnr == nil
end

---Toggles terminal window visibility
---
---Closes the terminal if currently open, or focuses it if closed. Provides
---a convenient way to show/hide terminals with a single command.
---
---@param layout string? window layout to use when opening
---@return Terminal self for method chaining
function Terminal:toggle(layout)
  if self:is_open() then
    self:close()
  else
    self:focus(layout)
  end
  return self
end

---@class SendOptions
---@field action? "focus"|"open"|"start" terminal interaction mode (default: "focus")
---@field trim? boolean remove leading/trailing whitespace (default: true)
---@field new_line? boolean append newline for command execution (default: true)
---@field decorator? string | fun(text: string[]): string[] transform text before sending

---Sends text input to the terminal job
---
---Before sending text, ensures the terminal is in the appropriate state based on opts.action:
---"focus" focuses the terminal for user interaction (default),
---"open" opens the terminal without stealing focus,
---"start" only starts the terminal without opening any window.
---Text is trimmed by default and gets a trailing newline for command execution.
---
---Input can be provided as:
---• Array of strings - sends the text directly
---• "single_line" - sends the current line under cursor
---• "visual_lines" - sends the current visual line selection
---• "visual_selection" - sends the current visual character selection
---• "last" - resends the last sent text
---
---@param input string[]|"single_line"|"visual_lines"|"visual_selection"|"last" lines of text to send or selection type
---@param opts? SendOptions options for sending text
---@return self for method chaining
function Terminal:send(input, opts)
  opts = opts or {}
  local action = opts.action or "focus"

  local deprecated_actions = {
    silent = "start",
    visible = "open",
    interactive = "focus"
  }
  if deprecated_actions[action] then
    utils.notify(
      string.format("Action '%s' is deprecated, use '%s' instead", action,
        deprecated_actions[action]),
      "warn"
    )
    action = deprecated_actions[action]
  end

  local trim = opts.trim == nil or opts.trim
  local new_line = opts.new_line == nil or opts.new_line
  local decorator
  if type(opts.decorator) == "string" then
    local all_decorators = config.get_text_decorators()
    decorator = all_decorators[opts.decorator] or text_decorators.identity
  else
    decorator = opts.decorator or text_decorators.identity
  end
  if type(input) == "string" then
    local valid_selection_types = { "single_line", "visual_lines", "visual_selection", "last" }
    if not vim.tbl_contains(valid_selection_types, input) then
      utils.notify(
        string.format("Invalid input type '%s'. Must be a table with one item per line or one of: %s", input,
          table.concat(valid_selection_types, ", ")),
        "error"
      )
      return self
    end
  end
  local text_input
  if input == "last" then
    text_input = vim.deepcopy(self._state.last_sent)
  elseif type(input) == "string" then
    text_input = text_selector.select(input)
  else
    text_input = input
  end
  self._state.last_sent = vim.deepcopy(text_input)
  if new_line then
    table.insert(text_input, "")
  end
  if trim then
    for i, line in ipairs(text_input) do
      text_input[i] = line:gsub("^%s+", ""):gsub("%s+$", "")
    end
  end
  local decorated_input = decorator(text_input)
  if action == "start" then
    self:start()
  elseif action == "open" then
    self:open()
  elseif action == "focus" then
    self:focus()
  end
  vim.fn.chansend(self._state.job_id, decorated_input)
  self:_scroll_bottom()
  return self
end

---Clears the terminal display
---
---Sends the appropriate clear command for the current platform (`cls` on Windows,
---`clear` on Unix systems). Opens and focuses the terminal to show the result.
function Terminal:clear()
  local clear = utils.is_windows() and "cls" or "clear"
  self:send({ clear })
end

---Handles buffer enter events for the terminal
---
---Restores the appropriate terminal mode and sets the last focused terminal.
---Called automatically when entering the terminal buffer.
function Terminal:on_buf_enter()
  self:_set_return_mode()
  self:_set_last_focused()
end

---Handles window leave events for the terminal
---
---Saves the current mode if persist_mode is enabled, and automatically closes
---floating terminals when focus is lost to prevent them from lingering.
function Terminal:on_win_leave()
  if self.persist_mode then self:_persist_mode() end
  if self._state.layout == "float" then self:close() end
end

---Handles Vim resize events for the terminal
---
---Updates the floating window configuration if the terminal is in float layout.
function Terminal:on_vim_resized()
  if vim.tbl_contains({ "float", "above", "below", "left", "right" }, self._state.layout) and self:is_open() then
    vim.api.nvim_win_set_config(self._state.window, self:_compute_win_config(self._state.layout))
  end
end

---Accesses internal terminal state
---
---Primarily used for debugging and testing.
---
---@param key string
---@return any the state value for the given key
function Terminal:get_state(key)
  return self._state[key]
end

---Gets the status icon for the terminal
---
---Returns an appropriate UTF icon based on the current terminal state:
---• ○ Not active (only for sticky terminals)
---• ▶ Started and running
---• ✓ Stopped but active, process succeeded
---• ✗ Stopped but active, process failed
---
---@return string the status icon
function Terminal:get_status_icon()
  if self:is_started() then
    return "▶"
  elseif self:is_active() then
    if self._state.last_exit_code == 0 then
      return "✓"
    else
      return "✗"
    end
  else
    return "○"
  end
end

---@private
function Terminal:_show(layout)
  open.show(self, layout)
end

---@private
function Terminal:_compute_win_config(layout)
  local win_config
  if layout == "float" then
    win_config = self:_compute_float_win_config()
  elseif vim.tbl_contains({ "above", "below", "left", "right" }, layout) then
    win_config = self:_compute_split_win_config(layout)
  else
    win_config = {}
  end
  return win_config
end

---@private
function Terminal:_compute_exit_handler(callback)
  return function(job, exit_code, event)
    callback(self, job, exit_code, event)
    self._state.job_id = nil
    self._state.last_exit_code = exit_code

    local should_cleanup = false
    local should_show = false
    if exit_code == 0 then
      should_cleanup = self.cleanup_on_success
      should_show = self.show_on_success
    else
      should_cleanup = self.cleanup_on_failure
      should_show = self.show_on_failure
    end

    if should_show then
      vim.schedule(function()
        self:_show()
      end)
    end

    if should_cleanup then
      vim.schedule(function()
        self:cleanup()
      end)
    end
  end
end

---@private
function Terminal:_compute_output_handler(callback)
  return function(channel_id, data, name)
    if self.auto_scroll then self:_scroll_bottom() end
    if self.watch_files then
      vim.schedule(function()
        vim.cmd('checktime')
      end)
    end
    callback(self, channel_id, data, name)
  end
end

---@private
function Terminal:_initialize_state()
  self._state = {
    bufnr = nil,
    dir = self:_compute_dir(),
    layout = self.layout,
    float_opts = self:_compute_float_win_config(),
    job_id = nil,
    has_been_started = false,
    last_exit_code = nil,
    last_sent = {},
    mode = mode.get_initial(self.start_in_insert),
    on_job_exit = self:_compute_exit_handler(self.on_job_exit),
    on_job_stdout = self:_compute_output_handler(self.on_job_stdout),
    on_job_stderr = self:_compute_output_handler(self.on_job_stderr),
    size = self.size,
    tabpage = nil,
    window = nil
  }
end

---@private
function Terminal:_compute_dir()
  local dir = nil
  if self.dir == "git_dir" then
    dir = utils.git_dir()
  elseif self.dir == nil then
    dir = vim.loop.cwd()
  else
    dir = vim.fn.expand(self.dir)
    if vim.fn.isdirectory(dir) == 0 then
      utils.notify(
        string.format("%s is not a directory", dir),
        "error"
      )
    end
  end
  return dir
end

---@private
function Terminal:_compute_split_win_config(layout)
  local win_config
  local size = self:_compute_size()
  if layout == "above" then
    win_config = { height = size.above, vertical = false, split = "above", win = -1 }
  elseif layout == "below" then
    win_config = { height = size.below, vertical = false, split = "below", win = -1 }
  elseif layout == "left" then
    win_config = { width = size.left, vertical = true, split = "left", win = -1 }
  elseif layout == "right" then
    win_config = { width = size.right, vertical = false, split = "right", win = -1 }
  end
  return win_config
end

---@private
function Terminal:_compute_float_win_config()
  local float_opts = vim.tbl_deep_extend("keep", {}, self.float_opts or {})
  float_opts.title = float_opts.title or self.name
  float_opts.height = float_opts.height or math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 5)))
  float_opts.width = float_opts.width or math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 10)))
  float_opts.row = float_opts.row or math.ceil(vim.o.lines - float_opts.height) * 0.5 - 1
  float_opts.col = float_opts.col or math.ceil(vim.o.columns - float_opts.width) * 0.5 - 1
  float_opts.zindex = (vim.api.nvim_win_get_config(0).zindex or 0) + 1
  return float_opts
end

---@private
function Terminal:_compute_size()
  local size = {}
  for layout, value in pairs(self._state.size) do
    if size_utils.is_percentage(value) then
      size[layout] = size_utils.percentage_to_absolute(value, layout)
    else
      size[layout] = value
    end
  end
  return size
end

---@private
function Terminal:_persist_size()
  local layout = self._state.layout
  if not self:is_open() then return end
  if not vim.tbl_contains({ "above", "below", "left", "right" }, layout) then return end

  local current_axis_absolute_size
  local current_axis_size
  if size_utils.is_vertical(layout) then
    current_axis_absolute_size = vim.api.nvim_win_get_width(self._state.window)
  else
    current_axis_absolute_size = vim.api.nvim_win_get_height(self._state.window)
  end
  if size_utils.is_percentage(self.size[layout]) then
    current_axis_size = size_utils.absolute_to_percentage(current_axis_absolute_size, layout)
  else
    current_axis_size = current_axis_absolute_size
  end
  self._state.size[layout] = current_axis_size
end

---@private
function Terminal:_restore_mode()
  mode.set(self._state.mode)
  return self
end

---@private
function Terminal:_set_last_focused()
  collection._state.last_focused = self
  if self.bang_target then
    collection._state.last_focused_bang_target = self
  end
  return self
end

---@private
function Terminal:_set_return_mode()
  if self.persist_mode then
    self:_restore_mode()
  else
    self:_set_initial_mode()
  end
  return self
end

---@private
function Terminal:_persist_mode()
  self._state.mode = mode.get()
  return self
end

---@private
function Terminal:_set_initial_mode()
  mode.set_initial(self.start_in_insert)
  return self
end

---@private
function Terminal:_scroll_bottom()
  if self:is_open() then
    vim.api.nvim_buf_call(self._state.bufnr, function()
      if mode.get() == mode.NORMAL then
        vim.cmd("normal! G")
      end
    end)
  end
end

M.Terminal = Terminal

return M
