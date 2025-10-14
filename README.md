# ErgoTerm

A Neovim plugin for seamless terminal workflow integration. Smart picker-based terminal selection, flexible text sending from any buffer, and persistent configuration with comprehensive lifecycle control.

> **Note:** ErgoTerm started as a fork of [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) but has grown into something quite different. Big thanks to @akinsho for the solid foundation!

## Features

- 🚀 **Flexible terminal creation** - Spawn terminals with your preferred layout (split, float, tab, etc.)
- 🎯 **Smart terminal selection** - Pick from active terminals using your favorite picker (Telescope, fzf-lua, or built-in)
- 📤 **Seamless text sending** - Send code, commands, or selections directly to any terminal
- 💾 **Saved terminals** - Reuse terminal configurations across Neovim sessions
- 🤖 **Perfect AI coding companion** - The most flexible plugin for any AI-assisted coding tools
- ⚡ **Powerful API** - Extensive Lua API for custom workflows and integrations

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "waiting-for-dev/ergoterm.nvim",
  config = function()
    require("ergoterm").setup()
  end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "waiting-for-dev/ergoterm.nvim",
  config = function()
    require("ergoterm").setup()
  end
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'waiting-for-dev/ergoterm.nvim'
```

Then add this to your `init.lua` or in a lua block:

```lua
require("ergoterm").setup()
```

After installation, you can verify everything is working correctly by running:

```vim
:checkhealth ergoterm
```

## 🚀 Basic Usage

### 🔧 Creating Terminals

Create new terminals with `:TermNew` and customize them with options:

```vim
:TermNew
:TermNew layout=float name=server dir=~/my-project cmd=iex
:TermNew layout=right auto_scroll=false persist_mode=true
:TermNew size.below=20 size.right=30% float_opts.border=rounded
:TermNew tags=dev,backend meta.project=myapp
```

All terminal configuration options are available (see [🔧 Available Options](#-available-options) section below), except callback functions (`on_create`, `on_open`, `on_close`, `on_focus`, `on_start`, `on_stop`, `on_job_exit`, `on_job_stdout`, `on_job_stderr`).

**Special syntax for nested and list settings:**
- **Dot notation** for table settings: Use `table.key=value` to set individual table keys
  - Example: `size.below=20` sets only the `below` key in the `size` table
  - Example: `float_opts.border=rounded` sets only the `border` key in `float_opts`
  - Example: `meta.custom=value` sets arbitrary user-defined metadata
- **Comma-separated** for lists: Use `setting=value1,value2,value3` for list values
  - Example: `tags=dev,test,prod` creates a list with three tags

### 🎯 Selecting Terminals

Choose from active terminals:

```vim
:TermSelect          " Open picker to select terminal
:TermSelect!         " Focus last focused terminal directly
```

Uses your configured picker (Telescope, fzf-lua, or built-in) to display all available terminals.

**Advanced Picker Options**

When using fzf-lua or Telescope, additional keybindings are available in the picker:

- `<Enter>` - Open terminal in previous layout
- `<Ctrl-s>` - Open in horizontal split
- `<Ctrl-v>` - Open in vertical split
- `<Ctrl-t>` - Open in new tab
- `<Ctrl-f>` - Open in floating window

These keybindings can be customized through the `picker.select_actions` and `picker.extra_select_actions` configuration options (see [Configuration](#️-configuration) section).

### 📤 Sending Text to Terminals

Send text from your buffer to any terminal:

```vim
:TermSend          " Send current line (opens picker)
:TermSend!         " Send to last focused terminal
:'<,'>TermSend     " Send visual selection
```

**Available options:**
- `text` - Custom text to send (default: current line or selection)
- `action` - Terminal behavior (default: `focus`)
  - `focus` - Focus terminal after sending
  - `open` - Show terminal but keep current focus
  - `start` - Send without opening terminal
- `decorator` - Text transformation (default: `identity`)
  - `identity` - Send text as-is
  - `markdown_code` - Wrap in markdown code block
  - Custom decorators can be registered in configuration (see [Configuration](#️-configuration))
- `trim` - Remove whitespace (default: `true`)
- `new_line` - Add newline for execution (default: `true`)

### ⚙️ Updating Terminal Settings

Modify existing terminal configuration:

```vim
:TermUpdate layout=float              " Update via picker
:TermUpdate! name=server              " Update last focused terminal
:TermUpdate! size.below=25            " Update only bottom split height
:TermUpdate! float_opts.border=double " Update floating window border
:TermUpdate! tags=prod,backend        " Replace all tags
```

All options from `:TermNew` are available (see [🔧 Available Options](#-available-options) section below), except `cmd` and `dir` which are immutable after terminal creation.

**Special update behavior:**
- **Table settings** (using dot notation): Only the specified nested keys are updated while other keys remain unchanged
  - Example: `:TermUpdate! size.below=20` updates only `below`, preserves `above`, `left`, `right`
  - Example: `:TermUpdate! meta.env=production` updates only the `env` key, preserves other metadata
- **List settings** (comma-separated): The entire list is replaced
  - Example: `:TermUpdate! tags=prod,critical` replaces all tags with the new list

### 🔍 Inspecting Terminals

Inspect a terminal's internal state for debugging purposes:

```vim
:TermInspect          " Select terminal to inspect
:TermInspect!         " Inspect last focused terminal
```

Displays the terminal object's internal structure using `vim.inspect()`, useful for debugging and understanding terminal configuration.

### 🌐 Universal Selection Mode

Toggle universal selection mode to temporarily override the `selectable` and `bang_target` settings for all terminals:

```vim
:TermToggleUniversalSelection
```

When enabled, all terminals become selectable and can be targeted by bang commands, regardless of their individual `selectable` and `bang_target` settings. This provides a way to access any terminals through pickers and bang commands when needed.

## ⌨️ Example Keymaps

Here are some useful keymaps to get you started:

```lua
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Terminal creation with different layouts
map("n", "<leader>cs", ":TermNew layout=below<CR>", opts)   -- Split below
map("n", "<leader>cv", ":TermNew layout=right<CR>", opts)   -- Vertical split
map("n", "<leader>cf", ":TermNew layout=float<CR>", opts)   -- Floating window
map("n", "<leader>ct", ":TermNew layout=tab<CR>", opts)     -- New tab

