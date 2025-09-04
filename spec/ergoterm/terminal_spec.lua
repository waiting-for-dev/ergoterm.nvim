---@diagnostic disable: undefined-field

local terms = require("ergoterm.terminal")
local config = require("ergoterm.config")
local utils = require("ergoterm.utils")
local mode = require("ergoterm.mode")
local test_helpers = require("test_helpers")

after_each(function()
  terms.cleanup_all({ close = true, force = true })
  terms.reset_ids()
end)

describe(".get_focused", function()
  it("returns currently focused terminal", function()
    local term = terms.Terminal:new()
    term:focus()

    local result = terms.get_focused()

    assert.equal(result, term)
  end)

  it("returns nil when there are terminals but none are focused", function()
    local term = terms.Terminal:new()
    term:focus()
    term:close()

    assert.is_nil(
      terms.get_focused()
    )
  end)

  it("returns nil when no terminals exist", function()
    assert.is_nil(
      terms.get_focused()
    )
  end)
end)

describe(".identify", function()
  it("returns terminal when current buffer matches terminal buffer", function()
    local term = terms.Terminal:new()
    term:focus()

    local result = terms.identify()

    assert.equal(result, term)
  end)

  it("returns nil when current buffer doesn't match any terminal buffer", function()
    local term = terms.Terminal:new()
    term:start()
    local other_bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(other_bufnr)

    local result = terms.identify()

    assert.is_nil(result)
  end)
end)

describe(".get_last_focused", function()
  it("returns last focused selectable terminal when universal selection is disabled", function()
    local term1 = terms.Terminal:new({ selectable = false })
    local term2 = terms.Terminal:new()
    term2:focus()
    term1:focus()

    local result = terms.get_last_focused()

    assert.equal(result, term2)
  end)

  it("returns last focused terminal regardless of selectable option when universal selection is enabled", function()
    local term1 = terms.Terminal:new({ selectable = false })
    local term2 = terms.Terminal:new()
    term2:focus()
    term1:focus()
    terms.toggle_universal_selection()

    local result = terms.get_last_focused()

    assert.equal(result, term1)

    terms.toggle_universal_selection()
  end)

  it("returns nil when no terminal has been focused", function()
    assert.is_nil(
      terms.get_last_focused()
    )
  end)
end)

describe(".get_all", function()
  it("returns all terminals", function()
    local term1 = terms.Terminal:new()
    local term2 = terms.Terminal:new()

    local result = terms.get_all()

    assert.equal(2, #result)
    assert.is_true(vim.tbl_contains(result, term1))
    assert.is_true(vim.tbl_contains(result, term2))
  end)

  it("returns empty table when no terminals exist", function()
    local result = terms.get_all()

    assert.equal(0, #result)
  end)
end)


describe(".get", function()
  it("returns terminal with given id", function()
    local term = terms.Terminal:new()

    assert.equal(
      term,
      terms.get(term.id)
    )
  end)

  it("returns nil when terminal does not exist", function()
    assert.is_nil(terms.get(1))
  end)
end)

describe(".get_by_name", function()
  it("returns terminal with given name", function()
    local term = terms.Terminal:new({ name = "test" })

    assert.equal(
      term,
      terms.get_by_name("test")
    )
  end)

  it("returns nil when terminal does not exist", function()
    assert.is_nil(terms.get_by_name("foo"))
  end)
end)

describe(".find", function()
  it("returns terminal matching given predicate", function()
    local term = terms.Terminal:new({ name = "test" })
    terms.Terminal:new({ name = "foo" })

    local result = terms.find(function(t)
      return t.name == "test"
    end)

    assert.equal(result, term)
  end)

  it("returns nil when no terminal matches predicate", function()
    terms.Terminal:new({ name = "foo" })

    local result = terms.find(function(t)
      return t.name == "bar"
    end)

    assert.is_nil(result)
  end)
end)

describe(".filter", function()
  it("returns all terminals matching given predicate", function()
    local term1 = terms.Terminal:new({ name = "test" })
    local term2 = terms.Terminal:new({ name = "test" })
    terms.Terminal:new({ name = "foo" })

    local result = terms.filter(function(t)
      return t.name == "test"
    end)

    assert.equal(2, #result)
    assert.is_true(vim.tbl_contains(result, term1))
    assert.is_true(vim.tbl_contains(result, term2))
  end)

  it("returns empty table when no terminals match predicate", function()
    terms.Terminal:new({ name = "foo" })

    local result = terms.filter(function(t)
      return t.name == "bar"
    end)

    assert.equal(0, #result)
  end)
end)

describe(".select", function()
  it("returns result of calling given picker with started terminal and given prompt and callbacks", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term = terms.Terminal:new():start()
    terms.Terminal:new()
    local callbacks = {}

    local result = terms.select(picker, "prompt", callbacks)

    ---@diagnostic disable: need-check-nil
    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term))
    assert.equal("prompt", result[2])
    assert.equal(callbacks, result[3])
    ---@diagnostic enable: need-check-nil
  end)

  it("includes started terminals with selectable=true from picler", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term = terms.Terminal:new({ selectable = true }):start()
    local callbacks = {}

    local result = terms.select(picker, "prompt", callbacks)

    ---@diagnostic disable: need-check-nil
    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term))
    ---@diagnostic enable: need-check-nil
  end)

  it("excludes non-started terminals with selectable=true from picler", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term1 = terms.Terminal:new({ selectable = true }):start()
    local term2 = terms.Terminal:new({ selectable = true })
    local callbacks = {}

    local result = terms.select(picker, "prompt", callbacks)

    ---@diagnostic disable: need-check-nil
    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term1))
    assert.is_false(vim.tbl_contains(result[1], term2))
    ---@diagnostic enable: need-check-nil
  end)

  it("includes sticky terminals with selectable=true even when not started", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term = terms.Terminal:new({ selectable = true, sticky = true })
    local callbacks = {}

    local result = terms.select(picker, "prompt", callbacks)

    ---@diagnostic disable: need-check-nil
    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term))
    ---@diagnostic enable: need-check-nil
  end)

  it("excludes started terminals with selectable=false from picker", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local visible_term = terms.Terminal:new({ selectable = true }):start()
    local hidden_term = terms.Terminal:new({ selectable = false }):start()
    local callbacks = {}

    local result = terms.select(picker, "prompt", callbacks)

    ---@diagnostic disable: need-check-nil
    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], visible_term))
    assert.is_false(vim.tbl_contains(result[1], hidden_term))
    ---@diagnostic enable: need-check-nil
  end)

  it("excludes sticky terminals with selectable=false from picker", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local started_term = terms.Terminal:new({ selectable = true }):start()
    local sticky_term = terms.Terminal:new({ selectable = false, sticky = true })
    local callbacks = {}

    local result = terms.select(picker, "prompt", callbacks)

    ---@diagnostic disable: need-check-nil
    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], started_term))
    assert.is_false(vim.tbl_contains(result[1], sticky_term))
    ---@diagnostic enable: need-check-nil
  end)

  it("includes terminals with selectable=false when universal selection is enabled", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local visible_term = terms.Terminal:new({ selectable = true }):start()
    local hidden_term = terms.Terminal:new({ selectable = false }):start()
    local callbacks = {}
    terms.toggle_universal_selection()

    local result = terms.select(picker, "prompt", callbacks)

    ---@diagnostic disable: need-check-nil
    assert.equal(2, #result[1])
    assert.is_true(vim.tbl_contains(result[1], visible_term))
    assert.is_true(vim.tbl_contains(result[1], hidden_term))
    ---@diagnostic enable: need-check-nil
  end)

  it("notifies when no terminals are started", function()
    local picker = {
      select = function()
        return nil
      end
    }
    local result = test_helpers.mocking_notify(function()
      terms.select(picker, "prompt", {})
    end)

    ---@diagnostic disable: need-check-nil
    assert.equal("No ergoterms have been started yet", result.msg)
    assert.equal("info", result.level)
    ---@diagnostic enable: need-check-nil
  end)
end)

