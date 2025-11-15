# Test-Driven Development

This guide shows how to integrate test runners into your Neovim workflow using ergoterm.

## Simple Setup: Single Test Runner

Here's a basic configuration for a test runner:

```lua
local ergoterm = require("ergoterm")

local tests = ergoterm:new({
  cmd = "npm test -- --watch",
  name = "tests",
  layout = "below",
  size = { below = "30%" },
  cleanup_on_success = false,
  cleanup_on_failure = false,
  show_on_failure = true,
  start_in_insert = false
})
```

**Configuration explained:**
- `layout = "below"` - Opens as horizontal split below current window
- `size = { below = "30%" }` - Uses 30% of screen height
- `cleanup_on_success = false` - Keeps terminal open after tests pass
- `cleanup_on_failure = false` - Keeps terminal open after tests fail
- `show_on_failure = true` - Automatically shows terminal window when tests fail
- `start_in_insert = false` - Stays in normal mode for easier navigation of test output

### Basic Keybindings

```lua
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Toggle test terminal
map("n", "<leader>tt", function()
  tests:toggle()
end, { desc = "Toggle Tests" })

-- Run all tests
map("n", "<leader>ta", function()
  tests:send({ "a" }, { action = "start" })
end, opts)

-- Run tests for current file
map("n", "<leader>tf", function()
  local file = vim.fn.expand("%:p")
  tests:send({ "p", file }, { action = "start" })
end, opts)
```

## Multiple Test Configurations

To work with different test types or runners, create a factory with shared defaults:

```lua
local test_runners = ergoterm.with_defaults({
  layout = "below",
  size = { below = "30%" },
  cleanup_on_success = false,
  cleanup_on_failure = false,
  show_on_failure = true,
  start_in_insert = false,
  auto_list = false,
  bang_target = false,
  tags = { "test" }
})

-- Create instances for different test scenarios
local unit_tests = test_runners:new({
  cmd = "npm test -- --watch",
  name = "unit-tests"
})

local integration_tests = test_runners:new({
  cmd = "npm run test:integration -- --watch",
  name = "integration-tests"
})

local e2e_tests = test_runners:new({
  cmd = "npm run test:e2e",
  name = "e2e-tests",
  cleanup_on_success = true
})
```

- We use the `tags` option to label these terminals as `test` for easy filtering later.

### Custom Selection

Use tags to create a custom picker for test runners:

```lua
local test_terms = ergoterm.filter_by_tag("test")

vim.keymap.set("n", "<leader>tl", function()
  ergoterm.select({
    terminals = test_terms,
    prompt = "Select Test Runner"
  })
end, { desc = "List Test Runners" })
```

### Progressive Disclosure with Smart Selection

Use `select_started` to create intelligent keybindings that adapt to context:

```lua
-- Run all tests: sends to unit tests if it's the only one running,
-- otherwise shows picker
vim.keymap.set("n", "<leader>ta", function()
  ergoterm.select_started({
    terminals = test_terms,
    prompt = "Run all tests in",
    callbacks = function(term)
      return term:send({ "a" }, { action = "start" })
    end,
    default = unit_tests
  })
end, { noremap = true, silent = true, desc = "Run All Tests" })

-- Run test for current file
vim.keymap.set("n", "<leader>tf", function()
  local file = vim.fn.expand("%:p")
  ergoterm.select_started({
    terminals = test_terms,
    prompt = "Run tests for current file in",
    callbacks = function(term)
      return term:send({ term.meta.run_file(file) }, { action = "start" })
    end,
    default = unit_tests
  })
end, { noremap = true, silent = true, desc = "Run Tests for File" })
```

**How it works:**
- If **no test runners are running**, uses the `default` (unit tests)
- If **one test runner is running**, sends command directly to it
- If **multiple test runners are running**, shows picker to choose which one

This creates a smooth workflow that adapts to your current context.

## Polymorphic Behavior with Meta

Different test runners use different commands and file patterns. Use `meta` to handle these differences:

```lua
local unit_tests = test_runners:new({
  cmd = "npm test -- --watch",
  name = "unit-tests",
  meta = {
    run_file = function(file) return "p" end,
    run_pattern = function(pattern) return "t " .. pattern end
  }
})

local integration_tests = test_runners:new({
  cmd = "pytest --watch",
  name = "integration-tests",
  meta = {
    run_file = function(file) return file end,
    run_pattern = function(pattern) return "-k " .. pattern end
  }
})

local go_tests = test_runners:new({
  cmd = "go test ./... -v",
  name = "go-tests",
  meta = {
    run_file = function(file)
      local dir = vim.fn.fnamemodify(file, ":h")
      return "go test " .. dir .. " -v"
    end,
    run_pattern = function(pattern) return "go test ./... -run " .. pattern .. " -v" end
  }
})
```

Now create mappings that work with all test runners:

