---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local close = require("ergoterm.instance.close")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe("close", function()
  it("closes the terminal window", function()
    local term = Terminal:new()
    term:open()
    local win_id = term:get_state("window")

    close(term)

    assert.is_false(vim.api.nvim_win_is_valid(win_id))
    assert.is_false(term:is_open())
  end)

  it("replaces the terminal window with an empty buffer if it is the last window", function()
    local term = Terminal:new()
    term:open("window")
    local win_id = term:get_state("window")
    local initial_bufnr = term:get_state("bufnr")

    close(term)

    local bufnr = vim.api.nvim_win_get_buf(win_id)
    assert.is_true(vim.api.nvim_buf_is_valid(bufnr))
    assert.not_equal(initial_bufnr, bufnr)
  end)

  it("persists absolute size when persist_size is true", function()
    local term = Terminal:new({ persist_size = true, layout = "below", size = { below = 10 } })
    term:open()
    local win_id = term:get_state("window")
    vim.api.nvim_win_set_config(win_id, { height = 20 })

    close(term)

    assert.equal(20, term:get_state("size").below)
  end)

  it("persists percentage size when persist_size is true", function()
    local original_lines = vim.o.lines
    vim.o.lines = 40

    local term = Terminal:new({ persist_size = true, layout = "below", size = { below = "50%" } })
    assert.equal("50%", term:get_state("size").below)
    term:open()
    local win_id = term:get_state("window")
    vim.api.nvim_win_set_config(win_id, { height = 20 })
    vim.o.lines = 80

    close(term)

    assert.equal("25%", term:get_state("size").below)

    vim.o.lines = original_lines
  end)

  it("doesn't persist size when persist_size is false", function()
    local term = Terminal:new({ persist_size = false, layout = "below", size = { below = 10 } })
    term:open()
    local win_id = term:get_state("window")
    vim.api.nvim_win_set_config(win_id, { height = 20 })

    close(term)

    assert.equal(10, term:get_state("size").below)
  end)

  it("runs the on_close() callback", function()
    local called = false
    local term = Terminal:new({
      on_close = function() called = true end,
    })
    term:open()

    close(term)

    assert.is_true(called)
  end)
end)
