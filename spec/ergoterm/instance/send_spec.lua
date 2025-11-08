---@diagnostic disable: undefined-field

local config = require("ergoterm.config")
local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local send = require("ergoterm.instance.send")
local test_helpers = require("test_helpers")
local utils = require("ergoterm.utils")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(":send", function()
  it("sends input to the terminal process", function()
    local term = Terminal:new():start()

    send.send(term, { "hello" })
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "hello"))
  end)

  it("sends selected text when input is a selection string", function()
    local text_selector = require("ergoterm.instance.send.text_selector")
    local original_select = text_selector.select
    --- @diagnostic disable-next-line: duplicate-set-field
    text_selector.select = function()
      return { "selected text" }
    end

    local term = Terminal:new():start()
    send.send(term, "single_line")
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "selected text"))

    text_selector.select = original_select
  end)

  it("resends last sent text when input is `last`", function()
    local term = Terminal:new():start()

    send.send(term, { "first" })
    vim.wait(100)
    send.send(term, "last")
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "first"))
    assert.is_true(vim.tbl_contains(lines, "first"))
  end)

  it("notifies error for invalid string input type", function()
    local term = Terminal:new():start()

    local result = test_helpers.mocking_notify(function()
      ---@diagnostic disable-next-line: param-type-mismatch
      send.send(term, "invalid_type")
    end)

    assert.equal(
      "Invalid input type 'invalid_type'. Must be a table with one item per line or one of: single_line, visual_lines, visual_selection, last",
      result.msg)
    assert.equal("error", result.level)
  end)

  it("adds a newline by default", function()
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    send.send(term, { "foo" })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo", "" }
    )
  end)

  it("does not add a newline if new_line is false", function()
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    send.send(term, { "foo" }, { new_line = false })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo" }
    )
  end)

  it("trims input by default", function()
    local term = Terminal:new():start()

    send.send(term, { "  baz  " })
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "baz"))
    assert.is_false(vim.tbl_contains(lines, "  baz  "))
  end)

  it("does not trim input if trim is false", function()
    local term = Terminal:new():start()

    send.send(term, { "  qux  " }, { trim = false })
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "  qux  "))
  end)

  it("applies decorator to input", function()
    local term = Terminal:new():start()
    local decorator = function(text)
      local result = {}
      for _, line in ipairs(text) do
        table.insert(result, "decorated: " .. line)
      end
      return result
    end

    send.send(term, { "foo" }, { decorator = decorator })
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "decorated: foo"))
  end)

  it("parses decorator given as a string from the config", function()
    local original_extra_decorators = config.text_decorators.extra

    config.text_decorators.extra["test_decorator"] = function(text)
      local result = {}
      for _, line in ipairs(text) do
        table.insert(result, "decorated: " .. line)
      end
      return result
    end
    local term = Terminal:new():start()

    send.send(term, { "foo" }, { decorator = "test_decorator" })
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "decorated: foo"))

    config.text_decorators.extra = original_extra_decorators
  end)

  it("notifies and falls back to identity when decorator is not known", function()
    local term = Terminal:new():start()

    local result = test_helpers.mocking_notify(function()
      send.send(term, { "foo" }, { decorator = "unknown_decorator" })
    end)
    vim.wait(100)

    assert.equal(
      "Decorator 'unknown_decorator' not found. Using identity decorator.",
      result.msg)
    assert.equal("warn", result.level)
    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "foo"))
  end)

  it("only starts the terminal if action is start", function()
    local term = Terminal:new()

    send.send(term, { "foo" }, { action = "start" })
    vim.wait(100)

    assert.is_true(term:is_started())
    assert.is_false(term:is_open())
  end)

  it("only opens the terminal if action is open", function()
    local term = Terminal:new():start()

    send.send(term, { "foo" }, { action = "open" })
    vim.wait(100)

    assert.is_true(term:is_open())
    assert.is_false(term:is_focused())
  end)

  it("focuses the terminal if action is focus", function()
    local term = Terminal:new()

    send.send(term, { "foo" }, { action = "focus" })
    vim.wait(100)

    assert.is_true(term:is_focused())
  end)

  it("defaults to focus action", function()
    local term = Terminal:new()

    send.send(term, { "foo" })
    vim.wait(100)

    assert.is_true(term:is_focused())
  end)

  it("scrolls to the bottom after sending", function()
    local term = Terminal:new():open()
    vim.api.nvim_win_set_cursor(term:get_state("window"), { 1, 0 })

    send.send(term, { "line1", "line2", "line3" })
    vim.wait(100)

    local cursor = vim.api.nvim_win_get_cursor(term:get_state("window"))
    local lines = vim.api.nvim_buf_line_count(term:get_state("bufnr"))
    assert.equal(lines, cursor[1])
  end)
end)

describe(".clear", function()
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

    send.clear(term)
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "clear", "" }
    )
  end)

  it("sends 'cls' to the terminal on Windows", function()
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_windows = function() return true end
    local term = Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    send.clear(term)
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "cls", "" }
    )
  end)

  it("delegates action option to send", function()
    local term = Terminal:new():start()

    send.clear(term, "open")
    vim.wait(100)

    assert.is_true(term:is_open())
  end)
end)
