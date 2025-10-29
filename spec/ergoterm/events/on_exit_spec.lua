---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local on_exit = require("ergoterm.events.on_exit")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".on_exit", function()
  it("sets job_id to nil", function()
    local term = Terminal:new():start()
    local callback = function() end

    on_exit(term, 1, 0, "exit", callback)

    assert.is_nil(term:get_state("job_id"))
  end)

  it("sets last_exit_code", function()
    local term = Terminal:new():start()
    local callback = function() end

    on_exit(term, 1, 42, "exit", callback)

    assert.equal(42, term:get_state("last_exit_code"))
  end)

  it("cleans up on successful exit when cleanup_on_success is true", function()
    local term = Terminal:new({ cleanup_on_success = true, cleanup_on_failure = false })
    local callback = function() end
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    on_exit(term, 1, 0, "exit", callback)

    assert.is_nil(collection.get(term.id))

    vim.schedule = original_schedule
  end)

  it("does not clean up on successful exit when cleanup_on_success is false", function()
    local term = Terminal:new({ cleanup_on_success = false, cleanup_on_failure = true })
    local callback = function() end
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    on_exit(term, 1, 0, "exit", callback)

    assert.is_not_nil(collection.get(term.id))

    vim.schedule = original_schedule
  end)

  it("cleans up on failed exit when cleanup_on_failure is true", function()
    local term = Terminal:new({ cleanup_on_success = false, cleanup_on_failure = true })
    local callback = function() end
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    on_exit(term, 1, 1, "exit", callback)

    assert.is_nil(collection.get(term.id))

    vim.schedule = original_schedule
  end)

  it("does not clean up on failed exit when cleanup_on_failure is false", function()
    local term = Terminal:new({ cleanup_on_success = true, cleanup_on_failure = false })
    local callback = function() end
    local original_schedule = vim.schedule
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) fn() end

    on_exit(term, 1, 1, "exit", callback)

    assert.is_not_nil(collection.get(term.id))

    vim.schedule = original_schedule
  end)

  it("opens on successful exit when show_on_success is true", function()
    local term = Terminal:new({ cleanup_on_success = false, show_on_success = true }):start()
    local callback = function() end

    on_exit(term, 1, 0, "exit", callback)
    vim.wait(100)

    assert.is_true(term:is_open())

    vim.api.nvim_win_close(term:get_state("window"), true)
  end)

  it("does not open on successful exit when show_on_success is false", function()
    local term = Terminal:new({ cleanup_on_success = false, show_on_success = false }):start()
    local callback = function() end

    on_exit(term, 1, 0, "exit", callback)
    vim.wait(100)

    assert.is_false(term:is_open())
  end)

  it("opens on failed exit when show_on_failure is true", function()
    local term = Terminal:new({ cleanup_on_failure = false, show_on_failure = true }):start()
    local callback = function() end

    on_exit(term, 1, 1, "exit", callback)
    vim.wait(100)

    assert.is_true(term:is_open())

    vim.api.nvim_win_close(term:get_state("window"), true)
  end)

  it("does not open on failed exit when show_on_failure is false", function()
    local term = Terminal:new({ show_on_success = true, show_on_failure = false }):start()
    local callback = function() end

    on_exit(term, 1, 1, "exit", callback)
    vim.wait(100)

    assert.is_false(term:is_open())
  end)

  it("does not restart process when show_on_success triggers", function()
    local term = Terminal:new({ cleanup_on_success = false, show_on_success = true }):start()
    local callback = function() end

    on_exit(term, 1, 0, "exit", callback)
    vim.wait(100)

    assert.is_nil(term:get_state("job_id"))
    assert.is_true(term:is_open())
    assert.is_false(term:is_started())

    vim.api.nvim_win_close(term:get_state("window"), true)
  end)

  it("does not restart process when show_on_failure triggers", function()
    local term = Terminal:new({ cleanup_on_failure = false, show_on_failure = true }):start()
    local callback = function() end

    on_exit(term, 1, 1, "exit", callback)
    vim.wait(100)

    assert.is_nil(term:get_state("job_id"))
    assert.is_true(term:is_open())
    assert.is_false(term:is_started())

    vim.api.nvim_win_close(term:get_state("window"), true)
  end)

  it("calls user's callback", function()
    local called = false
    local callback = function() called = true end
    local term = Terminal:new()

    on_exit(term, 1, 0, "exit", callback)

    assert.is_true(called)
  end)
end)
