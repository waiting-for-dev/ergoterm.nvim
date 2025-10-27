---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local instance = require("ergoterm.instance")
local Terminal = instance.Terminal
local config = require("ergoterm.config")
local utils = require("ergoterm.utils")
local mode = require("ergoterm.mode")
local test_helpers = require("test_helpers")

after_each(function()
  collection.cleanup_all({ close = true, force = true })
  collection.reset_ids()
end)

describe(":new", function()
  it("defaults to config's auto_scroll", function()
    local term = Terminal:new()

    assert.is_false(term.auto_scroll)
  end)

  it("defaults to config's bang_target", function()
    local term = Terminal:new()

    assert.is_true(term.bang_target)
  end)

  it("defaults to config's shell if cmd is not provided", function()
    local term = Terminal:new()

    assert.equal(vim.o.shell, term.cmd)
  end)

  it("defaults to config's clear_env", function()
    local term = Terminal:new()

    assert.is_false(term.clear_env)
  end)

  it("defaults to config's cleanup_on_success", function()
    local term = Terminal:new()

    assert.is_true(term.cleanup_on_success)
  end)

  it("defaults to config's cleanup_on_failure", function()
    local term = Terminal:new()

    assert.is_false(term.cleanup_on_failure)
  end)

  it("defaults to config's default_action", function()
    local term = Terminal:new()

    assert.is_function(term.default_action)
  end)

  it("defaults to config's show_on_success", function()
    local term = Terminal:new()

    assert.is_false(term.show_on_success)
  end)

  it("defaults to config's show_on_failure", function()
    local term = Terminal:new()

    assert.is_false(term.show_on_failure)
  end)

  it("defaults to config's layout", function()
    local term = Terminal:new()

    assert.equal("below", term.layout)
  end)

  it("defaults name to cmd option", function()
    local term = Terminal:new({ cmd = "echo hello" })

    assert.equal("echo hello", term.name)
  end)

  it("defaults to config's float_opts for non-given options", function()
    local term = Terminal:new({ float_opts = { width = 100, height = 20 } })

    assert.equal("single", term.float_opts.border)
  end)

  it("defaults to config's float_winblend", function()
    local term = Terminal:new()

    assert.equal(10, term.float_winblend)
  end)

  it("defaults to config's persist_mode", function()
    local term = Terminal:new()

    assert.is_false(term.persist_mode)
  end)

  it("defaults to config's persist_mode", function()
    local term = Terminal:new()

    assert.is_true(term.persist_size)
  end)

  it("defaults to config's start_in_insert", function()
    local term = Terminal:new()

    assert.is_true(term.start_in_insert)
  end)

  it("defaults to config's selectable", function()
    local term = Terminal:new()

    assert.is_true(term.selectable)
  end)

  it("defaults to config's sticky", function()
    local term = Terminal:new()

    assert.is_false(term.sticky)
  end)

  it("defaults to config's watch_files", function()
    local term = Terminal:new()

    assert.is_false(term.watch_files)
  end)

  it("defaults to config's tags", function()
    local term = Terminal:new()

    assert.equal(0, #term.tags)
  end)

  it("merges tags with defaults for non-given options", function()
    config.set({ terminal_defaults = { tags = { "default" } } })

    local term = Terminal:new({ tags = { "custom" } })

    assert.equal(1, #term.tags)
    assert.is_true(vim.tbl_contains(term.tags, "custom"))

    config.set({ terminal_defaults = { tags = {} } })
  end)

  it("defaults to config's size", function()
    local term = Terminal:new()

    assert.equal("50%", term.size.below)
    assert.equal("50%", term.size.above)
    assert.equal("50%", term.size.left)
    assert.equal("50%", term.size.right)
  end)

  it("defaults to config's float_opts", function()
    local term = Terminal:new()
    local float_opts = term.float_opts

    assert.equal(float_opts.title_pos, "left")
    assert.equal(float_opts.relative, "editor")
    assert.equal(float_opts.border, "single")
    assert.equal(float_opts.zindex, 50)
  end)

  it("merges float_opts with defaults for non-given options", function()
    local term = Terminal:new({ float_opts = { width = 100, height = 20 } })

    assert.equal("single", term.float_opts.border)
  end)

  it("merges size with defaults for non-given options", function()
    local term = Terminal:new({ size = { below = 20 } })

    assert.equal(20, term.size.below)
    assert.equal("50%", term.size.above)
    assert.equal("50%", term.size.left)
    assert.equal("50%", term.size.right)
  end)

  it("defaults to config's on_focus", function()
    local term = Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_focus)
  end)

  it("defaults to config's on_job_exit", function()
    local term = Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_job_exit)
  end)

  it("defaults to config's on_job_stdout", function()
    local term = Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_job_stdout)
  end)

  it("defaults to config's on_job_stderr", function()
    local term = Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_job_stderr)
  end)

  it("defaults to config's on_open", function()
    local term = Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_open)
  end)

  it("defaults to config's on_start", function()
    local term = Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_start)
  end)

  it("defaults to config's on_stop", function()
    local term = Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_stop)
  end)

  it("builds sequential ids", function()
    local term1 = Terminal:new()
    local term2 = Terminal:new()

    assert.equal(1, term1.id)
    assert.equal(2, term2.id)
  end)

  it("doesn't reuse ids from cleaned up terminal", function()
    local term1 = Terminal:new()
    term1:cleanup()
    local term2 = Terminal:new()

    assert.equal(2, term2.id)
  end)

  it("initializes directory as the current git directory if dir is given as 'git_dir'", function()
    local term = Terminal:new({ dir = "git_dir" })

    local expected_dir = vim.fn.getcwd()

    assert.equal(expected_dir, term:get_state("dir"))
  end)

  it("initializes directory as the current working directory if dir is nil", function()
    local term = Terminal:new({ dir = nil })

    local expected_dir = vim.fn.getcwd()

    assert.equal(expected_dir, term:get_state("dir"))
  end)

  it("initializes directory as the given directory if dir is a string", function()
    local term = Terminal:new({ dir = "/tmp" })

    assert.equal("/tmp", term:get_state("dir"))
  end)

  it("errors if dir is not a valid directory", function()
    local result = test_helpers.mocking_notify(function()
      Terminal:new({ dir = "/invalid" })
    end)

    assert.equal("/invalid is not a directory", result.msg)
    assert.equal("error", result.level)
  end)

  it("initializes layout from given layout", function()
    local term = Terminal:new({ layout = "right" })

    assert.equal("right", term:get_state("layout"))
  end)

  it("initializes float_opts title from name when not given", function()
    local term = Terminal:new({ name = "test" })

    assert.equal("test", term:get_state("float_opts").title)
  end)

  it("doesn't override float_opts title when given", function()
    local term = Terminal:new({ float_opts = { title = "foo" } })

    assert.equal("foo", term:get_state("float_opts").title)
  end)

  it("initializes float_opts row from height when not given", function()
    local term = Terminal:new({ float_opts = { height = 20 } })

    assert.equal(math.ceil((vim.o.lines - 20)) * 0.5 - 1, term:get_state("float_opts").row)
  end)

  it("doesn't override float_opts row when given", function()
    local term = Terminal:new({ float_opts = { row = 10 } })

    assert.equal(10, term:get_state("float_opts").row)
  end)

  it("initializes float_opts col from width when not given", function()
    local term = Terminal:new({ float_opts = { width = 100 } })

    assert.equal(math.ceil((vim.o.columns - 100)) * 0.5 - 1, term:get_state("float_opts").col)
  end)

  it("doesn't override float_opts col when given", function()
    local term = Terminal:new({ float_opts = { col = 10 } })

    assert.equal(10, term:get_state("float_opts").col)
  end)

  it("initializes size values", function()
    local term = Terminal:new({ size = { below = 20, right = "30%" } })

    assert.equal(20, term:get_state("size").below)
    assert.equal("30%", term:get_state("size").right)
  end)

  it("initializes on_job_exit so it calls provided on_job_exit", function()
    local foo = nil
    local term = Terminal:new({ on_job_exit = function() foo = "foo" end })

    term:get_state("on_job_exit")(1, 2, "event")
    assert.equal("foo", foo)
  end)

  it("initializes on_job_stdout so it calls provided on_job_stdout", function()
    local foo = nil
    local term = Terminal:new({ on_job_stdout = function() foo = "foo" end })

    term:get_state("on_job_stdout")(1, { "data" }, "name")
    assert.equal("foo", foo)
  end)

  it("initializes on_job_stderr so it calls provided on_job_stderr", function()
    local foo = nil
    local term = Terminal:new({ on_job_stderr = function() foo = "foo" end })

    term:get_state("on_job_stderr")(1, { "data" }, "name")
    assert.equal("foo", foo)
  end)

  it("initializes has_been_started to false", function()
    local term = Terminal:new()

    assert.is_false(term:get_state("has_been_started"))
  end)

  it("adds terminal to the list of terminals in the state", function()
    local term = Terminal:new()

    assert.is_true(vim.tbl_contains(collection.get_state("terminals"), term))
  end)