describe(".cleanup_all", function()
  it("cleans up all terminals", function()
    local term = terms.Terminal:new()

    terms.cleanup_all()

    assert.is_nil(terms.get(term.id))
  end)

  it("stops any running terminals", function()
    local term = terms.Terminal:new():start()

    terms.cleanup_all()

    assert.is_nil(terms.get(term.id))
  end)

  it("does not remove sticky terminals from session unless force is true", function()
    local regular_term = terms.Terminal:new()
    local sticky_term = terms.Terminal:new({ sticky = true })

    terms.cleanup_all()

    assert.is_nil(terms.get(regular_term.id))
    assert.is_not_nil(terms.get(sticky_term.id))
  end)

  it("removes sticky terminals from session when force is true", function()
    local regular_term = terms.Terminal:new()
    local sticky_term = terms.Terminal:new({ sticky = true })

    terms.cleanup_all({ force = true })

    assert.is_nil(terms.get(regular_term.id))
    assert.is_nil(terms.get(sticky_term.id))
  end)

  it("removes terminals from the session", function()
    local term = terms.Terminal:new()
    term:open()

    terms.cleanup_all()

    assert.is_false(term:is_open())
    assert.is_nil(terms.get(term.id))
  end)
end)

describe(".get_state", function()
  it("returns value for a given key from the state", function()
    local term = terms.Terminal:new({ foo = "bar" })

    assert.is_true(vim.tbl_contains(terms.get_state("terminals"), term))
  end)
end)

describe(".toggle_universal_selection", function()
  it("toggles universal selection state", function()
    local initial_state = terms.get_state("universal_selection")

    local result = terms.toggle_universal_selection()

    assert.equal(not initial_state, result)
    assert.equal(result, terms.get_state("universal_selection"))
  end)

  it("returns true when toggled from false", function()
    -- Ensure we start from false
    if terms.get_state("universal_selection") then
      terms.toggle_universal_selection()
    end

    local result = terms.toggle_universal_selection()

    assert.is_true(result)
  end)

  it("returns false when toggled from true", function()
    -- Ensure we start from true
    if not terms.get_state("universal_selection") then
      terms.toggle_universal_selection()
    end

    local result = terms.toggle_universal_selection()

    assert.is_false(result)
  end)
end)

describe(".reset_ids", function()
  it("resets sequence of terminal ids", function()
    local term1 = terms.Terminal:new()
    term1:cleanup()

    terms.reset_ids()
    local term2 = terms.Terminal:new()

    assert.equal(1, term2.id)
  end)
end)

