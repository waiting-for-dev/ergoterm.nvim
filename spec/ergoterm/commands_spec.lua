---@diagnostic disable: undefined-field

local commands = require("ergoterm.commands")
local terms = require("ergoterm")
local test_helpers = require("test_helpers")
local utils = require("ergoterm.utils")

after_each(function()
  terms.cleanup_all({ force = true })
  terms.reset_ids()
end)

describe("M.new", function()
  it("creates a new terminal", function()
    local term = commands.new("")

    assert.is_not_nil(term)
  end)

  it("creates a new terminal in the given directory", function()
    local original_expand = vim.fn.expand
    local original_isdirectory = vim.fn.isdirectory
    --- @diagnostic disable: duplicate-set-field
    vim.fn.expand = function(path) return path end
    vim.fn.isdirectory = function(_) return 1 end
    --- @diagnostic enable: duplicate-set-field

    local term = commands.new("dir=/tmp")

    assert.is_not_nil(term)
    assert.equal("/tmp", term:get_state("dir"))

    vim.fn.expand = original_expand
    vim.fn.isdirectory = original_isdirectory
  end)

  it("creates a new terminal with defaults when not explicitly given", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.equal("below", term:get_state("layout"))
  end)

  it("creates a new terminal with overrides to the defaults when given", function()
    local term = commands.new("layout=right")

    assert.is_not_nil(term)
    assert.equal("right", term:get_state("layout"))
  end)

  it("creates a new terminal with list settings when given separated by commas", function()
    local term = commands.new("tags=tag1,tag2,tag3")

    assert.is_not_nil(term)
    assert.is_table(term.tags)
    assert.equal(3, #term.tags)
    assert.is_true(vim.tbl_contains(term.tags, "tag1"))
    assert.is_true(vim.tbl_contains(term.tags, "tag2"))
    assert.is_true(vim.tbl_contains(term.tags, "tag3"))
  end)

  it("creates a new terminal with table settings when keys are separated by dots", function()
    local term = commands.new("size.above=10 size.below=20%")

    assert.is_not_nil(term)
    assert.is_table(term.size)
    assert.equal(10, term.size.above)
    assert.equal("20%", term.size.below)
  end)

  it("keeps default table settings when only some keys are given", function()
    local term = commands.new("float_opts.border=double")

    assert.is_not_nil(term)
    assert.is_table(term.float_opts)
    assert.equal("double", term.float_opts.border)
    assert.equal("left", term.float_opts.title_pos)
  end)
end)

describe("M.select", function()
  it("calls picker with the configured select options", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term1 = terms.Terminal:new():start()
    local term2 = terms.Terminal:new():start()

    local result = commands.select("", false, picker)

    assert.equal("Please select a terminal: ", result[2])
    assert.is_table(result[3])
    assert.equal(2, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term1))
    assert.is_true(vim.tbl_contains(result[1], term2))
  end)

  it("doesn't short circuit when there's only one terminal but it's not called with either bang or target", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term = terms.Terminal:new():start()

    local result = commands.select("", false, picker)

    assert.equal("Please select a terminal: ", result[2])
    assert.is_table(result[3])
    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term))
  end)

  it("focuses last focused terminal when called with bang", function()
    local term = terms.Terminal:new():start()
    term:focus()
    local spy_focus = spy.on(term, "focus")
    local null_picker = {
      select = function() return nil end
    }

    local result = commands.select("", true, null_picker)

    assert.spy(spy_focus).was_called()
  end)

  it("ignores non bang target terminals when called with bang", function()
    local term = terms.Terminal:new():start()
    local term_not_auto_list = terms.Terminal:new({ bang_target = false }):start()
    term:focus()
    term_not_auto_list:focus()
    local spy_focus = spy.on(term, "focus")

    commands.select("", true, {})

    assert.spy(spy_focus).was_called()
  end)

  it("notifies when bang is given but no last focused terminal exists", function()
    local notify_result = test_helpers.mocking_notify(function()
      commands.select("", true, {})
    end)

    assert.equal("No terminals are open", notify_result.msg)
    assert.equal("error", notify_result.level)
  end)

  it("focuses terminal by name when target option is provided", function()
    local term1 = terms.Terminal:new({ name = "target-term" }):start()
    local term2 = terms.Terminal:new({ name = "other-term" }):start()
    local spy_focus1 = spy.on(term1, "focus")
    local spy_focus2 = spy.on(term2, "focus")

    commands.select("target=target-term", false, {})

    assert.spy(spy_focus1).was_called()
    assert.spy(spy_focus2).was_not_called()
  end)

  it("notifies when target terminal does not exist", function()
    terms.Terminal:new({ name = "existing-term" }):start()
    local notify_result = test_helpers.mocking_notify(function()
      local result = commands.select("target=nonexistent", false, {})
    end)

    --- @diagnostic disable: need-check-nil
    assert.equal("Terminal 'nonexistent' not found", notify_result.msg)
    assert.equal("error", notify_result.level)
    --- @diagnostic enable: need-check-nil
  end)

  it("notifies when both target and bang are provided", function()
    local term = terms.Terminal:new({ name = "test-term" }):start()
    term:focus()
    local notify_result = test_helpers.mocking_notify(function()
      local result = commands.select("target=test-term", true, {})
    end)

    --- @diagnostic disable: need-check-nil
    assert.equal("Cannot use both target and ! options", notify_result.msg)
    assert.equal("error", notify_result.level)
    --- @diagnostic enable: need-check-nil
  end)
