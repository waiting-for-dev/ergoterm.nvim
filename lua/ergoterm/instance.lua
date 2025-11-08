local M = {}

---@module "ergoterm.instance.cleanup"
local cleanup = require("ergoterm.instance.cleanup")
---@module "ergoterm.instance.close"
local close = require("ergoterm.instance.close")
---@module "ergoterm.collection"
local collection = require("ergoterm.collection")
---@module "ergoterm.config"
local config = require("ergoterm.config")
---@module "ergoterm.instance.focus"
local focus = require("ergoterm.instance.focus")
---@module "ergoterm.mode"
local mode = require("ergoterm.mode")
---@module "ergoterm.instance.unfocus"
local unfocus = require("ergoterm.instance.unfocus")
---@module "ergoterm.events.on_buf_enter"
local on_buf_enter = require("ergoterm.events.on_buf_enter")
---@module "ergoterm.events.on_exit"
local on_exit = require("ergoterm.events.on_exit")
---@module "ergoterm.events.on_output"
local on_output = require("ergoterm.events.on_output")
---@module "ergoterm.events.on_win_leave"
local on_win_leave = require("ergoterm.events.on_win_leave")
---@module "ergoterm.instance.open"
local open = require("ergoterm.instance.open")
---@module "ergoterm.instance.send"
local send = require("ergoterm.instance.send")
---@module "ergoterm.instance.start"
local start = require("ergoterm.instance.start")
---@module "ergoterm.instance.stop"
local stop = require("ergoterm.instance.stop")
---@module "ergoterm.size"
local size_utils = require("ergoterm.size_utils")
---@module "ergoterm.instance.update"
local update = require("ergoterm.instance.update")
---@module "ergoterm.utils"
local utils = require("ergoterm.utils")

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
---@field auto_list boolean
---@field size Size
---@field start_in_insert boolean
---@field sticky boolean
---@field name string
---@field on_close on_close
---@field on_focus on_focus
---@field on_unfocus on_unfocus
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
---name will be made unique if a terminal with the same name already exists by
---appending a numeric suffix.
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
  term.name = term:_compute_name()
  term.clear_env = vim.F.if_nil(term.clear_env, config.get("terminal_defaults.clear_env"))
  term.cleanup_on_success = vim.F.if_nil(term.cleanup_on_success, config.get("terminal_defaults.cleanup_on_success"))
  term.cleanup_on_failure = vim.F.if_nil(term.cleanup_on_failure, config.get("terminal_defaults.cleanup_on_failure"))
  term.default_action = vim.F.if_nil(term.default_action, config.get("terminal_defaults.default_action"))
  term.layout = term.layout or config.get("terminal_defaults.layout")
  term.env = term.env
  term.meta = term.meta or {}
  term.float_opts = vim.tbl_deep_extend("keep", term.float_opts or {}, config.get("terminal_defaults.float_opts"))
  term.float_winblend = term.float_winblend or config.get("terminal_defaults.float_winblend")
  term.persist_mode = vim.F.if_nil(term.persist_mode, config.get("terminal_defaults.persist_mode"))
  term.persist_size = vim.F.if_nil(term.persist_size, config.get("terminal_defaults.persist_size"))
  if term.selectable ~= nil then
    utils.notify(
      "[ergoterm] `selectable` option is deprecated and will be removed soon. Use `auto_list` instead.",
      "warn"
    )
    term.auto_list = term.selectable
    term.selectable = nil
  end
  term.auto_list = vim.F.if_nil(term.auto_list, config.get("terminal_defaults.auto_list"))
  term.size = vim.tbl_deep_extend("keep", term.size or {}, config.get("terminal_defaults.size"))
  term.start_in_insert = vim.F.if_nil(term.start_in_insert, config.get("terminal_defaults.start_in_insert"))
  term.sticky = vim.F.if_nil(term.sticky, config.get("terminal_defaults.sticky"))
  term.on_close = vim.F.if_nil(term.on_close, config.get("terminal_defaults.on_close"))
  term.on_focus = vim.F.if_nil(term.on_focus, config.get("terminal_defaults.on_focus"))
  term.on_unfocus = vim.F.if_nil(term.on_unfocus, config.get("terminal_defaults.on_unfocus"))
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
---If the terminal is the only window open, it replaces its buffer with an empty
---buffer to avoid closing Vim entirely.
---
---It'll also persist the window size if `persist_size` is enabled.
---
---Triggers the `on_close` callback.
---
---@return Terminal self for method chaining
function Terminal:close()
  return close(self)