describe(":new", function()
  it("takes auto_scroll option", function()
    local term = terms.Terminal:new({ auto_scroll = false })

    assert.is_false(term.auto_scroll)
  end)

  it("defaults to config's auto_scroll", function()
    local term = terms.Terminal:new()

    assert.is_false(term.auto_scroll)
  end)

  it("takes cmd option", function()
    local term = terms.Terminal:new({ cmd = "echo hello" })

    assert.equal("echo hello", term.cmd)
  end)

  it("defaults to config's shell if cmd is not provided", function()
    local term = terms.Terminal:new()

    assert.equal(vim.o.shell, term.cmd)
  end)

  it("takes clear_env option", function()
    local term = terms.Terminal:new({ clear_env = true })

    assert.is_true(term.clear_env)
  end)

  it("defaults to config's clear_env", function()
    local term = terms.Terminal:new()

    assert.is_false(term.clear_env)
  end)

  it("takes cleanup_on_success option", function()
    local term = terms.Terminal:new({ cleanup_on_success = false })

    assert.is_false(term.cleanup_on_success)
  end)

  it("defaults to config's cleanup_on_success", function()
    local term = terms.Terminal:new()

    assert.is_true(term.cleanup_on_success)
  end)

  it("takes cleanup_on_failure option", function()
    local term = terms.Terminal:new({ cleanup_on_failure = false })

    assert.is_false(term.cleanup_on_failure)
  end)

  it("defaults to config's cleanup_on_failure", function()
    local term = terms.Terminal:new()

    assert.is_true(term.cleanup_on_failure)
  end)

  it("takes layout option", function()
    local term = terms.Terminal:new({ layout = "right" })

    assert.equal("right", term.layout)
  end)

  it("defaults to config's layout", function()
    local term = terms.Terminal:new()

    assert.equal("below", term.layout)
  end)

  it("takes env option", function()
    local term = terms.Terminal:new({ env = { FOO = "bar" } })

    assert.equal("bar", term.env.FOO)
  end)

  it("takes name option", function()
    local term = terms.Terminal:new({ name = "test" })

    assert.equal("test", term.name)
  end)

  it("defaults name to cmd option", function()
    local term = terms.Terminal:new({ cmd = "echo hello" })

    assert.equal("echo hello", term.name)
  end)

  it("takes float_opts option", function()
    local term = terms.Terminal:new({ float_opts = { width = 100, height = 50 } })

    assert.equal(100, term.float_opts.width)
    assert.equal(50, term.float_opts.height)
  end)

  it("defaults to config's float_opts for non-given options", function()
    local term = terms.Terminal:new({ float_opts = { width = 100, height = 20 } })

    assert.equal("single", term.float_opts.border)
  end)

  it("takes float_winblend option", function()
    local term = terms.Terminal:new({ float_winblend = 20 })

    assert.equal(20, term.float_winblend)
  end)

  it("defaults to config's float_winblend", function()
    local term = terms.Terminal:new()

    assert.equal(10, term.float_winblend)
  end)

  it("takes persist_mode option", function()
    local term = terms.Terminal:new({ persist_mode = true })

    assert.is_true(term.persist_mode)
  end)

  it("defaults to config's persist_mode", function()
    local term = terms.Terminal:new()

    assert.is_false(term.persist_mode)
  end)

  it("takes start_in_insert option", function()
    local term = terms.Terminal:new({ start_in_insert = false })

    assert.is_false(term.start_in_insert)
  end)

  it("defaults to config's start_in_insert", function()
    local term = terms.Terminal:new()

    assert.is_true(term.start_in_insert)
  end)

  it("takes selectable option", function()
    local term = terms.Terminal:new({ selectable = false })

    assert.is_false(term.selectable)
  end)

  it("defaults to config's selectable", function()
    local term = terms.Terminal:new()

    assert.is_true(term.selectable)
  end)

  it("takes sticky option", function()
    local term = terms.Terminal:new({ sticky = true })

    assert.is_true(term.sticky)
  end)

  it("defaults to config's sticky", function()
    local term = terms.Terminal:new()

    assert.is_false(term.sticky)
  end)

  it("takes size option", function()
    local term = terms.Terminal:new({ size = { below = 20, right = "30%" } })

    assert.equal(20, term.size.below)
    assert.equal("30%", term.size.right)
  end)

  it("defaults to config's size", function()
    local term = terms.Terminal:new()

    assert.equal("50%", term.size.below)
    assert.equal("50%", term.size.above)
    assert.equal("50%", term.size.left)
    assert.equal("50%", term.size.right)
  end)

  it("merges size with defaults for non-given options", function()
    local term = terms.Terminal:new({ size = { below = 20 } })

    assert.equal(20, term.size.below)
    assert.equal("50%", term.size.above)
    assert.equal("50%", term.size.left)
    assert.equal("50%", term.size.right)
  end)

  it("takes on_close option", function()
    local foo = nil

    local term = terms.Terminal:new({ on_close = function() foo = "foo" end })
    term:on_close()

    assert.equal("foo", foo)
  end)

  it("defaults to config's on_close", function()
    local term = terms.Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_close)
  end)

  it("takes on_create option", function()
    local foo = nil

    local term = terms.Terminal:new({ on_create = function() foo = "foo" end })
    term:on_create()

    assert.equal("foo", foo)
  end)

  it("defaults to config's on_create", function()
    local term = terms.Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_create)
  end)

  it("takes on_focus option", function()
    local foo = nil

    local term = terms.Terminal:new({ on_focus = function() foo = "foo" end })
    term:on_focus()

    assert.equal("foo", foo)
  end)

  it("defaults to config's on_focus", function()
    local term = terms.Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_focus)
  end)

  it("takes on_job_exit option", function()
    local foo = nil

    local term = terms.Terminal:new({ on_job_exit = function() foo = "foo" end })
    term:on_job_exit(1, 2, "event")

    assert.equal("foo", foo)
  end)

  it("defaults to config's on_job_exit", function()
    local term = terms.Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_job_exit)
  end)

  it("takes on_job_stdout option", function()
    local foo = nil

    local term = terms.Terminal:new({ on_job_stdout = function() foo = "foo" end })
    term:on_job_stdout(1, { "data" }, "name")

    assert.equal("foo", foo)
  end)

  it("defaults to config's on_job_stdout", function()
    local term = terms.Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_job_stdout)
  end)

  it("takes on_job_stderr option", function()
    local foo = nil

    local term = terms.Terminal:new({ on_job_stderr = function() foo = "foo" end })
    term:on_job_stderr(1, { "data" }, "name")

    assert.equal("foo", foo)
  end)

  it("defaults to config's on_job_stderr", function()
    local term = terms.Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_job_stderr)
  end)

  it("takes on_open option", function()
    local foo = nil

    local term = terms.Terminal:new({ on_open = function() foo = "foo" end })
    term:on_open()

    assert.equal("foo", foo)
  end)

  it("defaults to config's on_open", function()
    local term = terms.Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_open)
  end)

  it("takes on_start option", function()
    local foo = nil

    local term = terms.Terminal:new({ on_start = function() foo = "foo" end })
    term:on_start()

    assert.equal("foo", foo)
  end)

  it("defaults to config's on_start", function()
    local term = terms.Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_start)
  end)

  it("takes on_stop option", function()
    local foo = nil

    local term = terms.Terminal:new({ on_stop = function() foo = "foo" end })
    term:on_stop()

    assert.equal("foo", foo)
  end)

  it("defaults to config's on_stop", function()
    local term = terms.Terminal:new()

    assert.equal(config.NULL_CALLBACK, term.on_stop)
  end)

  it("builds sequential ids", function()
    local term1 = terms.Terminal:new()
    local term2 = terms.Terminal:new()

    assert.equal(1, term1.id)
    assert.equal(2, term2.id)
  end)

  it("doesn't build cleaned up terminal ids", function()
    local term1 = terms.Terminal:new()
    term1:cleanup()
    local term2 = terms.Terminal:new()

    assert.equal(2, term2.id)
  end)

  it("initializes directory as the current git directory if dir is given as 'git_dir'", function()
    local term = terms.Terminal:new({ dir = "git_dir" })

    local expected_dir = vim.fn.getcwd()

    assert.equal(expected_dir, term:get_state("dir"))
  end)

  it("initializes directory as the current working directory if dir is nil", function()
    local term = terms.Terminal:new({ dir = nil })

    local expected_dir = vim.fn.getcwd()

    assert.equal(expected_dir, term:get_state("dir"))
  end)

  it("initializes directory as the given directory if dir is a string", function()
    local term = terms.Terminal:new({ dir = "/tmp" })

    assert.equal("/tmp", term:get_state("dir"))
  end)

  it("errors if dir is not a valid directory", function()
    local result = test_helpers.mocking_notify(function()
      terms.Terminal:new({ dir = "/invalid" })
    end)

    ---@diagnostic disable: need-check-nil
    assert.equal("/invalid is not a directory", result.msg)
    assert.equal("error", result.level)
    ---@diagnostic enable: need-check-nil
  end)

  it("initializes layout from given layout", function()
    local term = terms.Terminal:new({ layout = "right" })

    assert.equal("right", term:get_state("layout"))
  end)

  it("doesn't override float_opts defaults for non-given options", function()
    local term = terms.Terminal:new({ float_opts = { width = 100, height = 20 } })

    assert.equal("single", term.float_opts.border)
  end)

  it("initializes float_opts title from name when not given", function()
    local term = terms.Terminal:new({ name = "test" })

    assert.equal("test", term:get_state("float_opts").title)
  end)

  it("doesn't override float_opts title when given", function()
    local term = terms.Terminal:new({ float_opts = { title = "foo" } })

    assert.equal("foo", term:get_state("float_opts").title)
  end)

  it("initializes float_opts row from height when not given", function()
    local term = terms.Terminal:new({ float_opts = { height = 20 } })

    assert.equal(math.ceil((vim.o.lines - 20)) * 0.5 - 1, term:get_state("float_opts").row)
  end)

  it("doesn't override float_opts row when given", function()
    local term = terms.Terminal:new({ float_opts = { row = 10 } })

    assert.equal(10, term:get_state("float_opts").row)
  end)

  it("initializes float_opts col from width when not given", function()
    local term = terms.Terminal:new({ float_opts = { width = 100 } })

    assert.equal(math.ceil((vim.o.columns - 100)) * 0.5 - 1, term:get_state("float_opts").col)
  end)

  it("doesn't override float_opts col when given", function()
    local term = terms.Terminal:new({ float_opts = { col = 10 } })

    assert.equal(10, term:get_state("float_opts").col)
  end)

  it("initializes size with numeric values", function()
    local term = terms.Terminal:new({ size = { below = 20, right = 30 } })

    assert.equal(20, term:get_state("size").below)
    assert.equal(30, term:get_state("size").right)
  end)

  it("initializes size with percentage values for vertical layouts", function()
    local original_lines = vim.o.lines
    vim.o.lines = 40

    local term = terms.Terminal:new({ size = { below = "25%", above = "75%" } })

    assert.equal(10, term:get_state("size").below)
    assert.equal(30, term:get_state("size").above)

    vim.o.lines = original_lines
  end)

  it("initializes size with percentage values for horizontal layouts", function()
    local original_columns = vim.o.columns
    vim.o.columns = 80

    local term = terms.Terminal:new({ size = { left = "25%", right = "75%" } })

    assert.equal(20, term:get_state("size").left)
    assert.equal(60, term:get_state("size").right)

    vim.o.columns = original_columns
  end)

  it("initializes on_job_exit so it calls provided on_job_exit", function()
    local foo = nil
    local term = terms.Terminal:new({ on_job_exit = function() foo = "foo" end })

    term:get_state("on_job_exit")(1, 2, "event")
    assert.equal("foo", foo)
  end)

  it("initializes on_job_stdout so it calls provided on_job_stdout", function()
    local foo = nil
    local term = terms.Terminal:new({ on_job_stdout = function() foo = "foo" end })

    term:get_state("on_job_stdout")(1, { "data" }, "name")
    assert.equal("foo", foo)
  end)

  it("initializes on_job_stderr so it calls provided on_job_stderr", function()
    local foo = nil
    local term = terms.Terminal:new({ on_job_stderr = function() foo = "foo" end })

    term:get_state("on_job_stderr")(1, { "data" }, "name")
    assert.equal("foo", foo)
  end)

  it("adds terminal to the list of terminals in the state", function()
    local term = terms.Terminal:new()

    assert.is_true(vim.tbl_contains(terms.get_state("terminals"), term))
  end)