end)

describe("M.send", function()
  local text_selector = require("ergoterm.instance.send.text_selector")
  local select_only_picker = {
    select = function(terminals, _, callbacks)
      callbacks.default.fn(terminals[1])
    end
  }
  local null_picker = {
    select = function() return nil end
  }
  local original_select

  before_each(function()
    original_select = text_selector.select
    --- @diagnostic disable-next-line: duplicate-set-field
    text_selector.select = function() return { "test line" } end
  end)

  after_each(function()
    text_selector.select = original_select
  end)

  it("sends given text to the terminal", function()
    local term = terms.Terminal:new():start()
    local spy_send = spy.on(term, "send")

    commands.send("text='hello world'", 0, false, select_only_picker)

    assert.spy(spy_send).was_called_with(match._, { "hello world" }, {
      action = nil,
      trim = nil,
      new_line = nil,
      decorator = nil
    })
  end)

  it("sends according to given action", function()
    local term = terms.Terminal:new():start()
    local spy_send = spy.on(term, "send")

    commands.send("action=start", 0, false, select_only_picker)

    assert.spy(spy_send).was_called_with(match._, "single_line", {
      action = "start",
      trim = nil,
      new_line = nil,
      decorator = nil
    })
  end)

  it("decorates text with given decorator", function()
    local term = terms.Terminal:new():start()
    local spy_send = spy.on(term, "send")

    commands.send("decorator=markdown_code", 0, false, select_only_picker)

    assert.spy(spy_send).was_called_with(match._, "single_line", {
      action = nil,
      trim = nil,
      new_line = nil,
      decorator = "markdown_code"
    })
  end)

  it("trims text if specified", function()
    local term = terms.Terminal:new():start()
    local spy_send = spy.on(term, "send")

    commands.send("trim=false", 0, false, select_only_picker)

    assert.spy(spy_send).was_called_with(match._, "single_line", {
      action = nil,
      trim = false,
      new_line = nil,
      decorator = nil
    })
  end)

  it("adds new_line if specified", function()
    local term = terms.Terminal:new():start()
    local spy_send = spy.on(term, "send")

    commands.send("new_line=false", 0, false, select_only_picker)

    assert.spy(spy_send).was_called_with(match._, "single_line", {
      action = nil,
      trim = nil,
      new_line = false,
      decorator = nil
    })
  end)

  it("clear screen if specified", function()
    local original_is_windows = utils.is_windows
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_windows = function() return false end

    local term = terms.Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    commands.send("clear=true text='after clear'", 0, false, select_only_picker)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "clear", "" }
    )

    utils.is_windows = original_is_windows
  end)

  it("uses last focused terminal when called with the bang option", function()
    local term = terms.Terminal:new():start()
    term:focus()
    local spy_send = spy.on(term, "send")

    commands.send("text='bang test'", 0, true, null_picker)

    assert.spy(spy_send).was_called_with(match._, { "bang test" }, {
      action = nil,
      trim = nil,
      new_line = nil,
      decorator = nil
    })
  end)

  it("ignores non bang target terminals when called with the bang option", function()
    local term = terms.Terminal:new():start()
    local term_not_bang_target = terms.Terminal:new({ bang_target = false }):start()
    term:focus()
    term_not_bang_target:focus()
    local spy_send = spy.on(term, "send")

    commands.send("text='bang test'", 0, true, null_picker)

    assert.spy(spy_send).was_called_with(match._, { "bang test" }, {
      action = nil,
      trim = nil,
      new_line = nil,
      decorator = nil
    })
  end)

  it("calls picker to select a terminal when not in bang mode", function()
    local term = terms.Terminal:new():start()
    local spy_send = spy.on(term, "send")

    commands.send("text='picker test'", 0, false, select_only_picker)

    assert.spy(spy_send).was_called_with(match._, { "picker test" }, {
      action = nil,
      trim = nil,
      new_line = nil,
      decorator = nil
    })
  end)

  it("notifies when no terminals are focused in bang mode", function()
    local notify_result = test_helpers.mocking_notify(function()
      commands.send("text='no focus'", 0, true, null_picker)
    end)

    assert.equal("No terminals are open", notify_result.msg)
    assert.equal("error", notify_result.level)
  end)

  it("uses text selector for visual selection when range > 0", function()
    local term = terms.Terminal:new():start()
    local spy_send = spy.on(term, "send")
    local original_visualmode = vim.fn.visualmode
    --- @diagnostic disable-next-line: duplicate-set-field
    vim.fn.visualmode = function() return "V" end

    commands.send("", 1, false, select_only_picker)

    assert.spy(spy_send).was_called_with(match._, "visual_lines", {
      action = nil,
      trim = nil,
      new_line = nil,
      decorator = nil
    })

    vim.fn.visualmode = original_visualmode
  end)

  it("uses text selector for visual selection when range > 0 and visual mode is not line-wise", function()
    local term = terms.Terminal:new():start()
    local spy_send = spy.on(term, "send")
    local original_visualmode = vim.fn.visualmode
    --- @diagnostic disable-next-line: duplicate-set-field
    vim.fn.visualmode = function() return "v" end

    commands.send("", 1, false, select_only_picker)

    assert.spy(spy_send).was_called_with(match._, "visual_selection", {
      action = nil,
      trim = nil,
      new_line = nil,
      decorator = nil
    })

    vim.fn.visualmode = original_visualmode
  end)

  it("uses text selector for single line when range is 0", function()
    local term = terms.Terminal:new():start()
    local spy_send = spy.on(term, "send")

    commands.send("", 0, false, select_only_picker)

    assert.spy(spy_send).was_called_with(match._, "single_line", {
      action = nil,
      trim = nil,
      new_line = nil,
      decorator = nil
    })
  end)

  it("sends to terminal by name when target option is provided", function()
    local term1 = terms.Terminal:new({ name = "target-term" }):start()
    local term2 = terms.Terminal:new({ name = "other-term" }):start()
    local spy_send1 = spy.on(term1, "send")
    local spy_send2 = spy.on(term2, "send")

    commands.send("target=target-term text='test'", 0, false, select_only_picker)

    assert.spy(spy_send1).was_called_with(match._, { "test" }, {
      action = nil,
      trim = nil,
      new_line = nil,
      decorator = nil
    })
    assert.spy(spy_send2).was_not_called()
  end)

  it("notifies when target terminal does not exist for send", function()
    terms.Terminal:new({ name = "existing-term" }):start()
    local notify_result = test_helpers.mocking_notify(function()
      commands.send("target=nonexistent text='test'", 0, false, null_picker)
    end)

    --- @diagnostic disable: need-check-nil
    assert.equal("Terminal 'nonexistent' not found", notify_result.msg)
    assert.equal("error", notify_result.level)
    --- @diagnostic enable: need-check-nil
  end)
