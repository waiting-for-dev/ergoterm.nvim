# Project Initialization on Startup

This guide shows how to automatically run initialization tasks when opening a project, with terminals that surface errors but stay hidden on success.

## Background Initialization with `.nvim.lua`

You can use `.nvim.lua` files to define terminals that start automatically when you open a project. Combined with `show_on_failure = true`, these terminals run quietly in the background but immediately surface if something goes wrong.

**Security note:** Since `.nvim.lua` executes arbitrary Lua code, only load files from projects you trust. Neovim will prompt you to confirm before loading these files for the first time.

## Example: Docker and Git Initialization

Here's a setup that starts Docker services and fetches remote changes when opening a project:

**.nvim.lua** (in your project root):

```lua
local ergoterm = require("ergoterm")

-- Start Docker services
local docker_init = ergoterm:new({
  name = "docker-init",
  cmd = "docker-compose up -d",
  auto_list = false,
  show_on_failure = true,
  sticky = true,
  on_job_exit = function(term, job, exit_code)
    if exit_code == 0 then
      vim.notify("Docker services started", vim.log.levels.INFO)
    end
  end
})

-- Fetch remote changes
local git_fetch = ergoterm:new({
  name = "git-fetch",
  cmd = "git fetch --all --prune",
  auto_list = false,
  show_on_failure = true,
  sticky = true,
  on_job_exit = function(term, job, exit_code)
    if exit_code == 0 then
      vim.notify("Git fetch completed", vim.log.levels.INFO)
    end
  end
})

-- Start both terminals in the background
docker_init:start()
git_fetch:start()
```

**Configuration explained:**

- **`auto_list = false`**: Keeps these terminals hidden from `:TermSelect` picker since they're utility tasks
- **`show_on_failure = true`**: Automatically opens and focuses the terminal if the command exits with a non-zero code
- **`sticky = true`**: Keeps terminal registered after completion so you can inspect or restart it if needed
- **`:start()`**: Launches the terminal in the background without opening a window

### How It Works

When you open the project in Neovim:

1. Both terminals start executing in the background
2. If Docker starts successfully, you never see the terminal
3. If Docker fails (e.g., daemon not running), the terminal opens automatically showing the error
4. Same behavior for `git fetch` - silent success, visible failure

This pattern is perfect for prerequisite checks and setup tasks that should "just work" but need attention when they don't.

## Common Initialization Patterns

### Sequential Startup

If tasks depend on each other, chain them with callbacks:

```lua
local docker_init = ergoterm:new({
  name = "docker-init",
  cmd = "docker-compose up -d && docker-compose ps",
  auto_list = false,
  show_on_failure = true,
  on_job_exit = function(term, job, exit_code)
    if exit_code == 0 then
      -- Only start database migrations after Docker is up
      migrations:start()
    end
  end
})

local migrations = ergoterm:new({
  name = "migrations",
  cmd = "your-migration-command",
  auto_list = false,
  show_on_failure = true
})

docker_init:start()
```

## Debugging Initialization Tasks

Even with `auto_list = false`, you can still inspect these terminals:

```vim
" Inspect by name
:TermInspect target=docker-init

" Enable universal selection to see all terminals
:TermToggleUniversalSelection
:TermSelect
```

This lets you check the output of successful runs or manually restart failed tasks.