end)

describe(":update", function()
  it("updates terminal with given settings", function()
    local term = Terminal:new({ name = "foo", layout = "below" })
    term:update({ name = "bar", layout = "right" })

    assert.equal("bar", term.name)
    assert.equal("right", term.layout)
  end)

  it("deep merges table settings when deep_merge = true", function()
    local term = Terminal:new({ env = { FOO = "foo", BAR = "bar" } })
    term:update({ env = { BAZ = "baz" } }, { deep_merge = true })

    assert.equal("foo", term.env.FOO)
    assert.equal("bar", term.env.BAR)
    assert.equal("baz", term.env.BAZ)
  end)
end)

describe(":start", function()
  it("starts the terminal", function()
    local term = Terminal:new()

    term:start()

    local bufnr = term:get_state("bufnr")
    assert.is_not_nil(bufnr)
    assert.is_true(vim.api.nvim_buf_is_valid(bufnr))
  end)
end)

describe(":is_started", function()
  it("returns whether terminal is started", function()
    local term = Terminal:new():start()

    assert.is_true(term:is_started())
  end)
end)

describe(":stop", function()
  it("stops the terminal", function()
    local term = Terminal:new()
    term:start()

    term:stop()
    vim.wait(100)

    assert.is_false(term:is_started())
  end)
end)

