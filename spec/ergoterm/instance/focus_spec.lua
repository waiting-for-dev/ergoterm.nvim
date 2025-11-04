---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local focus = require("ergoterm.instance.focus")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".focus", function()
  it("opens the terminal if not already open", function()
    local term = Terminal:new()

    focus(term)

    assert.is_true(term:is_open())
  end)

  it("forwards given layout when opening the terminal", function()
    local term = Terminal:new()

    focus(term, "right")

    assert.equal("right", term:get_state("layout"))
  end)

  it("sets the terminal window as the current window", function()
    local term = Terminal:new()

    focus(term)

    assert.equal(term:get_state("window"), vim.api.nvim_get_current_win())
  end)

  it("triggers on_buf_enter", function()
    local term = Terminal:new()

    focus(term)

    assert.equal(term, collection.get_last_focused())
  end)
end)

describe(".is_focused", function()
  it("returns true if the terminal is focused", function()
    local term = Terminal:new()

    focus(term)

    assert.is_true(focus.is_focused(term))
  end)

  it("returns false if the terminal is not focused", function()
    local term = Terminal:new()

    assert.is_false(focus.is_focused(term))
  end)
end)
