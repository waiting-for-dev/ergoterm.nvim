---@diagnostic disable: undefined-field

local commands = require("ergoterm.commands")
local terms = require("ergoterm.terminal")
local test_helpers = require("test_helpers")

after_each(function()
  terms.cleanup_all({ close = true, force = true })
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

  it("creates a new terminal with 'below' layout by default", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.equal("below", term:get_state("layout"))
  end)

  it("creates a new terminal with the given layout", function()
    local term = commands.new("layout=right")

    assert.is_not_nil(term)
    assert.equal("right", term:get_state("layout"))
  end)

  it("creates a new terminal with the command name by default", function()
    local term = commands.new("cmd=/bin/bash")

    assert.is_not_nil(term)
    assert.equal("/bin/bash", term.name)
  end)

  it("creates a new terminal with the given name", function()
    local term = commands.new("name=test-terminal")

    assert.is_not_nil(term)
    assert.equal("test-terminal", term.name)
  end)

  it("creates a new terminal with the shell as command by default", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.equal(vim.o.shell, term.cmd)
  end)

  it("creates a new terminal with the given command", function()
    local term = commands.new("cmd=/bin/bash")

    assert.is_not_nil(term)
    assert.equal("/bin/bash", term.cmd)
  end)

  it("focuses the newly created terminal", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.is_true(term:is_focused())
  end)

  it("creates a new terminal with auto_scroll=false by default", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.is_false(term.auto_scroll)
  end)

  it("creates a new terminal with the given auto_scroll option", function()
    local term = commands.new("auto_scroll=false")

    assert.is_not_nil(term)
    assert.is_false(term.auto_scroll)
  end)

  it("creates a new terminal with bang_target=true by default", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.is_true(term.bang_target)
  end)

  it("creates a new terminal with the given bang_target option", function()
    local term = commands.new("bang_target=false")

    assert.is_not_nil(term)
    assert.is_false(term.bang_target)
  end)

  it("creates a new terminal with persist_mode=false by default", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.is_false(term.persist_mode)
  end)

  it("creates a new terminal with the given persist_mode option", function()
    local term = commands.new("persist_mode=true")

    assert.is_not_nil(term)
    assert.is_true(term.persist_mode)
  end)

  it("creates a new terminal with selectable=true by default", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.is_true(term.selectable)
  end)

  it("creates a new terminal with the given selectable option", function()
    local term = commands.new("selectable=false")

    assert.is_not_nil(term)
    assert.is_false(term.selectable)
  end)

  it("creates a new terminal with start_in_insert=true by default", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.is_true(term.start_in_insert)
  end)

  it("creates a new terminal with the given start_in_insert option", function()
    local term = commands.new("start_in_insert=false")

    assert.is_not_nil(term)
    assert.is_false(term.start_in_insert)
  end)

  it("creates a new terminal with cleanup_on_success=true by default", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.is_true(term.cleanup_on_success)
  end)

  it("creates a new terminal with cleanup_on_failure=false by default", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.is_false(term.cleanup_on_failure)
  end)

  it("creates a new terminal with sticky=false by default", function()
    local term = commands.new("")

    assert.is_not_nil(term)
    assert.is_false(term.sticky)
  end)

  it("creates a new terminal with the given sticky option", function()
    local term = commands.new("sticky=true")

    assert.is_not_nil(term)
    assert.is_true(term.sticky)
  end)

  it("creates a new terminal with multiple configuration options", function()
    local term = commands.new(
      "layout=float auto_scroll=false persist_mode=true selectable=false start_in_insert=false sticky=true cleanup_on_success=false cleanup_on_failure=true")

    assert.is_not_nil(term)
    assert.equal("float", term:get_state("layout"))
    assert.is_false(term.auto_scroll)
    assert.is_true(term.persist_mode)
    assert.is_false(term.selectable)
    assert.is_false(term.start_in_insert)
    assert.is_true(term.sticky)
    assert.is_false(term.cleanup_on_success)
    assert.is_true(term.cleanup_on_failure)
  end)
end)