```lua
-- Run tests for current file
vim.keymap.set("n", "<leader>tf", function()
  local file = vim.fn.expand("%:p")
  ergoterm.select_started({
    terminals = test_terms,
    prompt = "Run tests for file in",
    callbacks = function(term)
      return term:send({ term.meta.run_file(file) }, { action = "start" })
    end,
    default = unit_tests
  })
end, { noremap = true, silent = true, desc = "Run Tests for File" })

-- Run tests matching pattern
vim.keymap.set("n", "<leader>tp", function()
  vim.ui.input({ prompt = "Test pattern: " }, function(pattern)
    if pattern then
      ergoterm.select_started({
        terminals = test_terms,
        prompt = "Run pattern in",
        callbacks = function(term)
          return term:send({ term.meta.run_pattern(pattern) }, { action = "start" })
        end,
        default = unit_tests
      })
    end
  end)
end, { noremap = true, silent = true, desc = "Run Tests by Pattern" })
```

These keybindings adapt to whichever test runner you're using, automatically using the correct command syntax.

## One-Off Test Commands

For tests that run once and exit, configure automatic cleanup:

```lua
local ci_tests = test_runners:new({
  cmd = "npm run test:ci",
  name = "ci-tests",
  cleanup_on_success = true,
  cleanup_on_failure = false,
  show_on_success = false,
  show_on_failure = true
})

-- Run CI tests
vim.keymap.set("n", "<leader>tc", function()
  ci_tests:start():open()
end, { desc = "Run CI Tests" })
```

**Behavior:**
- Automatically cleans up terminal if tests pass
- Keeps terminal open if tests fail (so you can see errors)
- Only shows window when tests fail

## Complete Example Configuration

```lua
local ergoterm = require("ergoterm")

-- Create factory with shared defaults
local test_runners = ergoterm.with_defaults({
  layout = "below",
  size = { below = "30%" },
  cleanup_on_success = false,
  cleanup_on_failure = false,
  show_on_failure = true,
  start_in_insert = false,
  auto_list = false,
  bang_target = false,
  tags = { "test" }
})

-- Create test runner instances
local unit_tests = test_runners:new({
  cmd = "npm test -- --watch",
  name = "unit-tests",
  meta = {
    run_file = function(file) return "p" end,
    run_all = function() return "a" end,
    run_pattern = function(pattern) return "t " .. pattern end
  }
})

local integration_tests = test_runners:new({
  cmd = "npm run test:integration -- --watch",
  name = "integration-tests",
  meta = {
    run_file = function(file) return file end,
    run_all = function() return "" end,
    run_pattern = function(pattern) return "-k " .. pattern end
  }
})

local ci_tests = test_runners:new({
  cmd = "npm run test:ci",
  name = "ci-tests",
  cleanup_on_success = true,
  meta = {
    run_file = function(file) return file end,
    run_all = function() return "" end,
    run_pattern = function(pattern) return "-k " .. pattern end
  }
})

-- Keybindings
local map = vim.keymap.set
local opts = { noremap = true, silent = true }
local test_terms = ergoterm.filter_by_tag("test")

-- Toggle default test runner
map("n", "<leader>tt", function()
  unit_tests:toggle()
end, { desc = "Toggle Unit Tests" })

-- List all test runners
map("n", "<leader>tl", function()
  ergoterm.select({
    terminals = test_terms,
    prompt = "Select Test Runner"
  })
end, { desc = "List Test Runners" })

-- Run all tests (smart selection)
map("n", "<leader>ta", function()
  ergoterm.select_started({
    terminals = test_terms,
    prompt = "Run all tests in",
    callbacks = function(term)
      return term:send({ term.meta.run_all() }, { action = "start" })
    end,
    default = unit_tests
  })
end, opts)

-- Run tests for current file (smart selection)
map("n", "<leader>tf", function()
  local file = vim.fn.expand("%:p")
  ergoterm.select_started({
    terminals = test_terms,
    prompt = "Run tests for file in",
    callbacks = function(term)
      return term:send({ term.meta.run_file(file) }, { action = "start" })
    end,
    default = unit_tests
  })
end, opts)

-- Run tests by pattern (smart selection)
map("n", "<leader>tp", function()
  vim.ui.input({ prompt = "Test pattern: " }, function(pattern)
    if pattern then
      ergoterm.select_started({
        terminals = test_terms,
        prompt = "Run pattern in",
        callbacks = function(term)
          return term:send({ term.meta.run_pattern(pattern) }, { action = "start" })
        end,
        default = unit_tests
      })
    end
  end)
end, opts)

-- Run CI tests (one-off)
map("n", "<leader>tc", function()
  ci_tests:start():open()
end, { desc = "Run CI Tests" })
```

## Tips

- Use `show_on_failure = true` to automatically see failing tests
- Set `start_in_insert = false` for easier navigation of test output
- Use `cleanup_on_success = true` for one-off test runs
- The `meta` pattern works for any test runner command differences
- Create different tag categories for test types (e.g., `unit_test`, `integration_test`, `e2e_test`)
- Use `watch_files = true` if your test runner modifies files (like coverage reports)
- Combine with `auto_scroll = true` to automatically follow test output in real-time
