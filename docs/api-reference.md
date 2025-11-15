# API Reference

Complete reference for the ergoterm API.

## Overview

The ergoterm API is split into two main components:

- **Collection methods**: Functions to manage and query all terminals in your session (accessed via `require("ergoterm")`)
- **Instance methods**: Methods to control individual terminal instances (accessed via `term:method()`)

**Example:**

```lua
local ergoterm = require("ergoterm")

-- Collection method: create a new terminal
local term = ergoterm:new({ cmd = "htop", layout = "float" })

-- Instance methods: control the terminal
term:start()
term:focus()
term:send({ "q" })
```

## Collection Methods

Collection methods are accessed through the main ergoterm module:

```lua
local ergoterm = require("ergoterm")
```

### Creating Terminals

#### `ergoterm:new(args)`

Creates a new terminal instance with the specified configuration.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `args` | `table` | No | Terminal configuration (see [Terminal Defaults](../README.md#terminal-defaults)) |
| `args.cmd` | `string` | No | Command to run in the terminal (default: shell) |
| `args.dir` | `string` | No | Working directory. Special value: `"git_dir"` expands to git root |
| `args.env` | `table` | No | Environment variables as key-value pairs |
| `args.name` | `string` | No | Terminal name (default: command name). Made unique automatically if duplicate |
| `args.meta` | `table` | No | Custom metadata for polymorphic behavior |
| `args.tags` | `string[]` | No | Tags for organizing terminals |

**Returns:** `Terminal` instance

**Example:**

```lua
local dev_server = ergoterm:new({
  name = "server",
  cmd = "npm run dev",
  layout = "right",
  tags = { "dev", "server" }
})
```

#### `ergoterm.with_defaults(custom_defaults)`

Creates a factory for creating terminals with shared default settings.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `custom_defaults` | `table` | Yes | Default configuration for all terminals created by this factory |

**Returns:** Factory object with a `new(args)` method

**Example:**

```lua
local tasks = ergoterm.with_defaults({
  layout = "below",
  size = { below = "30%" },
  sticky = true
})

local migrate = tasks:new({ name = "migrate", cmd = "rails db:migrate" })
local seed = tasks:new({ name = "seed", cmd = "rails db:seed" })
```

### Querying Terminals

#### `ergoterm.find(predicate)`

Finds the first terminal matching the given condition.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `predicate` | `function` | Yes | Function that returns `true` for matching terminals: `function(term)` |

**Returns:** `Terminal` or `nil`

**Example:**

```lua
local server = ergoterm.find(function(term)
  return term.name == "server"
end)
```

#### `ergoterm.filter(predicate)`

Returns all terminals matching the given condition.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `predicate` | `function` | Yes | Function that returns `true` for matching terminals: `function(term)` |

**Returns:** Array of `Terminal` instances

**Example:**

```lua
local running = ergoterm.filter(function(term)
  return term:is_started()
end)
```

#### `ergoterm.get_all()`

Returns all terminals in the current session.

**Returns:** Array of `Terminal` instances

**Example:**

```lua
local all_terminals = ergoterm.get_all()
print("Total terminals: " .. #all_terminals)
```

#### `ergoterm.get(id)`

Gets a terminal by its unique ID.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `number` | Yes | Terminal ID |

**Returns:** `Terminal` or `nil`

**Example:**

```lua
local term = ergoterm.get(1)
```

#### `ergoterm.get_by_name(name)`

Finds the terminal with the specified name.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | `string` | Yes | Terminal name |

**Returns:** `Terminal` or `nil`

**Example:**

```lua
local server = ergoterm.get_by_name("server")
if server then
  server:focus()
end
```

#### `ergoterm.filter_by_tag(tag)`

Returns all terminals that have the specified tag.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `tag` | `string` | Yes | Tag to search for |

**Returns:** Array of `Terminal` instances

**Example:**

```lua
local dev_terminals = ergoterm.filter_by_tag("dev")
```

#### `ergoterm.get_focused()`

Returns the terminal that currently has window focus.

**Returns:** `Terminal` or `nil`

**Example:**

```lua
local focused = ergoterm.get_focused()
if focused then
  print("Currently focused: " .. focused.name)
end
```

#### `ergoterm.identify()`

Returns the terminal associated with the current buffer.

**Returns:** `Terminal` or `nil`

**Example:**

```lua
local current = ergoterm.identify()
```

#### `ergoterm.get_target_for_bang()`

Returns the most recently focused terminal eligible for bang commands.

If `universal_selection` is enabled, returns the last focused terminal regardless of its `bang_target` flag. Otherwise, returns the last focused terminal that has `bang_target = true`.

**Returns:** `Terminal` or `nil`

**Example:**

```lua
local target = ergoterm.get_target_for_bang()
if target then
  target:send({ "echo 'hello'" })
end
```

### Selection and Pickers

#### `ergoterm.select(defaults)`

Presents a picker interface for terminal selection.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `defaults` | `table` | No | Configuration options |
| `defaults.terminals` | `Terminal[]` | No | Terminals to choose from (default: auto-list terminals that are active or sticky) |
| `defaults.prompt` | `string` | No | Picker prompt text (default: "Please select a terminal") |
| `defaults.callbacks` | `table\|function` | No | Action callbacks or single function for default action |
| `defaults.picker` | `table` | No | Custom picker implementation |

**Returns:** Result from picker, or `nil` if no terminals available

**Callbacks:**

Callbacks define actions that can be performed on selected terminals. They can be provided in two formats:

1. **Simple function**: A single function for the default action
   ```lua
   callbacks = function(term) term:toggle() end
   ```

2. **Table of keybindings**: A table mapping keys to action definitions
   ```lua
   callbacks = {
     default = { fn = function(term) term:toggle() end, desc = "Toggle terminal" },
     ["<C-x>"] = { fn = function(term) term:close() end, desc = "Close terminal" }
   }
   ```

Each action in the table format must have:
- `fn`: Function that receives the terminal as parameter
- `desc`: Description shown in the picker

If not provided, defaults to the configured picker actions from `setup()`.

**Example:**

```lua
local dev_terms = ergoterm.filter_by_tag("dev")

-- Simple callback
ergoterm.select({
  terminals = dev_terms,
  prompt = "Select Development Terminal",
  callbacks = function(term)
    term:toggle()
  end
})

-- Multiple keybindings
ergoterm.select({
  terminals = dev_terms,
  prompt = "Select Development Terminal",
  callbacks = {
    default = { fn = function(term) term:focus() end, desc = "Focus terminal" },
    ["<C-d>"] = { fn = function(term) term:cleanup() end, desc = "Delete terminal" }
  }
})
```

#### `ergoterm.select_started(defaults)`

Presents a picker interface for started terminals only.

Filters the provided terminals to only include those that have been started. If none are started and a `default` terminal is provided, that terminal is selected instead.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `defaults` | `table` | Yes | Configuration options (same as `select()`) |
| `defaults.default` | `Terminal` | No | Terminal to select when none are started |

**Returns:** Result from picker, or `nil` if no started terminals available

**Example:**

```lua
local chats = ergoterm.filter_by_tag("ai_chat")

ergoterm.select_started({
  terminals = chats,
  prompt = "Send to chat",
  callbacks = function(term)
    term:send("single_line")
  end,
  default = claude_sonnet
})
```

**Behavior:**
- If **no terminals are started** and `default` is provided: selects the default
- If **one terminal is started**: selects it directly (no picker shown)
- If **multiple terminals are started**: shows picker

### Cleanup and State Management

#### `ergoterm.cleanup_all(opts)`

Cleans up all terminals in the current session. This is a destructive operation that cannot be undone.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `opts` | `table` | No | Cleanup options |
| `opts.force` | `boolean` | No | Force removal of sticky terminals (default: `false`) |

**Example:**

```lua
ergoterm.cleanup_all({ force = true })
```

#### `ergoterm.toggle_universal_selection()`

Toggles universal selection mode.

When enabled, all terminals are shown in the default selection and can be targeted by bang commands, regardless of their `auto_list` or `bang_target` settings.

**Returns:** `boolean` - The new state after toggling

**Example:**

```lua
local is_enabled = ergoterm.toggle_universal_selection()
print("Universal selection: " .. (is_enabled and "enabled" or "disabled"))
```

#### `ergoterm.get_state(key)`

Accesses internal module state. Primarily used for debugging and testing.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `key` | `string` | Yes | State key to retrieve |

**Returns:** State value for the given key

**Example:**

```lua
local last_focused = ergoterm.get_state("last_focused")
```

#### `ergoterm.reset_ids()`

Resets the terminal ID sequence back to 1.

Terminal IDs are never reused, even after deletion. This function clears the ID history, allowing the sequence to restart from 1. Useful for testing.

**Example:**

```lua
ergoterm.reset_ids()
```

## Instance Methods

Instance methods are called on individual terminal objects:

```lua
local term = ergoterm:new({ cmd = "htop" })
term:start()
```

### Lifecycle Management

#### `term:start()`

Initializes the terminal job and buffer.

Recomputes the working directory, starts the job with configured environment and handlers, sets up buffer autocommands, and triggers the `on_start` callback.

**Returns:** `Terminal` (self)

**Example:**

```lua
term:start()
```

#### `term:is_started()`

Checks if the terminal job is running.

**Returns:** `boolean`

**Example:**

```lua
if not term:is_started() then
  term:start()
end
```

#### `term:stop()`

Terminates the terminal job.

Stops the underlying job process, closes any open windows, and triggers the `on_stop` callback.

**Returns:** `Terminal` (self)

**Example:**

```lua
term:stop()
```

#### `term:is_active()`

Checks if the terminal has an active buffer.

A terminal is active when started or when already stopped but not yet cleaned up.

**Returns:** `boolean`

**Example:**

```lua
if term:is_active() then
  print("Terminal has an active buffer")
end
```

#### `term:cleanup(opts)`

Cleans up the terminal.

Stops the terminal if needed and removes the buffer reference. If the terminal is not sticky or `opts.force` is true, it will be removed from the collection entirely.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `opts` | `table` | No | Cleanup options |
| `opts.force` | `boolean` | No | Force removal even if sticky (default: `false`) |

**Example:**

```lua
term:cleanup({ force = true })
```

#### `term:is_cleaned_up()`

Checks if the terminal has been cleaned up.

A terminal is cleaned up when it has been started at least once and its buffer is no longer present.

**Returns:** `boolean`

**Example:**

```lua
if term:is_cleaned_up() then
  print("Terminal has been cleaned up")
end
```

### Window Management

#### `term:open(layout)`

Creates a window for the terminal without focusing it.

Automatically starts the terminal if not already started. Uses the provided layout or falls back to the terminal's configured layout.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `layout` | `string` | No | Window layout: `"below"`, `"above"`, `"left"`, `"right"`, `"float"`, `"tab"`, `"window"` |

**Returns:** `Terminal` (self)

**Example:**

```lua
term:open("float")
```

#### `term:is_open()`

Returns whether the terminal window is currently open.

**Returns:** `boolean`

**Example:**

```lua
if term:is_open() then
  term:close()
end
```

#### `term:close()`

Closes the terminal window while keeping the job running.

If the terminal is the only window open, it replaces its buffer with an empty buffer to avoid closing Vim entirely. Persists the window size if `persist_size` is enabled. Triggers the `on_close` callback.

**Returns:** `Terminal` (self)

**Example:**

```lua
term:close()
```

#### `term:focus(layout)`

Brings the terminal window into focus and switches to it.

Automatically starts and opens the terminal if needed. Switches to the terminal's tabpage and window, making it the active window. Sets the terminal as the last focused terminal and sets up the appropriate terminal mode. Triggers the `on_focus` callback.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `layout` | `string` | No | Window layout to use if opening for the first time |

**Returns:** `Terminal` (self)

**Example:**

```lua
term:focus("right")
```

#### `term:is_focused()`

Checks if this terminal is the currently active window.

**Returns:** `boolean`

**Example:**

```lua
if term:is_focused() then
  print("Terminal is focused")
end
```

#### `term:unfocus(win_id)`

Removes focus from the terminal window.

Persists mode if configured and closes floating terminals. Optionally switches to a different window. Triggers the `on_unfocus` callback.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `win_id` | `number` | No | Window ID to switch to after unfocusing |

**Returns:** `Terminal` (self)

**Example:**

```lua
term:unfocus()
```

#### `term:toggle(layout)`

Toggles terminal state between focused and closed.

Closes the terminal if currently open, or focuses it if closed.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `layout` | `string` | No | Window layout to use when opening |

**Returns:** `Terminal` (self)

**Example:**

```lua
vim.keymap.set("n", "<leader>tt", function() term:toggle() end)
```

### Sending Input

#### `term:send(input, opts)`

Sends text input to the terminal job.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `input` | `string[]\|string` | Yes | Text to send (array of lines) or selection type |
| `opts` | `table` | No | Send options |
| `opts.action` | `string` | No | Terminal action: `"focus"` (default), `"open"`, `"start"` |
| `opts.trim` | `boolean` | No | Trim whitespace (default: `true`) |
| `opts.new_line` | `boolean` | No | Append newline to execute command (default: `true`) |
| `opts.clear` | `boolean` | No | Clear terminal before sending (default: `false`) |
| `opts.decorator` | `string\|function` | No | Text decorator to apply |

**Input types:**
- `string[]` - Array of lines to send
- `"single_line"` - Sends the current line
- `"visual_lines"` - Sends lines covered by visual line selection
- `"visual_selection"` - Sends exact text covered by visual selection
- `"last"` - Resends the last sent text

**Example:**

```lua
term:send({ "echo 'hello'" })
term:send("single_line", { action = "open", new_line = false })
term:send("last")
```

#### `term:clear(action)`

Clears the terminal display.

Sends the appropriate clear command for the current platform (`cls` on Windows, `clear` on Unix systems).

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `action` | `string` | No | Terminal action before clearing: `"focus"`, `"open"`, `"start"` |

**Example:**

```lua
term:clear("open")
```

### Configuration

#### `term:update(settings, opts)`

Updates terminal settings after creation.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `settings` | `table` | Yes | Properties to update (see [Terminal Defaults](../README.md#terminal-defaults)) |
| `opts` | `table` | No | Update options |
| `opts.deep_merge` | `boolean` | No | Deep merge table settings (default: `false`) |

**Note:** Cannot update immutable properties: `cmd`, `dir`, `scrollback`, `env`

**Returns:** `Terminal` or `nil`

**Example:**

```lua
term:update({ layout = "float", size = { below = "40%" } })
```

### State Inspection

#### `term:get_status_icon()`

Gets the status icon for the terminal.

Returns an appropriate UTF icon based on the current terminal state:
- `○` Not active (only for sticky terminals)
- `▶` Started and running
- `✓` Stopped but active, process succeeded
- `✗` Stopped but active, process failed

**Returns:** `string`

**Example:**

```lua
print(term:get_status_icon() .. " " .. term.name)
```

#### `term:get_state(key)`

Accesses internal terminal state. Primarily used for debugging and testing.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `key` | `string` | Yes | State key to retrieve |

**Returns:** State value for the given key

**Example:**

```lua
local bufnr = term:get_state("bufnr")
```