describe("M.select", function()
  it("calls picker with the configured select options", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term = terms.Terminal:new():start()

    local result = commands.select(false, picker)

    assert.equal("Please select a terminal to open (or focus): ", result[2])
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

    local result = commands.select(true, null_picker)

    assert.spy(spy_focus).was_called()
    assert.is_true(result)
  end)

  it("ignores non bang target terminals when called with bang", function()
    local term = terms.Terminal:new():start()
    local term_not_selectable = terms.Terminal:new({ bang_target = false }):start()
    term:focus()
    term_not_selectable:focus()
    local spy_focus = spy.on(term, "focus")

    commands.select(true, {})

    assert.spy(spy_focus).was_called()
  end)

  it("notifies when bang is given but no last focused terminal exists", function()
    local notify_result = test_helpers.mocking_notify(function()
      local result = commands.select(true, {})
      assert.is_false(result)
    end)

    --- @diagnostic disable: need-check-nil
    assert.equal("No terminals are open", notify_result.msg)
    assert.equal("error", notify_result.level)
    --- @diagnostic enable: need-check-nil
  end)
end)

describe("M.send", function()
  local text_selector = require("ergoterm.text_selector")
  local text_decorators = require("ergoterm.text_decorators")
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

    commands.send("action=silent", 0, false, select_only_picker)

    assert.spy(spy_send).was_called_with(term, "single_line", {
      action = "silent",
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
      local result = commands.send("text='no focus'", 0, true, null_picker)
      assert.is_false(result)
    end)

    --- @diagnostic disable: need-check-nil
    assert.equal("No terminals are open", notify_result.msg)
    assert.equal("error", notify_result.level)
    --- @diagnostic enable: need-check-nil
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

  it("updates layout option", function()
    local term = terms.Terminal:new():start()

    commands.update("layout=right", false, select_only_picker)

    assert.equal("right", term.layout)
  end)

  it("updates name option", function()
    local term = terms.Terminal:new():start()

    commands.update("name=test-terminal", false, select_only_picker)

    assert.equal("test-terminal", term.name)
  end)

  it("updates auto_scroll option", function()
    local term = terms.Terminal:new():start()

    commands.update("auto_scroll=false", false, select_only_picker)

    assert.is_false(term.auto_scroll)
  end)

  it("updates persist_mode option", function()
    local term = terms.Terminal:new():start()

    commands.update("persist_mode=true", false, select_only_picker)

    assert.is_true(term.persist_mode)
  end)

  it("updates selectable option", function()
    local term = terms.Terminal:new():start()

    commands.update("selectable=false", false, select_only_picker)

    assert.is_false(term.selectable)
  end)

  it("updates start_in_insert option", function()
    local term = terms.Terminal:new():start()

    commands.update("start_in_insert=false", false, select_only_picker)

    assert.is_false(term.start_in_insert)
  end)

  it("updates sticky option", function()
    local term = terms.Terminal:new():start()

    commands.update("sticky=true", false, select_only_picker)

    assert.is_true(term.sticky)
  end)

  it("uses last focused terminal when called with the bang option", function()
    local term = terms.Terminal:new():start()
    term:focus()

    commands.update("layout=right", true, null_picker)

    assert.equal("right", term.layout)
  end)

  it("ignores non bang target terminals when called with the bang option", function()
    local term = terms.Terminal:new():start()
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

    --- @diagnostic disable: need-check-nil
    assert.equal("No terminals are open", notify_result.msg)
    assert.equal("error", notify_result.level)
    --- @diagnostic enable: need-check-nil
  end)

  it("calls picker to select a terminal when not in bang mode", function()
    local term = terms.Terminal:new():start()

    commands.update("layout=left", false, select_only_picker)

    assert.equal("left", term.layout)
  end)
end)

describe("M.toggle_universal_selection", function()
  it("toggles universal selection and notifies when enabled", function()
    local notify_result = test_helpers.mocking_notify(function()
      local result = commands.toggle_universal_selection()
      assert.is_true(result)
    end)

    --- @diagnostic disable: need-check-nil
    assert.equal("Universal selection enabled", notify_result.msg)
    assert.equal("info", notify_result.level)
    --- @diagnostic enable: need-check-nil

    terms.toggle_universal_selection()
  end)

  it("toggles universal selection and notifies when disabled", function()
    terms.toggle_universal_selection()

    local notify_result = test_helpers.mocking_notify(function()
      local result = commands.toggle_universal_selection()
      assert.is_false(result)
    end)

    --- @diagnostic disable: need-check-nil
    assert.equal("Universal selection disabled", notify_result.msg)
    assert.equal("info", notify_result.level)
    --- @diagnostic enable: need-check-nil

    terms.toggle_universal_selection()
  end)
end)