end)

describe(":update", function()
  it("updates passed properties", function()
    local term = terms.Terminal:new({ name = "foo", layout = "below" })
    term:update({ name = "bar", layout = "right" })

    assert.equal("bar", term.name)
    assert.equal("right", term.layout)
  end)

  it("recomputes mode", function()
    local term = terms.Terminal:new({ start_in_insert = false })
    term:update({ start_in_insert = true })

    assert.equal("i", term:get_state("mode"))
  end)

  it("recomputes layout", function()
    local term = terms.Terminal:new({ layout = "below" })
    term:update({ layout = "right" })

    assert.equal("right", term:get_state("layout"))
  end)

  it("doesn't override float_opts that are not-given options", function()
    local term = terms.Terminal:new({ float_opts = { width = 100, height = 1 } })
    term:update({ float_opts = { width = 200 } })

    assert.equal(1, term:get_state("float_opts").height)
  end)

  it("doesn't override size that are not-given options", function()
    local term = terms.Terminal:new({ size = { below = 20, right = "30%" } })

    term:update({ size = { below = 25 } })

    assert.equal(25, term.size.below)
    assert.equal("30%", term.size.right)
  end)

  it("recomputes on_job_exit", function()
    local foo = nil
    local term = terms.Terminal:new({ on_job_exit = function() foo = "foo" end })
    term:update({ on_job_exit = function() foo = "bar" end })

    term:get_state("on_job_exit")(1, 2, "event")
    assert.equal("bar", foo)
  end)

  it("recomputes on_job_stdout", function()
    local foo = nil
    local term = terms.Terminal:new({ on_job_stdout = function() foo = "foo" end })
    term:update({ on_job_stdout = function() foo = "bar" end })

    term:get_state("on_job_stdout")(1, { "data" }, "name")
    assert.equal("bar", foo)
  end)

  it("recomputes on_job_stderr", function()
    local foo = nil
    local term = terms.Terminal:new({ on_job_stderr = function() foo = "foo" end })
    term:update({ on_job_stderr = function() foo = "bar" end })

    term:get_state("on_job_stderr")(1, { "data" }, "name")
    assert.equal("bar", foo)
  end)

  it("doesn't allow updating cmd", function()
    local term = terms.Terminal:new({ cmd = "echo hello" })

    local result = test_helpers.mocking_notify(function()
      term:update({ cmd = "echo world" })
    end)

    ---@diagnostic disable: need-check-nil
    assert.equal("Cannot change cmd after terminal creation", result.msg)
    assert.equal("error", result.level)
    ---@diagnostic enable: need-check-nil
  end)

  it("doesn't allow updating dir", function()
    local term = terms.Terminal:new({ dir = "/tmp" })

    local result = test_helpers.mocking_notify(function()
      term:update({ dir = "/home" })
    end)

    ---@diagnostic disable: need-check-nil
    assert.equal("Cannot change dir after terminal creation", result.msg)
    assert.equal("error", result.level)
    ---@diagnostic enable: need-check-nil
  end)

  it("updates sticky option", function()
    local term = terms.Terminal:new({ sticky = false })
    term:update({ sticky = true })

    assert.is_true(term.sticky)
  end)
end)