end)

describe("M.update", function()
  local select_only_picker = {
    select = function(terminals, _, callbacks)
      callbacks.default.fn(terminals[1])
    end
  }
  local null_picker = {
    select = function() return nil end
  }

  it("updates plain options", function()
    local term = terms.Terminal:new({ sticky = true })

    commands.update("layout=right", false, select_only_picker)

    assert.equal("right", term.layout)
  end)

  it("merges given table options", function()
    local term = terms.Terminal:new({ size = { above = 10 }, sticky = true })

    commands.update("size.below=20%", false, select_only_picker)

    assert.is_table(term.size)
    assert.equal(10, term.size.above)
    assert.equal("20%", term.size.below)
  end)

  it("ignores non bang target terminals when called with the bang option", function()
    local term = terms.Terminal:new({ sticky = true })
    local term_not_bang_target = terms.Terminal:new({ bang_target = false }):start()
    term:focus()
    term_not_bang_target:focus()

    commands.update("layout=right", true, null_picker)

    assert.equal("right", term.layout)
    assert.equal("below", term_not_bang_target.layout)
  end)

  it("notifies when bang is given but no last focused terminal exists", function()
    local notify_result = test_helpers.mocking_notify(function()
      commands.update("layout=right", true, null_picker)
    end)

    assert.equal("No terminals are open", notify_result.msg)
    assert.equal("error", notify_result.level)
  end)

  it("calls picker to select a terminal when not in bang mode", function()
    local term = terms.Terminal:new():start()

    commands.update("layout=left", false, select_only_picker)

    assert.equal("left", term.layout)
  end)

  it("updates terminal by name when target option is provided", function()
    local term1 = terms.Terminal:new({ name = "target-term", sticky = true })
    local term2 = terms.Terminal:new({ name = "other-term", sticky = true })

    commands.update("target=target-term layout=right", false, select_only_picker)

    assert.equal("right", term1.layout)
    assert.equal("below", term2.layout)
  end)

  it("notifies when target terminal does not exist for update", function()
    terms.Terminal:new({ name = "existing-term", sticky = true })
    local notify_result = test_helpers.mocking_notify(function()
      commands.update("target=nonexistent layout=left", false, null_picker)
    end)

    assert.equal("Terminal 'nonexistent' not found", notify_result.msg)
    assert.equal("error", notify_result.level)
  end)
end)