describe(":is_active", function()
  it("returns true if terminal is started", function()
    local term = Terminal:new():start()

    assert.is_true(term:is_active())
  end)

  it("returns false if terminal is not started yet", function()
    local term = Terminal:new()

    assert.is_false(term:is_active())
  end)

  it("returns false if terminal started but has now been cleaned up", function()
    local term = Terminal:new({ cleanup_on_failure = true }):start()
    term:stop()
    vim.wait(100)

    assert.is_false(term:is_active())
  end)

  it("returns true if terminal started but has now stopped but not been cleaned up", function()
    local term = Terminal:new({ cleanup_on_failure = false }):start()
    term:stop()
    vim.wait(100)

    assert.is_true(term:is_active())
  end)

  it(
    "returns true if terminal started but has now stopped and although should not be cleaned up the buffer has been deleted",
    function()
      local term = Terminal:new({ cleanup_on_failure = false }):start()
      term:stop()
      vim.wait(100)
      local bufnr = term:get_state("bufnr")
      vim.api.nvim_buf_delete(bufnr, { force = true })

      assert.is_false(term:is_active())
    end)
end)

describe(":open", function()
  it("opens the terminal", function()
    local term = Terminal:new()

    term:open("right")

    local win_id = term:get_state("window")
    assert.is_true(vim.api.nvim_win_is_valid(win_id))
  end)
end)

describe(":is_open", function()
  it("returns whether terminal is open", function()
    local term = Terminal:new():open()

    assert.is_true(term:is_open())
  end)
end)

describe(":close", function()
  it("closes the terminal", function()
    local term = Terminal:new()
    term:open()
    local win_id = term:get_state("window")

    term:close()

    assert.is_false(vim.api.nvim_win_is_valid(win_id))
    assert.is_false(term:is_open())
  end)
end)

describe(":focus", function()
  it("focuses the terminal", function()
    local term = Terminal:new()
    term:open()

    term:focus()

    assert.equal(term:get_state("window"), vim.api.nvim_get_current_win())
  end)
end)

describe(":is_focused", function()
  it("returns whether the terminal is focused", function()
    local term = Terminal:new()

    term:focus()

    assert.is_true(term:is_focused())
  end)
end)