describe(":start", function()
  it("creates a new buffer", function()
    local term = terms.Terminal:new()

    term:start()

    local bufnr = term:get_state("bufnr")
    assert.is_not_nil(bufnr)
    assert.is_true(vim.api.nvim_buf_is_valid(bufnr))
  end)

  it("opens term with the given command", function()
    local term = terms.Terminal:new({ cmd = "echo hello" })
    local spy_termopen = spy.on(vim.fn, "termopen")

    term:start()

    assert.spy(spy_termopen).was_called_with("echo hello", match.is_table())
  end)

  it("updates the state with the new job_id", function()
    local term = terms.Terminal:new()

    term:start()

    local job_id = term:get_state("job_id")
    assert.is_number(job_id)
  end)

  it("runs the on_create callback", function()
    local called = false
    local term = terms.Terminal:new({
      on_create = function() called = true end,
    })

    term:start()

    assert.is_true(called)
  end)

  it("does nothing if already started", function()
    local term = terms.Terminal:new()
    term:start()
    local initial_bufnr = term:get_state("bufnr")
    local initial_job_id = term:get_state("job_id")

    term:start()

    assert.equal(initial_bufnr, term:get_state("bufnr"))
    assert.equal(initial_job_id, term:get_state("job_id"))
  end)


  it("recomputes dir on start", function()
    local original_termopen = vim.fn.termopen
    local original_cwd = vim.loop.cwd
    vim.fn.termopen = function(_, _) return 1 end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.loop.cwd = function() return "/initial/dir" end

    local term = terms.Terminal:new({})

    ---@diagnostic disable-next-line: duplicate-set-field
    vim.loop.cwd = function() return "/changed/dir" end

    term:start()

    assert.equal("/changed/dir", term:get_state("dir"))

    vim.fn.termopen = original_termopen
    vim.loop.cwd = original_cwd
  end)
end)

describe(":is_started", function()
  it("returns true if terminal is started", function()
    local term = terms.Terminal:new():start()

    assert.is_true(term:is_started())
  end)

  it("returns false if terminal is not started", function()
    local term = terms.Terminal:new()

    assert.is_false(term:is_started())
  end)

  it("returns false if terminal job is stopped", function()
    local term = terms.Terminal:new():start()
    term:stop()
    vim.wait(100)

    assert.is_false(term:is_started())
  end)
end)

describe(":is_active", function()
  it("returns true if terminal has active buffer", function()
    local term = terms.Terminal:new():start()

    assert.is_true(term:is_active())
  end)

  it("returns false if terminal has no buffer", function()
    local term = terms.Terminal:new()

    assert.is_false(term:is_active())
  end)

  it("returns false if terminal is stopped", function()
    local term = terms.Terminal:new():start()
    term:stop()
    vim.wait(100)

    assert.is_false(term:is_active())
  end)

  it("returns false if terminal buffer is deleted", function()
    local term = terms.Terminal:new():start()
    local bufnr = term:get_state("bufnr")

    vim.api.nvim_buf_delete(bufnr, { force = true })

    assert.is_false(term:is_active())
  end)
end)

describe(":open", function()
  it("starts the terminal if it is not yet started", function()
    local term = terms.Terminal:new()

    term:open()

    assert.is_true(term:is_started())
  end)

  it("opens the terminal above if layout is above", function()
    local term = terms.Terminal:new()

    term:open("above")

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("above", win_config.split)
  end)

  it("opens the terminal at below if layout is below", function()
    local term = terms.Terminal:new()

    term:open("below")

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("below", win_config.split)
  end)

  it("opens the terminal at the left if layout is left", function()
    local term = terms.Terminal:new()

    term:open("left")

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("left", win_config.split)
  end)

  it("opens the terminal at the right if layout is right", function()
    local term = terms.Terminal:new()

    term:open("right")

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("right", win_config.split)
  end)

  it("opens the terminal in another tab if layout is tab", function()
    local term = terms.Terminal:new()
    local current_tabpage = vim.api.nvim_get_current_tabpage()

    term:open("tab")

    local tabpage = term:get_state("tabpage")
    assert.is_true(vim.api.nvim_tabpage_is_valid(tabpage))
    assert.not_equal(current_tabpage, tabpage)
  end)

  it("opens the terminal in a float window if layout is float", function()
    local term = terms.Terminal:new()

    term:open("float")

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.is_true(win_config.relative == "editor" or win_config.relative == "win")
  end)

  it("uses the stored layout if not provided", function()
    local term = terms.Terminal:new({ layout = "below" })

    term:open()

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("below", win_config.split)
  end)

  it("stores the layout in the state", function()
    local term = terms.Terminal:new()

    term:open("right")

    assert.equal("right", term:get_state("layout"))
  end)

  it("stores the window in the state", function()
    local term = terms.Terminal:new()

    term:open()

    assert.is_not_nil(term:get_state("window"))
  end)

  it("stores the tab in the state", function()
    local term = terms.Terminal:new()

    term:open()

    assert.is_not_nil(term:get_state("tabpage"))
  end)

  it("runs the on_open callback", function()
    local called = false
    local term = terms.Terminal:new({
      on_open = function() called = true end,
    })

    term:open()

    assert.is_true(called)
  end)

  it("sets the buffer filetype as ErgoTerm", function()
    local term = terms.Terminal:new()

    term:open()

    assert.equal("ErgoTerm", vim.bo[term:get_state("bufnr")].filetype)
  end)

  it("sets the buffer as not listed", function()
    local term = terms.Terminal:new()

    term:open()

    assert.is_false(vim.bo[term:get_state("bufnr")].buflisted)
  end)

  it("sets the window as no number", function()
    local term = terms.Terminal:new()

    term:open()

    assert.is_false(vim.wo[term:get_state("window")].number)
  end)

  it("sets the window as no sign column", function()
    local term = terms.Terminal:new()

    term:open()

    assert.equal("no", vim.wo[term:get_state("window")].signcolumn)
  end)

  it("sets the window as no relative number", function()
    local term = terms.Terminal:new()

    term:open()

    assert.is_false(vim.wo[term:get_state("window")].relativenumber)
  end)

  it("sets the window as no side scroll if layout is float", function()
    local term = terms.Terminal:new()

    term:open("float")

    assert.equal(0, vim.wo[term:get_state("window")].sidescrolloff)
  end)

  it("sets the window with float_windblend given in initialization if layout is float", function()
    local term = terms.Terminal:new({ float_winblend = 20 })

    term:open("float")

    assert.equal(20, vim.wo[term:get_state("window")].winblend)
  end)

  it("keeps focus on the original window", function()
    local term = terms.Terminal:new()
    local original_window = vim.api.nvim_get_current_win()

    term:open()

    assert.equal(original_window, vim.api.nvim_get_current_win())
  end)

  it("does nothing if the terminal is already open", function()
    local term = terms.Terminal:new()

    term:open()
    local initial_window = term:get_state("window")

    term:open()

    assert.equal(initial_window, term:get_state("window"))
  end)
end)