-- Open terminal picker
map("n", "<leader>cl", ":TermSelect<CR>", opts)  -- List and select terminals

-- Send text to last focused terminal
map("n", "<leader>cs", ":TermSend! new_line=false<CR>", opts)  -- Send line without newline
map("x", "<leader>cs", ":TermSend! new_line=false<CR>", opts)  -- Send selection without newline

-- Send and show output without focusing terminal
map("n", "<leader>cx", ":TermSend! action=open<CR>", opts)  -- Execute in terminal, keep focus
map("x", "<leader>cx", ":TermSend! action=open<CR>", opts)  -- Execute selection in terminal, keep focus

-- Send as markdown code block
map("n", "<leader>cS", ":TermSend! action=open trim=false decorator=\"markdown_code\"<CR>", opts)
map("x", "<leader>cS", ":TermSend! action=open trim=false decorator=\"markdown_code\"<CR>", opts)
```

## 💾 Standalone Terminals

Create persistent terminal configurations that survive across Neovim sessions. These terminals are defined once and can be quickly accessed with a single command.

### 🏗️ Creating Standalone Terminals

Define terminals in your configuration:

```lua
local terms = require("ergoterm.terminal")

-- Create standalone terminals
local lazygit = terms.Terminal:new({
  name = "lazygit",
  cmd = "lazygit",
  layout = "float",
  dir = "git_dir",
  selectable = false,
  bang_target = false
})

local claude = terms.Terminal:new({
  name = "claude",
  cmd = "claude",
  layout = "right",
  dir = "git_dir",
  selectable = false,
  watch_files = true
})

-- Map to keybindings for quick access
vim.keymap.set("n", "<leader>gg", function() lazygit:toggle() end, { desc = "Open lazygit" })
vim.keymap.set("n", "<leader>ci", function() claude:toggle() end, { desc = "Open claude" })
```

### 📁 Project-Specific Terminals with `.nvim.lua`

For project-specific terminal configurations, you can leverage a `.nvim.lua` file in your project root. This is especially useful with the `sticky` option to keep project terminals available even when stopped:

```lua
local term = require("ergoterm.terminal").Terminal

term:new({
  name = "Phoenix Server",
  cmd = "iex -S mix phx.server",
  layout = "right",
  sticky = true
})