describe(":cleanup", function()
  it("cleans up the terminal", function()
    local term = Terminal:new()

    term:cleanup()

    assert.is_nil(collection.get(term.id))
  end)
end)

describe(":is_cleaned_up", function()
  it("returns whether the terminal has been cleaned up", function()
    local term = Terminal:new()
    term:start()

    term:cleanup()

    assert.is_true(term:is_cleaned_up())
  end)
end)

describe(":toggle", function()
  it("closes the terminal if open", function()
    local term = Terminal:new()
    term:open()

    term:toggle()

    assert.is_false(term:is_open())
  end)

  it("focuses the terminal if closed", function()
    local term = Terminal:new()
    term:open()
    term:close()

    term:toggle()

    assert.is_true(term:is_focused())
  end)

  it("uses given layout if given", function()
    local term = Terminal:new({ layout = "below" })
    term:open()
    term:close()

    term:toggle("left")

    assert.equal("left", term:get_state("layout"))
    assert.is_true(term:is_focused())
  end)
end)

describe(":send", function()
  it("sends input to the terminal process", function()
    local term = Terminal:new({ cmd = "cat" }):start()

    term:send({ "hello" })
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "hello"))
  end)

  it("sends text using selection type", function()
    local text_selector = require("ergoterm.text_selector")
    local original_select = text_selector.select
    --- @diagnostic disable-next-line: duplicate-set-field
    text_selector.select = function(selection_type)
      assert.equal("single_line", selection_type)
      return { "selected text" }
    end

    local term = Terminal:new({ cmd = "cat" }):start()
    term:send("single_line")
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "selected text"))

    text_selector.select = original_select
  end)

  it("resends last text when input is `last`", function()
    local term = Terminal:new({ cmd = "cat" }):start()

    term:send({ "first" })
    vim.wait(100)
    term:send("last")
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "first"))
    assert.is_true(vim.tbl_contains(lines, "first"))
  end)

  it("adds a newline by default", function()
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:send({ "foo" })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo", "" }
    )
  end)

  it("does not add a newline if new_line is false", function()
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:send({ "foo" }, { new_line = false })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo" }
    )
  end)

  it("trims input by default", function()
    local term = Terminal:new({ cmd = "cat" }):start()
    term:send({ "  baz  " })

    vim.wait(100)
    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)

    assert.is_true(vim.tbl_contains(lines, "baz"))
    assert.is_false(vim.tbl_contains(lines, "  baz  "))
  end)

  it("does not trim input if trim is false", function()
    local term = Terminal:new({ cmd = "cat" }):start()
    term:send({ "  qux  " }, { trim = false })

    vim.wait(100)
    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)

    assert.is_true(vim.tbl_contains(lines, "  qux  "))
  end)

  it("applies decorator function to input", function()
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")
    local decorator = function(text)
      local result = {}
      for _, line in ipairs(text) do
        table.insert(result, "decorated: " .. line)
      end
      return result
    end

    term:send({ "foo" }, { decorator = decorator })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "decorated: foo", "decorated: " }
    )
  end)

  it("applies decorator string to input", function()
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:send({ "foo" }, { decorator = "identity" })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo", "" }
    )
  end)

  it("falls back to identity decorator for unknown string decorator", function()
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:send({ "foo" }, { decorator = "unknown_decorator" })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo", "" }
    )
  end)

  it("uses identity function as default decorator", function()
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:send({ "foo" })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo", "" }
    )
  end)

  it("opens the terminal if action is open", function()
    local term = Terminal:new({ cmd = "cat" }):start()
    term:close()

    term:send({ "foo" }, { action = "open" })
    vim.wait(100)

    assert.is_true(term:is_open())
  end)

  it("focuses the terminal if action is focus", function()
    local term = Terminal:new({ cmd = "cat" }):start()
    term:close()

    term:send({ "foo" }, { action = "focus" })
    vim.wait(100)

    assert.is_true(term:is_focused())
  end)

  it("scrolls to the bottom after sending", function()
    local term = Terminal:new({ cmd = "cat" }):start()
    term:open()
    vim.api.nvim_win_set_cursor(term:get_state("window"), { 1, 0 })

    term:send({ "foo" })
    vim.wait(100)

    local cursor = vim.api.nvim_win_get_cursor(term:get_state("window"))
    local lines = vim.api.nvim_buf_line_count(term:get_state("bufnr"))
    assert.equal(lines, cursor[1])
  end)

  it("notifies error for invalid string input type", function()
    local term = Terminal:new():start()

    local result = test_helpers.mocking_notify(function()
      ---@diagnostic disable-next-line: param-type-mismatch
      term:send("invalid_type")
    end)

    ---@diagnostic disable: need-check-nil
    assert.equal(
      "Invalid input type 'invalid_type'. Must be a table with one item per line or one of: single_line, visual_lines, visual_selection, last",
      result.msg)
    assert.equal("error", result.level)
    ---@diagnostic enable: need-check-nil
  end)