describe(":is_open", function()
  it("returns false if terminal is not open", function()
    local term = terms.Terminal:new()

    assert.is_false(term:is_open())
  end)

  it("returns true if terminal is open", function()
    local term = terms.Terminal:new()
    term:open()

    assert.is_true(term:is_open())
  end)

  it("returns false if terminal is open in another tab", function()
    local term = terms.Terminal:new()
    term:open("tab")

    assert.is_true(term:is_open())
  end)
end)

describe(":close", function()
  it("closes the terminal window if open", function()
    local term = terms.Terminal:new()
    term:open()
    local win_id = term:get_state("window")

    term:close()

    assert.is_false(vim.api.nvim_win_is_valid(win_id))
    assert.is_false(term:is_open())
  end)

  it("runs the on_close() callback", function()
    local called = false
    local term = terms.Terminal:new({
      on_close = function() called = true end,
    })
    term:open()

    term:close()

    assert.is_true(called)
  end)

  it("does nothing if the terminal is not open", function()
    local term = terms.Terminal:new()

    term:close()

    assert.is_false(term:is_open())
  end)
end)

describe(":focus", function()
  it("starts the terminal if it is not already started", function()
    local term = terms.Terminal:new()

    term:focus()

    assert.is_true(term:is_started())
  end)

  it("opens the terminal if it is not already open", function()
    local term = terms.Terminal:new()

    term:focus()

    assert.is_true(term:is_open())
  end)

  it("forwards given layout when opening the terminal", function()
    local term = terms.Terminal:new()

    term:focus("right")

    assert.equal("right", term:get_state("layout"))
  end)

  it("sets the terminal window as the current window", function()
    local term = terms.Terminal:new()
    term:open()

    term:focus()

    assert.equal(term:get_state("window"), vim.api.nvim_get_current_win())
  end)

  it("sets the terminal tab as the current tab", function()
    local term = terms.Terminal:new()
    term:open("tab")

    term:focus()

    assert.equal(term:get_state("tabpage"), vim.api.nvim_get_current_tabpage())
  end)

  it("sets the terminal as the last focused", function()
    local term = terms.Terminal:new()

    term:focus()

    assert.equal(term, terms.get_last_focused())
  end)

  it("runs the on_focus callback", function()
    local called = false
    local term = terms.Terminal:new({
      on_focus = function() called = true end,
    })

    term:focus()

    assert.is_true(called)
  end)

  it("does nothing if already focused", function()
    local term = terms.Terminal:new()
    term:focus()
    local initial_window = vim.api.nvim_get_current_win()
    local initial_tabpage = vim.api.nvim_get_current_tabpage()

    term:focus()

    assert.equal(initial_window, vim.api.nvim_get_current_win())
    assert.equal(initial_tabpage, vim.api.nvim_get_current_tabpage())
  end)
end)

describe(":is_focused", function()
  it("returns true if the terminal is focused", function()
    local term = terms.Terminal:new()

    term:focus()

    assert.is_true(term:is_focused())
  end)

  it("returns false if the terminal is not focused", function()
    local term1 = terms.Terminal:new()
    local term2 = terms.Terminal:new()

    term1:focus()

    assert.is_false(term2:is_focused())
  end)
end)

describe(":stop", function()
  it("closes the terminal if open by default", function()
    local term = terms.Terminal:new()
    term:open()

    term:stop()

    assert.is_false(term:is_open())
  end)

  it("closes the terminal if open when close is true", function()
    local term = terms.Terminal:new()
    term:open()

    term:stop(true)

    assert.is_false(term:is_open())
  end)

  it("closes the terminal window when stopping", function()
    local term = terms.Terminal:new()
    term:open()

    local spy_termclose = spy.on(term, "close")
    term:stop()

    assert.spy(spy_termclose).was_called()
  end)

  it("runs the on_stop callback", function()
    local called = false
    local term = terms.Terminal:new({
      on_stop = function() called = true end,
    })
    term:start()

    term:stop()

    assert.is_true(called)
  end)

  it("stops the running process", function()
    local term = terms.Terminal:new()
    term:start()
    local job_id = term:get_state("job_id")
    local spy_jobstop = spy.on(vim.fn, "jobstop")

    term:stop()

    assert.spy(spy_jobstop).was_called_with(job_id)
  end)

  it("resets the job id in the state", function()
    local term = terms.Terminal:new()
    term:start()

    term:stop()
    vim.wait(100)

    assert.is_nil(term:get_state("job_id"))
  end)

  it("preserves the buffer id in the state", function()
    local term = terms.Terminal:new()
    term:start()
    local bufnr = term:get_state("bufnr")

    term:stop()

    assert.equal(bufnr, term:get_state("bufnr"))
  end)
end)

describe(":is_stopped", function()
  it("returns true if the terminal job is stopped", function()
    local term = terms.Terminal:new()
    term:start()
    term:stop()
    vim.wait(100)

    assert.is_true(term:is_stopped())
  end)

  it("returns false if the terminal job is running", function()
    local term = terms.Terminal:new()
    term:start()

    assert.is_false(term:is_stopped())
  end)
end)