describe("M.inspect", function()
  local select_only_picker = {
    select = function(terminals, _, callbacks)
      callbacks.default.fn(terminals[1])
    end
  }
  local null_picker = {
    select = function() return nil end
  }

  it("calls vim.print with vim.inspect on selected terminal", function()
    terms.Terminal:new({ name = "foo", sticky = true })
    local original_print = vim.print
    local print_called = false
    local print_arg = nil
    --- @diagnostic disable-next-line: duplicate-set-field
    vim.print = function(passed_arg)
      print_called = true
      print_arg = passed_arg
    end

    commands.inspect("", false, select_only_picker)

    assert.is_true(print_called)
    assert.is_string(print_arg)
    ---@cast print_arg string
    assert.is_true(string.find(print_arg, 'name = "foo"', 1, true) ~= nil)

    vim.print = original_print
  end)

  it("uses last focused terminal when called with bang", function()
    terms.Terminal:new({ name = "foo", sticky = true }):focus()
    local original_print = vim.print
    local print_called = false
    local print_arg = nil
    --- @diagnostic disable-next-line: duplicate-set-field
    vim.print = function(passed_arg)
      print_called = true
      print_arg = passed_arg
    end

    commands.inspect("", true, null_picker)

    assert.is_true(print_called)
    assert.is_string(print_arg)
    ---@cast print_arg string
    assert.is_true(string.find(print_arg, 'name = "foo"', 1, true) ~= nil)

    vim.print = original_print
  end)

  it("inspects terminal by name when target option is provided", function()
    terms.Terminal:new({ name = "foo", sticky = true })
    local original_print = vim.print
    local print_called = false
    local print_arg = nil
    --- @diagnostic disable-next-line: duplicate-set-field
    vim.print = function(passed_arg)
      print_called = true
      print_arg = passed_arg
    end

    commands.inspect("target=foo", false, select_only_picker)

    assert.is_true(print_called)
    assert.is_string(print_arg)
    ---@cast print_arg string
    assert.is_true(string.find(print_arg, 'name = "foo"', 1, true) ~= nil)

    vim.print = original_print
  end)

  it("notifies when target terminal does not exist for inspect", function()
    terms.Terminal:new({ name = "existing-term", sticky = true })
    local notify_result = test_helpers.mocking_notify(function()
      commands.inspect("target=nonexistent", false, null_picker)
    end)

    assert.equal("Terminal 'nonexistent' not found", notify_result.msg)
    assert.equal("error", notify_result.level)
  end)
end)

describe("M.toggle_universal_selection", function()
  it("toggles universal selection and notifies when enabled", function()
    local notify_result = test_helpers.mocking_notify(function()
      local result = commands.toggle_universal_selection()
      assert.is_true(result)
    end)

    assert.equal("Universal selection enabled", notify_result.msg)
    assert.equal("info", notify_result.level)

    terms.toggle_universal_selection()
  end)

  it("toggles universal selection and notifies when disabled", function()
    terms.toggle_universal_selection()

    local notify_result = test_helpers.mocking_notify(function()
      local result = commands.toggle_universal_selection()
      assert.is_false(result)
    end)

    assert.equal("Universal selection disabled", notify_result.msg)
    assert.equal("info", notify_result.level)

    terms.toggle_universal_selection()
  end)
end)