term:new({
  name = "DB Console",
  cmd = "psql -U postgres my_database",
  layout = "below",
  sticky = true
})
```

With `sticky = true`, these terminals remain visible in the picker (`:TermSelect`) even when stopped, making it easy to restart your development environment. The terminals are automatically loaded when you open the project in Neovim.

### 🔧 Available Options

All options default to values from your configuration:

- `auto_scroll` - Automatically scroll terminal output to bottom
- `bang_target` - Allow terminal to be targeted by bang commands (can be overridden by universal selection mode)
- `watch_files` - Watch for file changes when terminal produces output (requires vim's `autoread` option)
- `cmd` - Command to execute in the terminal
- `clear_env` - Use clean environment for the job
- `cleanup_on_success` - Cleanup terminal when process exits successfully (exit code 0)
- `cleanup_on_failure` - Cleanup terminal when process exits with failure (exit code non-zero)
- `show_on_success` - Open terminal window when process exits successfully (exit code 0). Requires `cleanup_on_success` to be `false`.
- `show_on_failure` - Open terminal window when process exits with failure (exit code non-zero). Requires `cleanup_on_failure` to be `false`.
- `default_action` - Function to invoke when selecting terminal in picker with `<Enter>`
- `dir` - Working directory for the terminal
  - Accepts absolute paths, relative paths (with `~` expansion), `"git_dir"` for git repository root, or `nil` for current directory
- `env` - Environment variables for the job (table of key-value pairs)
  - Example: `{ PATH = "/custom/path", DEBUG = "1" }`
- `float_opts` - Floating window configuration options
- `float_winblend` - Transparency level for floating windows
- `layout` - Default window layout when opening
- `name` - Display name for the terminal
- `on_close` - Called when the terminal window is closed. Receives the terminal instance as its only argument
- `on_create` - Called when the terminal buffer is first created. Receives the terminal instance as its only argument
- `on_focus` - Called when the terminal window gains focus. Receives the terminal instance as its only argument
- `on_job_exit` - Called when the terminal process exits. Receives the terminal instance, job ID, exit code, and event name
- `on_job_stderr` - Called when the terminal process outputs to stderr. Receives the terminal instance, channel ID, data lines, and stream name
- `on_job_stdout` - Called when the terminal process outputs to stdout. Receives the terminal instance, channel ID, data lines, and stream name
- `on_open` - Called when the terminal window is opened. Receives the terminal instance as its only argument
- `on_start` - Called when the terminal job process starts. Receives the terminal instance as its only argument
- `on_stop` - Called when the terminal job process stops. Receives the terminal instance as its only argument
- `persist_mode` - Remember terminal mode between visits
- `persist_size` - Remember terminal size between visits
- `selectable` - Include terminal in selection picker (can be overridden by universal selection mode)
- `sticky` - Keep terminal visible in picker even when stopped (requires `selectable` to also be `true`)
- `size` - Size configuration for different window layouts (table with `above`, `below`, `left`, `right` keys)
  - Each direction accepts either a string with percentage (e.g., `"30%"`) or a number for absolute size
  - Example: `{ below = 20, right = "40%" }` - 20 lines high for below splits, 40% width for right splits
- `start_in_insert` - Start terminal in insert mode
- `tags` - List of tags for categorizing and filtering terminals
- `meta` - User-defined metadata table for custom purposes

## ⚡ API Overview

ErgoTerm provides a comprehensive Lua API centered around terminal lifecycle management. The design follows a hierarchical pattern where higher-level methods automatically call lower-level ones as needed.

### 🔄 Terminal Lifecycle

Every terminal follows this lifecycle progression:

1. **Create** - `Terminal:new()` - Creates terminal instance with configuration
2. **Start** - `Terminal:start()` - Initializes buffer and job process
3. **Open** - `Terminal:open()` - Creates window for the terminal
4. **Focus** - `Terminal:focus()` - Brings terminal into active focus

Each method is idempotent and will automatically call prerequisite methods:

```lua
local terms = require("ergoterm.terminal")

-- Create a terminal instance
local term = terms.Terminal:new({ cmd = "htop", layout = "float" })

-- These methods cascade - focus() will start() and open() if needed
term:focus()  -- Automatically calls start() and open() if not already done

