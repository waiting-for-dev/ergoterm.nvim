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

  it("calls the on_win_close event", function()
    local called = false
    local term = Terminal:new({
      on_close = function() called = true end,
    })
    term:open()

    close(term)

    assert.is_true(called)
  end)
end)
