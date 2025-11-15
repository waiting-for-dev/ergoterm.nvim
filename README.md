# ergoterm.nvim

A flexible terminal management plugin for Neovim that puts you in control of your workflow.

## Philosophy

Most Neovim terminal integration follows a **tool-specific approach**: specialized plugins for AI chats, testing, task runners and other CLI tools (e.g., lazygit), each with their own terminal implementation and UI decisions. This creates friction when you want consistent behavior across tools or when no plugin exists for your preferred CLI application.

ergoterm inverts this with a **terminal-first approach**: a single, powerful terminal abstraction that adapts to any CLI tool. Instead of conforming to various plugin constraints, you configure terminals with exactly the behavior you need.

**The terminal becomes your universal integration layer.** You own the workflow; the terminals adapt to it.

## Setup

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

## Use Cases

- [On-Demand Terminal Access](docs/on-demand-usage.md)
- [Interactive AI Assistants](docs/interactive-ai-assistants.md)
- [Test Runner](docs/test-runner.md)
- [Development Environment](docs/development-environment.md)
- [Task Runner](docs/task-runner.md)
- [Project Initialization on Startup](docs/project-initialization.md)
- [API Reference](docs/api-reference.md)

## Configuration

### Terminal Defaults

All options can be set globally in `setup()` under `terminal_defaults`, or per-terminal when creating instances.

```lua
require("ergoterm").setup({
  terminal_defaults = {
    layout = "right",
    cleanup_on_success = false,
    auto_scroll = true
  }
})
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `auto_list` | `boolean` | `true` | Show terminal in default picker selection list (e.g., `:TermSelect` command) |
| `auto_scroll` | `boolean` | `false` | Automatically scroll to bottom on new output |
| `bang_target` | `boolean` | `true` | Include terminal as target for bang (`!`) commands |
| `clear_env` | `boolean` | `false` | Clear environment variables before starting |
| `cleanup_on_failure` | `boolean` | `false` | Cleanup terminal when process exits with non-zero code |
| `cleanup_on_success` | `boolean` | `true` | Cleanup terminal when process exits with code 0 |
| `default_action` | `function` | `function(term) term:focus() end` | Action performed when selecting terminal with default picker action |
| `float_opts` | `table` | See below | Floating window configuration options |
| `↳ border` | `string` | `"single"` | Border style (see `:help nvim_open_win()`) |
| `↳ col` | `number` | Auto-centered | Column position |
| `↳ height` | `number` | Auto-calculated | Window height |
| `↳ relative` | `string` | `"editor"` | What the float is positioned relative to |
| `↳ row` | `number` | Auto-centered | Row position |
| `↳ title` | `string` | Terminal name | Window title |
| `↳ title_pos` | `string` | `"left"` | Title position |
| `↳ width` | `number` | Auto-calculated | Window width |
| `↳ zindex` | `number` | +1 | Window stacking order |
| `float_winblend` | `number` | `10` | Transparency level for floating windows (0-100) |
| `layout` | `string` | `"below"` | Window layout: `"below"`, `"above"`, `"left"`, `"right"`, `"float"`, `"tab"`, `"window"` |
| `meta` | `table` | `{}` | Custom user metadata for storing arbitrary data. Useful for terminal polymorphism. |
| `on_close` | `function` | No-op | Callback when terminal window closes: `function(term)` |
| `on_focus` | `function` | No-op | Callback when terminal gains focus: `function(term)` |
| `on_job_exit` | `function` | No-op | Callback when job exits: `function(term, job, exit_code, event)` |
| `on_job_stderr` | `function` | No-op | Callback on stderr: `function(term, channel_id, data, name)` |
| `on_job_stdout` | `function` | No-op | Callback on stdout: `function(term, channel_id, data, name)` |
| `on_open` | `function` | No-op | Callback when terminal window opens: `function(term)` |
| `on_start` | `function` | No-op | Callback when terminal job starts: `function(term)` |
| `on_stop` | `function` | No-op | Callback when terminal job stops: `function(term)` |
| `on_unfocus` | `function` | No-op | Callback when terminal loses focus: `function(term)` |
| `persist_mode` | `boolean` | `false` | Remember insert/normal mode between focus sessions |
| `persist_size` | `boolean` | `true` | Remember window size when resizing splits |
| `scrollback` | `number` | `vim.o.scrollback` | Terminal scrollback buffer size |
| `shell` | `string` | `vim.o.shell` | Default shell command to run if no `cmd` is given |
| `show_on_failure` | `boolean` | `false` | Show terminal window when process fails (incompatible with `cleanup_on_failure`) |
| `show_on_success` | `boolean` | `false` | Show terminal window when process succeeds (incompatible with `cleanup_on_success`) |
| `size` | `table` | See below | Size for split layouts (number of rows/columns or percentage string) |
| `↳ above` | `string\|number` | `"50%"` | Height for above layout |
| `↳ below` | `string\|number` | `"50%"` | Height for below layout |
| `↳ left` | `string\|number` | `"50%"` | Width for left layout |
| `↳ right` | `string\|number` | `"50%"` | Width for right layout |
| `start_in_insert` | `boolean` | `true` | Start in insert mode when focusing terminal |
| `sticky` | `boolean` | `false` | Keep terminal active even after cleanup so it can be restarted |
| `tags` | `string[]` | `{}` | Tags for organizing and filtering terminals |
| `watch_files` | `boolean` | `false` | Refresh buffer when stdout is received |

### Picker Configuration

Configure terminal selection picker behavior:

```lua
require("ergoterm").setup({
  picker = {
    picker = "telescope",
    extra_select_actions = {
      ["<C-d>"] = { fn = function(term) term:cleanup() end, desc = "Delete terminal" }
    }
  }
})
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `extra_select_actions` | `table` | `{}` | Additional custom keybindings merged with defaults |
| `picker` | `string\|table\|nil` | `nil` | Picker implementation: `nil` (auto-detect), `"telescope"`, `"fzf-lua"`, `"vim-ui-select"`, or custom picker table |
| `select_actions` | `table` | Default keybindings | Picker action keybindings. Defaults: `default` (runs `default_action`), `<C-s>` (open below), `<C-v>` (open right), `<C-t>` (open in tab), `<C-f>` (open float). Each action is a table with `fn` (callback function) and `desc` (description) |

### Text Decorators

Text decorators transform text before sending to terminals. They can be used in the `:TermSend` command or the `term:send()` API method.

```lua
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
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `default` | `table` | Built-in decorators | Built-in text decorators: `identity` (no transformation), `markdown_code` (wraps in markdown code block) |
| `extra` | `table` | `{}` | Custom text decorators. Each decorator is a function that takes `string[]` and returns `string[]` |

Use with `:TermSend decorator=name` or `term:send(input, {decorator = "name"})`.

## Contributing

Contributions are welcome! To get started:

1. Clone the repository
2. Run tests with `busted`
3. Submit a pull request

Make sure all tests pass before submitting your PR.

## Acknowledgments

This plugin started as a fork of [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim). Thanks to the original author and contributors for their foundational work.

## License

GPL-3.0