describe(":cleanup", function()
  it("stops the terminal if started", function()
    local term = terms.Terminal:new()
    term:start()

    term:cleanup()
    vim.wait(100)

    assert.is_true(term:is_stopped())
  end)

  it("removes the terminal from the state", function()
    local term = terms.Terminal:new()

    term:cleanup()

    assert.is_nil(terms.get(term.id))
  end)

  it("does not remove sticky terminals from state unless force is true", function()
    local term = terms.Terminal:new({ sticky = true })

    term:cleanup()

    assert.is_not_nil(terms.get(term.id))
  end)

  it("removes sticky terminals from state when force is true", function()
    local term = terms.Terminal:new({ sticky = true })

    term:cleanup({ force = true })

    assert.is_nil(terms.get(term.id))
  end)

  it("removes the terminal from session when cleaning up", function()
    local term = terms.Terminal:new()
    term:open()

    term:cleanup()

    assert.is_false(term:is_open())
    assert.is_nil(terms.get(term.id))
  end)

  it("removes the terminal from the last focused cache if it was focused", function()
    local term = terms.Terminal:new()
    term:focus()

    term:cleanup()

    assert.is_nil(terms.get_last_focused())
  end)

  it("resets the buffer id in the state", function()
    local term = terms.Terminal:new()
    term:start()

    term:cleanup()

    assert.is_nil(term:get_state("bufnr"))
  end)
end)

describe(":toggle", function()
  it("closes the terminal if open", function()
    local term = terms.Terminal:new()
    term:open()

    term:toggle()

    assert.is_false(term:is_open())
  end)

  it("focuses the terminal if closed", function()
    local term = terms.Terminal:new()
    term:open()
    term:close()

    term:toggle()

    assert.is_true(term:is_focused())
  end)

  it("uses layout in the state if set", function()
    local term = terms.Terminal:new({ layout = "right" })
    term:open()
    term:close()

    term:toggle()

    assert.equal("right", term:get_state("layout"))
  end)

  it("uses given layout if given", function()
    local term = terms.Terminal:new({ layout = "below" })
    term:open()
    term:close()

    term:toggle("left")

    assert.equal("left", term:get_state("layout"))
    assert.is_true(term:is_focused())
  end)
end)

describe(":send", function()
  it("sends input to the terminal process", function()
    local term = terms.Terminal:new({ cmd = "cat" }):start()

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

    local term = terms.Terminal:new({ cmd = "cat" }):start()
    term:send("single_line")
    vim.wait(100)

    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)
    assert.is_true(vim.tbl_contains(lines, "selected text"))

    text_selector.select = original_select
  end)

  it("adds a newline by default", function()
    local term = terms.Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:send({ "foo" })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo", "" }
    )
  end)

  it("does not add a newline if new_line is false", function()
    local term = terms.Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:send({ "foo" }, { new_line = false })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo" }
    )
  end)

  it("trims input by default", function()
    local term = terms.Terminal:new({ cmd = "cat" }):start()
    term:send({ "  baz  " })

    vim.wait(100)
    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)

    assert.is_true(vim.tbl_contains(lines, "baz"))
    assert.is_false(vim.tbl_contains(lines, "  baz  "))
  end)

  it("does not trim input if trim is false", function()
    local term = terms.Terminal:new({ cmd = "cat" }):start()
    term:send({ "  qux  " }, { trim = false })

    vim.wait(100)
    local lines = vim.api.nvim_buf_get_lines(term:get_state("bufnr"), 0, -1, false)

    assert.is_true(vim.tbl_contains(lines, "  qux  "))
  end)

  it("applies decorator function to input", function()
    local term = terms.Terminal:new():start()
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
    local term = terms.Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:send({ "foo" }, { decorator = "identity" })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo", "" }
    )
  end)

  it("falls back to identity decorator for unknown string decorator", function()
    local term = terms.Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:send({ "foo" }, { decorator = "unknown_decorator" })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo", "" }
    )
  end)

  it("uses identity function as default decorator", function()
    local term = terms.Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:send({ "foo" })
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(
      term:get_state("job_id"),
      { "foo", "" }
    )
  end)

  it("opens the terminal if not open and action is not silent", function()
    local term = terms.Terminal:new({ cmd = "cat" }):start()
    term:close()

    term:send({ "foo" }, { action = "visible" })
    vim.wait(100)

    assert.is_true(term:is_open())
  end)

  it("does not open the terminal if action is silent", function()
    local term = terms.Terminal:new({ cmd = "cat" }):start()
    term:close()

    term:send({ "foo" }, { action = "silent" })
    vim.wait(100)

    assert.is_false(term:is_open())
  end)

  it("focuses the terminal if action is interactive", function()
    local term = terms.Terminal:new({ cmd = "cat" }):start()
    term:close()

    term:send({ "foo" }, { action = "interactive" })
    vim.wait(100)

    assert.is_true(term:is_focused())
  end)

  it("restores focus to original window if action is visible", function()
    local term = terms.Terminal:new({ cmd = "cat" }):start()
    local original_win = vim.api.nvim_get_current_win()

    term:send({ "foo" }, { action = "visible" })
    vim.wait(100)

    assert.equal(original_win, vim.api.nvim_get_current_win())
  end)

  it("scrolls to the bottom after sending", function()
    local term = terms.Terminal:new({ cmd = "cat" }):start()
    term:open()
    vim.api.nvim_win_set_cursor(term:get_state("window"), { 1, 0 })

    term:send({ "foo" })
    vim.wait(100)

    local cursor = vim.api.nvim_win_get_cursor(term:get_state("window"))
    local lines = vim.api.nvim_buf_line_count(term:get_state("bufnr"))
    assert.equal(lines, cursor[1])
  end)

  it("notifies error for invalid string input type", function()
    local term = terms.Terminal:new():start()

    local result = test_helpers.mocking_notify(function()
      ---@diagnostic disable-next-line: param-type-mismatch
      term:send("invalid_type")
    end)

    ---@diagnostic disable: need-check-nil
    assert.equal(
      "Invalid input type 'invalid_type'. Must be a table with one item per line or one of: single_line, visual_lines, visual_selection",
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
    local term = terms.Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:clear()
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(term:get_state("job_id"), { "clear", "" })
  end)

  it("sends 'cls' to the terminal on Windows", function()
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_windows = function() return true end
    local term = terms.Terminal:new():start()
    local spy_chansend = spy.on(vim.fn, "chansend")

    term:clear()
    vim.wait(100)

    assert.spy(spy_chansend).was_called_with(term:get_state("job_id"), { "cls", "" })
  end)
end)