-- You can also call methods individually
term:start()  -- Just start the job process
term:open()   -- Just create the window (calls start() if needed)
```

### 🛠️ Core Methods

- `start()` - Creates buffer and starts job process
- `open(layout?)` - Creates window with optional layout override
- `focus(layout?)` - Brings terminal into focus, cascades through start/open
- `close()` - Closes window but keeps job running
- `stop()` - Terminates job and cleans up buffer
- `cleanup()` - Cleans up terminal resources
- `toggle(layout?)` - Closes if open, focuses if closed
- `send(input, opts)` - Sends text to terminal with various behaviors

### 🔍 State Queries

- `is_started()` - Job is running
- `is_active()` - Has active buffer
- `is_open()` - Has visible window
- `is_focused()` - Is currently active window
- `is_stopped()` - Job has been terminated

### 📤 Sending Text to Terminals

The `Terminal:send(input, opts)` method provides flexible text input to terminals with various interaction modes:

```lua
-- Send current line interactively (focuses terminal)
term:send("single_line")

-- Send custom text without focusing terminal
term:send({"echo hello", "ls -la"}, { action = "open" })

-- Send visual selection silently (no UI changes)
term:send("visual_selection", { action = "start" })

-- Send with custom formatting
term:send({"print('hello')"}, { trim = false, decorator = "markdown_code" })
```

**Input types:**
- `string[]` - Array of text lines to send directly
- `"single_line"` - Current line under cursor
- `"visual_lines"` - Current visual line selection  
- `"visual_selection"` - Current visual character selection
- `"last"` - Last sent text (for resending)

**Action modes:**
- `"focus"` - Focus terminal after sending (default)
- `"open"` - Show terminal output without stealing focus
- `"start"` - Send text without any UI changes

For complete API documentation and advanced usage patterns, see [`lua/ergoterm/terminal.lua`](lua/ergoterm/terminal.lua).

#### 🎨 Custom Text Decorators

Create custom text transformations for sending code to terminals. You can pass decorator functions directly or register them by name in the configuration:

```lua
-- Option 1: Pass decorator function directly to send()
local function timestamp_decorator(text)
  local timestamp = os.date("%H:%M:%S")
  local result = {}
  for _, line in ipairs(text) do
    table.insert(result, string.format("[%s] %s", timestamp, line))
  end
  return result
end

terminal:send({"echo hello"}, { decorator = timestamp_decorator })

-- Option 2: Register named decorator in setup()
require("ergoterm").setup({
  text_decorators = {
    extra = {
      timestamp = function(text)
        local timestamp = os.date("%H:%M:%S")
        local result = {}
        for _, line in ipairs(text) do
          table.insert(result, string.format("[%s] %s", timestamp, line))
        end
        return result
      end
    }
  }
})

-- Then use by name
terminal:send({"echo hello"}, { decorator = "timestamp" })
-- Or from command line
:TermSend decorator=timestamp
```

### 🤖 Example: AI-Assisted Development with Claude Code

Here's an example showing how to integrate [Claude Code](https://claude.ai/) for AI-assisted coding:

```lua
local terms = require("ergoterm.terminal")

-- Create persistent Claude terminal
local claude = terms.Terminal:new({
  name = "claude",
  cmd = "claude",
  layout = "right",
  dir = "git_dir",
  selectable = false,
  watch_files = true
})

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Toggle Claude terminal
map("n", "<leader>ai", function() claude:toggle() end, { desc = "Toggle Claude" })

-- Reference current file to Claude
map("n", "<leader>aa", function()
  local file = vim.fn.expand("%:p")
  claude:send({ "@" .. file .. " " }, { new_line = false })
end, opts)

-- Sends current line to Claude session
map("n", "<leader>as", function()
  claude:send("single_line")
end, opts)

-- Sends current visual selection to Claude session
map("v", "<leader>as", function()
  claude:send("visual_selection", { trim = false })
end, opts)

