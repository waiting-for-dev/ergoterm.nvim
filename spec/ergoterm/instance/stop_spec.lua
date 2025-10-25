---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local stop = require("ergoterm.instance.stop")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(":stop", function()
  it("closes the terminal", function()
    local term = Terminal:new()
    term:start()

    stop(term)

    assert.is_false(term:is_open())
  end)

  it("runs the on_stop callback", function()
    local called = false
    local term = Terminal:new({
      on_stop = function() called = true end,
    })
    term:start()

    stop(term)

    assert.is_true(called)
  end)

  it("stops the running process", function()
    local term = Terminal:new()
    term:start()
    local job_id = term:get_state("job_id")
    local spy_jobstop = spy.on(vim.fn, "jobstop")

    stop(term)

    assert.spy(spy_jobstop).was_called_with(job_id)
  end)

  it("runs the exit handler", function()
    local term = Terminal:new()
    term:start()

    stop(term)
    vim.wait(100)

    assert.is_nil(term:get_state("job_id"))
  end)
end)
