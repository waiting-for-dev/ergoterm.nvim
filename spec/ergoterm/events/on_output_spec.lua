---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local on_output = require("ergoterm.events.on_output")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".on_output", function()
  it("calls checktime when watch_files is true", function()
    local term = Terminal:new({ watch_files = true }):start()
    local callback = function() end
    local spy_cmd = spy.on(vim, "cmd")
    local original_schedule = vim.schedule
    local scheduled_fn
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) scheduled_fn = fn end

    on_output(term, 1, { "data" }, "stdout", callback)
    scheduled_fn()

    assert.spy(spy_cmd).was_called_with("checktime")

    vim.schedule = original_schedule
  end)

  it("does not call checktime when watch_files is false", function()
    local term = Terminal:new({ watch_files = false }):start()
    local callback = function() end
    local spy_cmd = spy.on(vim, "cmd")
    local original_schedule = vim.schedule
    local scheduled_fn
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.schedule = function(fn) scheduled_fn = fn end

    on_output(term, 1, { "data" }, "stdout", callback)
    if scheduled_fn then scheduled_fn() end

    assert.spy(spy_cmd).was_not_called_with("checktime")

    vim.schedule = original_schedule
  end)

  it("scrolls to the bottom when auto_scroll is true", function()
    local term = Terminal:new({ auto_scroll = true }):open()
    vim.api.nvim_win_set_cursor(term:get_state("window"), { 1, 0 })
    local callback = function() end

    on_output(term, 1, { "data" }, "stdout", callback)
    vim.wait(100)

    local cursor = vim.api.nvim_win_get_cursor(term:get_state("window"))
    local lines = vim.api.nvim_buf_line_count(term:get_state("bufnr"))
    assert.equal(lines, cursor[1])
  end)

  it("does not scroll to the bottom when auto_scroll is false", function()
    local term = Terminal:new({ auto_scroll = false }):open()
    vim.api.nvim_win_set_cursor(term:get_state("window"), { 1, 0 })
    local callback = function() end

    on_output(term, 1, { "data" }, "stdout", callback)
    vim.wait(100)

    local cursor = vim.api.nvim_win_get_cursor(term:get_state("window"))
    assert.equal(1, cursor[1])
  end)

  it("calls user's callback", function()
    local called = false
    local callback = function() called = true end
    local term = Terminal:new():start()

    on_output(term, 1, { "data" }, "stdout", callback)

    assert.is_true(called)
  end)
end)