-- Send code to Claude as markdown (preserves formatting)
map("n", "<leader>aS", function()
  claude:send("single_line", { trim = false, decorator = "markdown_code" })
end, opts)
map("v", "<leader>aS", function()
  claude:send("visual_selection", { trim = false, decorator = "markdown_code" })
end, opts)
```

## ⚙️ Configuration

ErgoTerm can be customized through the `setup()` function. Here are the defaults:

```lua
require("ergoterm").setup({
  -- Terminal defaults - applied to all new terminals but overridable per instance
  terminal_defaults = {
    -- Default shell command
    shell = vim.o.shell,

    -- Default window layout
    layout = "below",

    -- Auto-scroll terminal output
    auto_scroll = false,

    -- Allow terminals to be targeted by bang commands by default
    bang_target = true,

    -- Watch for file changes when terminal produces output (requires vim's autoread option)
    watch_files = false,

    -- Cleanup terminal when process exits successfully (exit code 0)
    cleanup_on_success = true,

    -- Cleanup terminal when process exits with failure (exit code non-zero)
    cleanup_on_failure = false,

    -- Open terminal window when process exits successfully (exit code 0)
    show_on_success = false,

    -- Open terminal window when process exits with failure (exit code non-zero)
    show_on_failure = false,

    -- Default action to invoke when selecting terminal in picker
    default_action = function(term) term:focus() end,

    -- Remember terminal mode between visits
    persist_mode = false,

    -- Remember terminal size between visits
    persist_size = true,

    -- Start terminals in insert mode
    start_in_insert = true,

    -- Show terminals in picker by default
    selectable = true,

    -- Keep terminals visible in picker even when stopped, provided `selectable` is also true
    sticky = false,

    -- Default tags for categorizing and filtering terminals
    tags = {},

    -- User-defined metadata for custom purposes
    meta = {},

    -- Floating window options
    float_opts = {
      title_pos = "left",
      relative = "editor",
      border = "single",
      zindex = 50
    },
    
    -- Floating window transparency
    float_winblend = 10,
    
    -- Size configuration for different layouts
    size = {
      below = "50%",   -- 50% of screen height
      above = "50%",   -- 50% of screen height
      left = "50%",    -- 50% of screen width
      right = "50%"    -- 50% of screen width
    },

    -- Clean job environment
    clear_env = false,

    -- Environment variables for terminal jobs
    env = nil,  -- Example: { PATH = "/custom/path", DEBUG = "1" }
    
    -- Default callbacks (all no-ops by default)
    on_close = function(term) end,
    on_create = function(term) end,
    on_focus = function(term) end,
    on_job_exit = function(term, job_id, exit_code, event_name) end,
    on_job_stderr = function(term, channel_id, data_lines, stream_name) end,
    on_job_stdout = function(term, channel_id, data_lines, stream_name) end,
    on_open = function(term) end,
    on_start = function(term) end,
    on_stop = function(term) end,
  },
  
  -- Picker configuration
  picker = {
    -- Picker to use for terminal selection
    -- Can be "telescope", "fzf-lua", "vim-ui-select", or a custom picker object
    -- nil = auto-detect (telescope > fzf-lua > vim.ui.select)
    picker = nil,

    -- Default actions available in terminal picker
    -- These replace the built-in actions entirely
    select_actions = {
      default = { fn = function(term) term:focus() end, desc = "Open" },
      ["<C-s>"] = { fn = function(term) term:focus("below") end, desc = "Open in horizontal split" },
      ["<C-v>"] = { fn = function(term) term:focus("right") end, desc = "Open in vertical split" },
      ["<C-t>"] = { fn = function(term) term:focus("tab") end, desc = "Open in tab" },
      ["<C-f>"] = { fn = function(term) term:focus("float") end, desc = "Open in float window" }
    },

    -- Additional actions to append to select_actions
    -- These are merged with select_actions, allowing you to add custom actions
    -- without replacing the defaults
    extra_select_actions = {}
  },

  -- Text decorators configuration
  text_decorators = {
    -- Default text decorators available by name
    -- These replace the built-in decorators entirely
    default = {
      identity = function(text) return text end,
      markdown_code = function(text)
        -- Implementation details...
      end
    },

    -- Additional decorators to append to default
    -- These are merged with default, allowing you to add custom decorators
    -- without replacing the built-in ones
    extra = {}
  }
})
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### 🛠️ Development Setup

1. Clone the repository
2. Install dependencies for testing:
   ```bash
   # Install busted for Lua testing
   luarocks install busted
   ```
3. Run tests:
   ```bash
   busted
   ```

### 📋 Guidelines

- Follow existing code style and conventions
- Add tests for new features
- Update documentation for user-facing changes
- Keep commits focused and write clear commit messages

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to [@akinsho](https://github.com/akinsho) for [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim), which provided the foundation for this project
- The Neovim community for their excellent plugin ecosystem and documentation