end

---Brings the terminal window into focus and switches to it
---
---Automatically starts and opens the terminal if needed. Switches to the
---terminal's tabpage and window, making it the active window.
---
---Sets the terminal as the last focused terminal.
---
---Sets up the appropriate terminal mode depending on `persist_mode` setting.
---
---It triggers the `on_focus` callback.
---
---@param layout string? window layout to use if opening for the first time
---@return self for method chaining
function Terminal:focus(layout)
  return focus(self, layout)
end

---Checks if this terminal is the currently active window
---
---@return boolean true if this terminal's window is the current window
function Terminal:is_focused()
  return focus.is_focused(self)
end

---Removes focus from the terminal window
---
---Persists mode if configured, and closes floating terminals.
---Optionally switches to a different window.
---
---Triggers the `on_unfocus` callback.
---
---@param win_id number? optional window ID to switch to after unfocusing
---@return Terminal self for method chaining
function Terminal:unfocus(win_id)
  return unfocus(self, win_id)
end

---Cleans up the terminal
---
---Stops the terminal if needed, and removes the buffer reference.
---
---It'll also no longer be the last focused terminal if it was.
---
---If the terminal is not sticky, or `opts.force` is true, it will be removed
---from the collection state entirely.
---
---@param opts? CleanupOptions options for cleanup
function Terminal:cleanup(opts)
  return cleanup(self, opts)
end

---Checks if the terminal has been cleaned up
---
---That means the terminal has been started at least once and its buffer
---is no longer present.
---
---@return boolean
function Terminal:is_cleaned_up()
  return cleanup.is_cleaned_up(self)
end

---Toggles terminal state between focused and closed
---
---Closes the terminal if currently open, or focuses it if closed.
---
---@param layout layout? window layout to use when opening
---@return Terminal
function Terminal:toggle(layout)
  if self:is_open() then
    self:close()
  else
    self:focus(layout)
  end
  return self
end

---Sends text input to the terminal job
---
---Input can be given as:
---• A table of strings, each representing a line to send.
---• A string representing a selection type:
---  - "single_line" - sends the current line
---  - "visual_lines" - sends the lines covered by the current visual line selection
---  - "visual_selection" - sends the exact text covered by the current visual selection
---  - "last" - resends the last sent text
---
--- Following options can be configured via `opts`:
--- • `action` - what to do before sending text:
---   - "focus" - focus the terminal (default)
---   - "open" - open the terminal without focusing
---   - "start" - start the terminal without opening or focusing
--- • `trim` - whether to trim leading/trailing whitespace from each line (default: true)
--- • `new_line` - whether to append a newline character to each line for command execution (default: true)
--- • `decorator` - a string key or function to transform the text before sending:
---  - If a string key is provided, it looks up the decorator function from the global configuration.
---  - If a function is provided, it is used directly to transform the text.
---
---@param input send_input_type | string[]
---@param opts? SendOptions options for sending text
---@return self
function Terminal:send(input, opts)
  return send(self, input, opts)
end

---Clears the terminal display
---
---Sends the appropriate clear command for the current platform (`cls` on Windows,
---`clear` on Unix systems). Opens and focuses the terminal to show the result.
---
---@param action? send_action terminal interaction mode before clearing
function Terminal:clear(action)
  return send.clear(self, action)
end

---Handles buffer enter events for the terminal
---
---Restores the appropriate terminal mode and sets the last focused terminal.
function Terminal:on_buf_enter()
  return on_buf_enter(self)
end

---Handles window leave events for the terminal
---
---Saves the current mode if persist_mode is enabled, and automatically closes
---floating terminals.
function Terminal:on_win_leave()
  return on_win_leave(self)
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
    on_exit(self, job, exit_code, event, callback)
  end
end

---@private
function Terminal:_compute_output_handler(callback)
  return function(channel_id, data, name)
    on_output(self, channel_id, data, name, callback)
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
function Terminal:_compute_name()
  local base_name = self.name or self.cmd
  local name = base_name
  local suffix = 2

  while collection.get_by_name(name) do
    name = string.format("%s-%d", base_name, suffix)
    suffix = suffix + 1
  end

  return name
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