end)

describe(":clear", function()
  local original_is_windows

  before_each(function()
    original_is_windows = utils.is_windows
  end)

  after_each(function()
    utils.is_windows = original_is_windows
  end)

  it("sends 'clear' to the terminal on Unix", function()
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_windows = function() return false end
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:clear()
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(term:get_state("job_id"), { "clear", "" })
  end)

  it("sends 'cls' to the terminal on Windows", function()
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_windows = function() return true end
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:clear()
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(term:get_state("job_id"), { "cls", "" })
  end)
end)

describe(":on_buf_enter", function()
  it("restores last mode if persist_mode is true", function()
    local term = Terminal:new({ persist_mode = true, start_in_insert = false }):start()
    local spy_mode_set = spy.on(mode, "set")

    term:on_buf_enter()

    assert.spy(spy_mode_set).was_called_with("n")
  end)

  it("starts in insert mode if persist_mode is false and start_in_insert is true", function()
    local term = Terminal:new({ persist_mode = false, start_in_insert = true }):start()
    local spy_mode_set_initial = spy.on(mode, "set_initial")

    term:on_buf_enter()

    assert.spy(spy_mode_set_initial).was_called_with(true)
  end)

  it("starts in normal mode if persist_mode is false and start_in_insert is false", function()
    local term = Terminal:new({ persist_mode = false, start_in_insert = false }):start()
    local spy_mode_set_initial = spy.on(mode, "set_initial")

    term:on_buf_enter()

    assert.spy(spy_mode_set_initial).was_called_with(false)
  end)

  it("sets the terminal as last focused", function()
    local term = Terminal:new():start()

    term:on_buf_enter()

    assert.equal(term, collection.get_last_focused())
  end)
end)

describe(":on_win_leave", function()
  it("persists mode if persist_mode is true", function()
    local term = Terminal:new({ persist_mode = true, start_in_insert = true }):start()
    local original_mode_get = mode.get
    ---@diagnostic disable-next-line: duplicate-set-field
    mode.get = function() return "n" end

    term:on_win_leave()

    assert.equal("n", term:get_state("mode"))

    mode.get = original_mode_get
  end)

  it("does not persist mode if persist_mode is false", function()
    local term = Terminal:new({ persist_mode = false, start_in_insert = true }):start()
    local original_mode_get = mode.get
    ---@diagnostic disable-next-line: duplicate-set-field
    mode.get = function() return "n" end

    term:on_win_leave()

    assert.equal("i", term:get_state("mode"))

    mode.get = original_mode_get
  end)


  it("closes terminal if layout is float", function()
    local term = Terminal:new({ layout = "float" }):open()

    term:on_win_leave()

    assert.is_false(term:is_open())
  end)

  it("does not close terminal if layout is not float", function()
    local term = Terminal:new({ layout = "below" }):open()

    term:on_win_leave()

    assert.is_true(term:is_open())
  end)
end)


describe(":on_vim_resized", function()
  it("applies new win config to float terminal", function()
    local term = Terminal:new({ layout = "float", float_opts = { width = 60, height = 30 } })
    term:open()
    local spy_win_set_config = spy.on(vim.api, "nvim_win_set_config")

    term:on_vim_resized()

    assert.spy(spy_win_set_config).was_called_with(term:get_state("window"), match.is_table())
  end)

  it("applies new win config to a split terminal", function()
    local term = Terminal:new({ layout = "right" })
    term:open()
    local spy_win_set_config = spy.on(vim.api, "nvim_win_set_config")

    term:on_vim_resized()

    assert.spy(spy_win_set_config).was_called_with(term:get_state("window"), match.is_table())
  end)

  it("does nothing if layout is not float", function()
    local term = Terminal:new({ layout = "tab" })
    term:open()
    local spy_win_set_config = spy.on(vim.api, "nvim_win_set_config")

    term:on_vim_resized()

    assert.spy(spy_win_set_config).was_not_called()
  end)
end)

