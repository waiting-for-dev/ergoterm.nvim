# ErgoTerm

A Neovim plugin for seamless terminal workflow integration. Smart picker-based terminal selection, flexible text sending from any buffer, and persistent configuration with comprehensive lifecycle control.

> **Note:** ErgoTerm started as a fork of [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) but has grown into something quite different. Big thanks to @akinsho for the solid foundation!

## Features

- **Flexible terminal creation** - Spawn terminals with your preferred layout (split, float, tab, etc.)
- **Smart terminal selection** - Pick from active terminals using your favorite picker (Telescope, fzf-lua, or built-in)
- **Seamless text sending** - Send code, commands, or selections directly to any terminal
- **Saved terminals** - Reuse terminal configurations across Neovim sessions
- **Powerful API** - Extensive Lua API for custom workflows and integrations

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "waiting-from-dev/ergoterm.nvim",
  config = function()
    require("ergoterm").setup()
  end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "waiting-from-dev/ergoterm.nvim",
  config = function()
    require("ergoterm").setup()
  end
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'waiting-from-dev/ergoterm.nvim'
```

Then add this to your `init.lua` or in a lua block:

```lua
require("ergoterm").setup()
```

After installation, you can verify everything is working correctly by running:

```vim
:checkhealth ergoterm
```

## Basic Usage

### Creating Terminals

Create new terminals with `:TermNew` and customize them with options:

```vim
:TermNew
:TermNew layout=float name=server dir=~/my-project cmd=iex
```

**Available options:**
- `layout` - Window layout (default: `below`)
  - `above`, `below`, `left`, `right`, `tab`, `float`, `window`
- `name` - Terminal name for identification (defaults to the terminal command)
- `dir` - Working directory (default: current directory)
  - Accepts absolute paths (`/home/user/project`), relative paths (`~/my-project`, `./subdir`), `"git_dir"` for auto-detected git repository root, or `nil` for current directory
- `cmd` - Shell command to run (default: system shell)

### Selecting Terminals

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

### Sending Text to Terminals

Send text from your buffer to any terminal:

```vim
:TermSend          " Send current line (opens picker)
:TermSend!         " Send to last focused terminal
:'<,'>TermSend     " Send visual selection
```

**Available options:**
- `text` - Custom text to send (default: current line or selection)
- `action` - Terminal behavior (default: `interactive`)
  - `interactive` - Focus terminal after sending
  - `visible` - Show terminal but keep current focus
  - `silent` - Send without opening terminal
- `decorator` - Text transformation (default: `identity`)
  - `identity` - Send text as-is
  - `markdown_code` - Wrap in markdown code block
- `trim` - Remove whitespace (default: `true`)
- `new_line` - Add newline for execution (default: `true`)

### Updating Terminal Settings

Modify existing terminal configuration:

```vim
:TermUpdate layout=float     " Update via picker
:TermUpdate! name=server     " Update last focused terminal
```

**Available options:**
- `layout` - Change window layout
- `name` - Rename terminal
- `auto_scroll` - Auto-scroll behavior
- `persist_mode` - Remember terminal mode when revisiting
- `selectable` - Show in selection picker and allow as last focused (can be overridden by universal selection mode)
- `start_in_insert` - Start in insert mode

### Universal Selection Mode

Toggle universal selection mode to temporarily override the `selectable` setting:

```vim
:TermToggleUniversalSelection
```

When enabled, all terminals become selectable and can be set as last focused, regardless of their individual `selectable` setting. This provides a way to access non-selectable terminals through pickers and bang commands when needed.

## Example Keymaps

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
map("n", "<leader>cx", ":TermSend! action=visible<CR>", opts)  -- Execute in terminal, keep focus
map("x", "<leader>cx", ":TermSend! action=visible<CR>", opts)  -- Execute selection in terminal, keep focus

-- Send as markdown code block
map("n", "<leader>cS", ":TermSend! action=visible trim=false decorator=markdown_code<CR>", opts)
map("x", "<leader>cS", ":TermSend! action=visible trim=false decorator=markdown_code<CR>", opts)
```

## Standalone Terminals

Create persistent terminal configurations that survive across Neovim sessions. These terminals are defined once and can be quickly accessed with a single command.

### Creating Standalone Terminals

Define terminals in your configuration:

```lua
local terms = require("ergoterm.terminal")

-- Create standalone terminals
local lazygit = terms.Terminal:new({
  name = "lazygit",
  cmd = "lazygit",
  layout = "float",
  dir = "git_dir",
  selectable = false
})

local aider = terms.Terminal:new({
  name = "aider",
  cmd = "aider",
  layout = "right",
  dir = "git_dir",
  selectable = false
})

-- Map to keybindings for quick access
vim.keymap.set("n", "<leader>gg", function() lazygit:toggle() end, { desc = "Open lazygit" })
vim.keymap.set("n", "<leader>ai", function() aider:toggle() end, { desc = "Open aider" })
```

### Available Options

All options default to values from your configuration:

- `auto_scroll` - Automatically scroll terminal output to bottom
- `cmd` - Command to execute in the terminal
- `clear_env` - Use clean environment for the job
- `close_on_job_exit` - Close terminal window when process exits
- `dir` - Working directory for the terminal
  - Accepts absolute paths, relative paths (with `~` expansion), `"git_dir"` for git repository root, or `nil` for current directory
