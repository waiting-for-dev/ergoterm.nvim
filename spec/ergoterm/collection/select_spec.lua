---@diagnostic disable: undefined-field

local select = require("ergoterm.collection.select")
local terms = require("ergoterm")
local test_helpers = require("test_helpers")

after_each(function()
  terms.cleanup_all({ close = true, force = true })
  terms.reset_ids()
end)

describe(".select", function()
  it("returns result of calling picker with given terminals, prompt and callbacks", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term = terms.Terminal:new()
    local callbacks = {}

    local result = select({ terminals = { term }, prompt = "prompt", callbacks = callbacks, picker = picker })

    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term))
    assert.equal("prompt", result[2])
    assert.equal(callbacks, result[3])
  end)

  it("notifies when no terminals are started", function()
    local result = test_helpers.mocking_notify(function()
      select({ terminals = {}, prompt = "prompt" })
    end)

    assert.equal("No ergoterm terminals available", result.msg)
    assert.equal("info", result.level)
  end)

  it("short-circuits when a single terminal with a single default callback", function()
    local term = terms.Terminal:new()
    local executed = false
    local callback_fn = function(t)
      executed = true
      assert.equal(term, t)
    end

    terms.select({ terminals = { term }, prompt = "prompt", callbacks = { default = { fn = callback_fn, desc = "Default action" } } })

    assert.is_true(executed)
  end)

  it("wraps a single function given as a default callback", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term = terms.Terminal:new()
    local callback_fn = function(t) return t end

    local result = terms.select({ terminals = { term, term }, prompt = "prompt", callbacks = callback_fn, picker = picker })

    assert.is_table(result[3])
    assert.is_table(result[3].default)
    assert.equal(callback_fn, result[3].default.fn)
    assert.equal("Default action", result[3].default.desc)
  end)
end)

describe(".select_started", function()
  it("filters terminals to only include started ones", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local started_term = terms.Terminal:new():start()
    local stopped_term = terms.Terminal:new()

    local result = select.select_started({ terminals = { started_term, stopped_term }, prompt = "prompt", picker = picker })

    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], started_term))
  end)

  it("uses default terminal when no terminals are started", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local stopped_term = terms.Terminal:new()
    local default_term = terms.Terminal:new()

    local result = select.select_started({
      terminals = { stopped_term, default_term },
      prompt = "prompt",
      picker = picker,
      default = default_term
    })

    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], default_term))
  end)
end)