describe(":_setup_buffer_autocommands", function()
  it("adds a VimResized autocommand", function()
    local term = Terminal:new()

    term:start()

    local bufnr = term:get_state("bufnr")
    local aucmds = vim.api.nvim_get_autocmds({
      event = "VimResized",
      buffer = bufnr,
      group = "ErgoTermBuffer",
    })

    assert.is_true(#aucmds > 0)
    assert.is_true(aucmds[1].buffer == bufnr)
    assert.is_true(aucmds[1].group_name == "ErgoTermBuffer")
  end)

  it("adds a BufWipeout autocommand", function()
    local term = Terminal:new()

    term:start()

    local bufnr = term:get_state("bufnr")
    local aucmds = vim.api.nvim_get_autocmds({
      event = "BufWipeout",
      buffer = bufnr,
      group = "ErgoTermBuffer",
    })

    assert.is_true(#aucmds > 0)
    assert.is_true(aucmds[1].buffer == bufnr)
    assert.is_true(aucmds[1].group_name == "ErgoTermBuffer")
  end)

  it("adds a WinClosed autocommand", function()
    local term = Terminal:new()

    term:start()

    local bufnr = term:get_state("bufnr")
    local aucmds = vim.api.nvim_get_autocmds({
      event = "WinClosed",
      buffer = bufnr,
      group = "ErgoTermBuffer",
    })

    assert.is_true(#aucmds > 0)
    assert.is_true(aucmds[1].buffer == bufnr)
    assert.is_true(aucmds[1].group_name == "ErgoTermBuffer")
  end)

  it("closes terminal when WinClosed event is triggered", function()
    local term = Terminal:new()
    term:open()
    local win_id = term:get_state("window")

    vim.api.nvim_win_close(win_id, true)
    vim.wait(100)

    assert.is_false(term:is_open())
  end)
end)

describe("on job exit", function()
  it("cleans up on successful exit when cleanup_on_success is true", function()
    local term = Terminal:new({ cleanup_on_success = true, cleanup_on_failure = false })
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    exit_handler(1, 0, "exit")

    assert.is_nil(collection.get(term.id))
    vim.schedule = original_schedule
  end)

  it("does not clean up on successful exit when cleanup_on_success is false", function()
    local term = Terminal:new({ cleanup_on_success = false, cleanup_on_failure = true })
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    exit_handler(1, 0, "exit")

    assert.is_not_nil(collection.get(term.id))
    vim.schedule = original_schedule
  end)

  it("cleans up on failed exit when cleanup_on_failure is true", function()
    local term = Terminal:new({ cleanup_on_success = false, cleanup_on_failure = true })
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    exit_handler(1, 1, "exit")

    assert.is_nil(collection.get(term.id))
    vim.schedule = original_schedule
  end)

  it("does not clean up on failed exit when cleanup_on_failure is false", function()
    local term = Terminal:new({ cleanup_on_success = true, cleanup_on_failure = false })
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    exit_handler(1, 1, "exit")

    assert.is_not_nil(collection.get(term.id))
    vim.schedule = original_schedule
  end)

  it("calls user's on_job_exit handler before cleanup", function()
    local called = false
    local term = Terminal:new({
      cleanup_on_success = true,
      on_job_exit = function() called = true end
    })
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    exit_handler(1, 0, "exit")

    assert.is_true(called)
    assert.is_nil(collection.get(term.id))
    vim.schedule = original_schedule
  end)

  it("opens on successful exit when show_on_success is true", function()
    local term = Terminal:new({ cleanup_on_success = false, show_on_success = true })
    term:start()
    local exit_handler = term:get_state("on_job_exit")

    exit_handler(1, 0, "exit")
    vim.wait(100)

    assert.is_true(term:is_open())
  end)

  it("does not open on successful exit when show_on_success is false", function()
    local term = Terminal:new({ cleanup_on_success = false, show_on_success = false })
    term:start()
    local exit_handler = term:get_state("on_job_exit")

    exit_handler(1, 0, "exit")
    vim.wait(100)

    assert.is_false(term:is_open())
  end)

  it("opens on failed exit when show_on_failure is true", function()
    local term = Terminal:new({ cleanup_on_failure = false, show_on_failure = true })
    term:start()
    local exit_handler = term:get_state("on_job_exit")

    exit_handler(1, 1, "exit")
    vim.wait(100)

    assert.is_true(term:is_open())
  end)

  it("does not open on failed exit when show_on_failure is false", function()
    local term = Terminal:new({ show_on_success = true, show_on_failure = false })
    term:start()
    local exit_handler = term:get_state("on_job_exit")

    exit_handler(1, 1, "exit")
    vim.wait(100)

    assert.is_false(term:is_open())
  end)

  it("does not restart process when show_on_success triggers", function()
    local term = Terminal:new({ cleanup_on_success = false, show_on_success = true })
    term:start()
    local exit_handler = term:get_state("on_job_exit")

    exit_handler(1, 0, "exit")
    vim.wait(100)

    assert.is_nil(term:get_state("job_id"))
    assert.is_true(term:is_open())
    assert.is_false(term:is_started())
  end)

  it("does not restart process when show_on_failure triggers", function()
    local term = Terminal:new({ cleanup_on_failure = false, show_on_failure = true })
    term:start()
    local exit_handler = term:get_state("on_job_exit")

    exit_handler(1, 1, "exit")
    vim.wait(100)

    assert.is_nil(term:get_state("job_id"))
    assert.is_true(term:is_open())
    assert.is_false(term:is_started())
  end)
end)

describe(":get_state", function()
  it("returns the given key in the state of the terminal", function()
    local term = Terminal:new()

    assert.equal("below", term:get_state("layout"))
  end)
end)

describe(":get_status_icon", function()
  it("returns play icon when terminal is started", function()
    local term = Terminal:new()
    term:start()

    assert.equal("▶", term:get_status_icon())
  end)

  it("returns success icon when stopped but active with exit code 0", function()
    local term = Terminal:new()
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    exit_handler(1, 0, "exit")

    assert.equal("✓", term:get_status_icon())
  end)

  it("returns failure icon when stopped but active with non-zero exit code", function()
    local term = Terminal:new()
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    exit_handler(1, 1, "exit")

    assert.equal("✗", term:get_status_icon())
  end)

  it("returns inactive icon otherwise", function()
    local term = Terminal:new({ sticky = true })

    assert.equal("○", term:get_status_icon())
  end)
end)

describe("on stdout", function()
  it("calls checktime after stdout when watch_files is true", function()
    local term = Terminal:new({ watch_files = true })
    term:start()
    local stdout_handler = term:get_state("on_job_stdout")
    local spy_cmd = spy.on(vim, "cmd")
    local original_schedule = vim.schedule
    local scheduled_fn
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) scheduled_fn = fn end

    stdout_handler(1, { "data" }, "stdout")
    scheduled_fn()

    assert.spy(spy_cmd).was_called_with("checktime")

    vim.schedule = original_schedule
  end)

  it("calls checktime after stderr when watch_files is true", function()
    local term = Terminal:new({ watch_files = true })
    term:start()
    local stderr_handler = term:get_state("on_job_stderr")
    local spy_cmd = spy.on(vim, "cmd")
    local original_schedule = vim.schedule
    local scheduled_fn
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) scheduled_fn = fn end

    stderr_handler(1, { "data" }, "stderr")
    scheduled_fn()

    assert.spy(spy_cmd).was_called_with("checktime")

    vim.schedule = original_schedule
  end)

  it("does not call checktime when watch_files is false", function()
    local term = Terminal:new({ watch_files = false })
    term:start()
    local stdout_handler = term:get_state("on_job_stdout")
    local spy_cmd = spy.on(vim, "cmd")
    local original_schedule = vim.schedule
    local scheduled_fn
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) scheduled_fn = fn end

    stdout_handler(1, { "data" }, "stdout")
    if scheduled_fn then scheduled_fn() end

    assert.spy(spy_cmd).was_not_called_with("checktime")

    vim.schedule = original_schedule
  end)
end)