- `env` - Environment variables for the job
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
- `selectable` - Include terminal in selection picker and allow as last focused (can be overridden by universal selection mode)
- `start_in_insert` - Start terminal in insert mode

## API Overview

ErgoTerm provides a comprehensive Lua API centered around terminal lifecycle management. The design follows a hierarchical pattern where higher-level methods automatically call lower-level ones as needed.

### Terminal Lifecycle

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

### Core Methods

- `start()` - Creates buffer and starts job process
- `open(layout?)` - Creates window with optional layout override
- `focus(layout?)` - Brings terminal into focus, cascades through start/open
- `close()` - Closes window but keeps job running
- `stop()` - Terminates job and cleans up buffer
- `delete()` - Permanently removes terminal from session
- `toggle(layout?)` - Closes if open, focuses if closed
- `send(input, opts)` - Sends text to terminal with various behaviors

### State Queries

- `is_started()` - Has active buffer and job
- `is_open()` - Has visible window
- `is_focused()` - Is currently active window
- `is_stopped()` - Job has been terminated

### Sending Text to Terminals

The `Terminal:send(input, opts)` method provides flexible text input to terminals with various interaction modes:

```lua
-- Send current line interactively (focuses terminal)
term:send("single_line")

-- Send custom text without focusing terminal
term:send({"echo hello", "ls -la"}, { action = "visible" })

-- Send visual selection silently (no UI changes)
term:send("visual_selection", { action = "silent" })

-- Send with custom formatting
term:send({"print('hello')"}, { trim = false, decorator = markdown_decorator })
```

**Input types:**
- `string[]` - Array of text lines to send directly
- `"single_line"` - Current line under cursor
- `"visual_lines"` - Current visual line selection  
- `"visual_selection"` - Current visual character selection

**Action modes:**
- `"interactive"` - Focus terminal after sending (default)
- `"visible"` - Show terminal output without stealing focus
- `"silent"` - Send text without any UI changes

For complete API documentation and advanced usage patterns, see [`lua/ergoterm/terminal.lua`](lua/ergoterm/terminal.lua).

#### Custom Text Decorators

Create custom text transformations for sending code to terminals:

```lua
-- Add timestamp to each line
local function timestamp_decorator(text)
  local timestamp = os.date("%H:%M:%S")
  local result = {}
  for _, line in ipairs(text) do
    table.insert(result, string.format("[%s] %s", timestamp, line))
  end
  return result
end

-- Use with Terminal:send()
terminal:send({"echo hello"}, { decorator = timestamp_decorator })
```

### Example: AI-Assisted Development with Aider

Here's an example showing how to integrate [Aider](https://aider.chat/) for AI-assisted coding:

```lua
local terms = require("ergoterm.terminal")

-- Create persistent Aider terminal
local aider = terms.Terminal:new({
  name = "aider",
  cmd = "aider",
  layout = "right",
  dir = "git_dir",
  selectable = false
})

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Toggle Aider terminal
map("n", "<leader>ai", function() aider:toggle() end, { desc = "Toggle Aider" })

-- Add current file to Aider session
map("n", "<leader>aa", function()
  local file = vim.fn.expand("%:p")
  aider:send({ "/add " .. file })
end, opts)

-- Sends current line to Aider session
map("n", "<leader>as", function()
  aider:send("single_line")
end, opts)

-- Sends current visual selection to Aider session
map("v", "<leader>as", function()
  aider:send("visual_selection", { trim = false })
end, opts)

-- Send code to Aider as markdown (preserves formatting)
map("n", "<leader>aS", function()
  aider:send("single_line", { trim = false, decorator = require("ergoterm.decorators").markdown_code })
end, opts)
map("v", "<leader>aS", function()
  aider:send("visual_selection", { trim = false, decorator = require("ergoterm.decorators").markdown_code })
end, opts)
```

## Configuration

ErgoTerm can be customized through the `setup()` function. Here are the defaults:

```lua
require("ergoterm").setup({
  -- Default shell command
  shell = vim.o.shell,
  
  -- Default window layout
  layout = "below",
  
  -- Auto-scroll terminal output
  auto_scroll = true,
  
  -- Close terminal window when job exits
  close_on_job_exit = true,
  
  -- Remember terminal mode between visits
  persist_mode = false,
  
  -- Start terminals in insert mode
  start_in_insert = true,
  
  -- Show terminals in picker by default
  selectable = true,
  
  -- Floating window options
  float_opts = {
    title_pos = "left",
    relative = "editor",
    border = "single",
    zindex = 50
  },
  
  -- Floating window transparency
  float_winblend = 10,
  
  -- Clean job environment
  clear_env = false,
  
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
})
```

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup

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

### Guidelines

- Follow existing code style and conventions
- Add tests for new features
- Update documentation for user-facing changes
- Keep commits focused and write clear commit messages

## License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to [@akinsho](https://github.com/akinsho) for [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim), which provided the foundation for this project
- The Neovim community for their excellent plugin ecosystem and documentation
