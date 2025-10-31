---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local on_buf_enter = require("ergoterm.events.on_buf_enter")
local mode = require("ergoterm.mode")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".on_buf_enter", function()
  it("sets the terminal as the last focused", function()
    local term = Terminal:new()

    on_buf_enter(term)

    assert.equal(term, collection.get_last_focused())
  end)

  it("restores last mode if persist_mode is true", function()
    local term = Terminal:new({ persist_mode = true, start_in_insert = false })
    local spy_mode_set = spy.on(mode, "set")

    on_buf_enter(term)

    assert.spy(spy_mode_set).was_called_with("n")
  end)

  it("starts in insert mode if persist_mode is false and start_in_insert is true", function()
    local term = Terminal:new({ persist_mode = false, start_in_insert = true })
    local spy_mode_set_initial = spy.on(mode, "set_initial")

    on_buf_enter(term)

    assert.spy(spy_mode_set_initial).was_called_with(true)
  end)

  it("starts in normal mode if persist_mode is false and start_in_insert is false", function()
    local term = Terminal:new({ persist_mode = false, start_in_insert = false })
    local spy_mode_set_initial = spy.on(mode, "set_initial")

    on_buf_enter(term)

    assert.spy(spy_mode_set_initial).was_called_with(false)
  end)
end)
