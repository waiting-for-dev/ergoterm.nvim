---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local update = require("ergoterm.instance.update")
local test_helpers = require("test_helpers")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".update", function()
  it("updates passed settings", function()
    local term = Terminal:new({ name = "foo", layout = "below" })
    update(term, { name = "bar", layout = "right" })

    assert.equal("bar", term.name)
    assert.equal("right", term.layout)
  end)

  it("errors if not allowed setting is given", function()
    local term = Terminal:new({ cmd = "echo hello" })

    local result = test_helpers.mocking_notify(function()
      update(term, { cmd = "echo world" })
    end)

    assert.equal("Cannot change cmd after terminal creation", result.msg)
    assert.equal("error", result.level)
  end)

  it("doesn't update any setting if a non-supported setting is given", function()
    local term = Terminal:new({ name = "foo" })

    test_helpers.mocking_notify(function()
      update(term, { cmd = "echo world", name = "bar" })
    end)

    assert.equal("foo", term.name)
  end)

  it("recomputes mode", function()
    local term = Terminal:new({ start_in_insert = false })
    update(term, { start_in_insert = true })

    assert.equal("i", term:get_state("mode"))
  end)

  it("recomputes layout", function()
    local term = Terminal:new({ layout = "below" })
    update(term, { layout = "right" })

    assert.equal("right", term:get_state("layout"))
  end)

  it("recomputes on_job_exit", function()
    local foo = nil
    local term = Terminal:new({ on_job_exit = function() foo = "foo" end })
    update(term, { on_job_exit = function() foo = "bar" end })

    term:get_state("on_job_exit")(1, 2, "event")
    assert.equal("bar", foo)
  end)

  it("recomputes on_job_stdout", function()
    local foo = nil
    local term = Terminal:new({ on_job_stdout = function() foo = "foo" end })
    update(term, { on_job_stdout = function() foo = "bar" end })

    term:get_state("on_job_stdout")(1, { "data" }, "name")
    assert.equal("bar", foo)
  end)

  it("recomputes on_job_stderr", function()
    local foo = nil
    local term = Terminal:new({ on_job_stderr = function() foo = "foo" end })
    update(term, { on_job_stderr = function() foo = "bar" end })

    term:get_state("on_job_stderr")(1, { "data" }, "name")
    assert.equal("bar", foo)
  end)

  it("replaces table settings by default", function()
    local term = Terminal:new({ env = { FOO = "foo", BAR = "bar" } })
    update(term, { env = { BAZ = "baz" } })

    assert.equal(nil, term.env.FOO)
    assert.equal(nil, term.env.BAR)
    assert.equal("baz", term.env.BAZ)
  end)

  it("deep merges table settings when deep_merge = true", function()
    local term = Terminal:new({ env = { FOO = "foo", BAR = "bar" } })
    update(term, { env = { BAZ = "baz" } }, { deep_merge = true })

    assert.equal("foo", term.env.FOO)
    assert.equal("bar", term.env.BAR)
    assert.equal("baz", term.env.BAZ)
  end)
end)