describe(":on_buf_enter", function()
  it("restores last mode if persist_mode is true", function()
    local term = terms.Terminal:new({ persist_mode = true, start_in_insert = false }):start()
    local spy_mode_set = spy.on(mode, "set")

    term:on_buf_enter()

    assert.spy(spy_mode_set).was_called_with("n")
  end)

  it("starts in insert mode if persist_mode is false and start_in_insert is true", function()
    local term = terms.Terminal:new({ persist_mode = false, start_in_insert = true }):start()
    local spy_mode_set_initial = spy.on(mode, "set_initial")

    term:on_buf_enter()

    assert.spy(spy_mode_set_initial).was_called_with(true)
  end)

  it("starts in normal mode if persist_mode is false and start_in_insert is false", function()
    local term = terms.Terminal:new({ persist_mode = false, start_in_insert = false }):start()
    local spy_mode_set_initial = spy.on(mode, "set_initial")

    term:on_buf_enter()

    assert.spy(spy_mode_set_initial).was_called_with(false)
  end)

  it("sets the terminal as last focused", function()
    local term = terms.Terminal:new():start()

    term:on_buf_enter()

    assert.equal(term, terms.get_last_focused())
  end)
end)

describe(":on_win_leave", function()
  it("persists mode if persist_mode is true", function()
    local term = terms.Terminal:new({ persist_mode = true, start_in_insert = true }):start()
    local original_mode_get = mode.get
    ---@diagnostic disable-next-line: duplicate-set-field
    mode.get = function() return "n" end

    term:on_win_leave()

    assert.equal("n", term:get_state("mode"))

    mode.get = original_mode_get
  end)

  it("does not persist mode if persist_mode is false", function()
    local term = terms.Terminal:new({ persist_mode = false, start_in_insert = true }):start()
    local original_mode_get = mode.get
    ---@diagnostic disable-next-line: duplicate-set-field
    mode.get = function() return "n" end

    term:on_win_leave()

    assert.equal("i", term:get_state("mode"))

    mode.get = original_mode_get
  end)


  it("closes terminal if layout is float", function()
    local term = terms.Terminal:new({ layout = "float" }):open()

    term:on_win_leave()

    assert.is_false(term:is_open())
  end)

  it("does not close terminal if layout is not float", function()
    local term = terms.Terminal:new({ layout = "below" }):open()

    term:on_win_leave()

    assert.is_true(term:is_open())
  end)
end)


describe(":on_vim_resized", function()
  it("updates state with new computed float options", function()
    local original_lines = vim.o.lines
    vim.o.lines = 40
    local term = terms.Terminal:new({ layout = "float" }):open()
    local float_opts_height = term:get_state("float_opts").height

    vim.o.lines = 150

    term:on_vim_resized()

    local new_float_opts_height = term:get_state("float_opts").height
    assert.not_equal(float_opts_height, new_float_opts_height)

    vim.o.lines = original_lines
  end)

  it("applies new computed float options to the window", function()
    local term = terms.Terminal:new({ layout = "float", float_opts = { width = 60, height = 30 } })
    term:open("float")
    local spy_win_set_config = spy.on(vim.api, "nvim_win_set_config")

    term:on_vim_resized()

    assert.spy(spy_win_set_config).was_called_with(term:get_state("window"), match.is_table())
  end)

  it("does nothing if layout is not float", function()
    local term = terms.Terminal:new({ layout = "below" })
    term:open("below")
    local spy_win_set_config = spy.on(vim.api, "nvim_win_set_config")

    term:on_vim_resized()

    assert.spy(spy_win_set_config).was_not_called()
  end)
end)

describe(":_setup_buffer_autocommands", function()
  it("adds a VimResized autocommand", function()
    local term = terms.Terminal:new()

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
    local term = terms.Terminal:new()

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
end)

describe("cleanup on job exit", function()
  it("cleans up on successful exit when cleanup_on_success is true", function()
    local term = terms.Terminal:new({ cleanup_on_success = true, cleanup_on_failure = false })
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    exit_handler(1, 0, "exit")

    assert.is_nil(terms.get(term.id))
    vim.schedule = original_schedule
  end)

  it("does not clean up on successful exit when cleanup_on_success is false", function()
    local term = terms.Terminal:new({ cleanup_on_success = false, cleanup_on_failure = true })
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    exit_handler(1, 0, "exit")

    assert.is_not_nil(terms.get(term.id))
    vim.schedule = original_schedule
  end)

  it("cleans up on failed exit when cleanup_on_failure is true", function()
    local term = terms.Terminal:new({ cleanup_on_success = false, cleanup_on_failure = true })
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    exit_handler(1, 1, "exit")

    assert.is_nil(terms.get(term.id))
    vim.schedule = original_schedule
  end)

  it("does not clean up on failed exit when cleanup_on_failure is false", function()
    local term = terms.Terminal:new({ cleanup_on_success = true, cleanup_on_failure = false })
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    exit_handler(1, 1, "exit")

    assert.is_not_nil(terms.get(term.id))
    vim.schedule = original_schedule
  end)

  it("calls user's on_job_exit handler before cleanup", function()
    local called = false
    local term = terms.Terminal:new({
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
    assert.is_nil(terms.get(term.id))
    vim.schedule = original_schedule
  end)
end)

describe(":get_state", function()
  it("returns the given key in the state of the terminal", function()
    local term = terms.Terminal:new()

    assert.equal("below", term:get_state("layout"))
  end)
end)

describe(":get_status_icon", function()
  it("returns play icon when terminal is started", function()
    local term = terms.Terminal:new()
    term:start()

    assert.equal("▶", term:get_status_icon())
  end)

  it("returns success icon when stopped but active with exit code 0", function()
    local term = terms.Terminal:new()
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    exit_handler(1, 0, "exit")

    assert.equal("✓", term:get_status_icon())
  end)

  it("returns failure icon when stopped but active with non-zero exit code", function()
    local term = terms.Terminal:new()
    term:start()
    local exit_handler = term:get_state("on_job_exit")
    exit_handler(1, 1, "exit")

    assert.equal("✗", term:get_status_icon())
  end)

  it("returns inactive icon for sticky terminals that are not active", function()
    local term = terms.Terminal:new({ sticky = true })

    assert.equal("○", term:get_status_icon())
  end)

  it("returns empty string for non-sticky terminals that are not active", function()
    local term = terms.Terminal:new({ sticky = false })

    assert.equal("", term:get_status_icon())
  end)
end)
