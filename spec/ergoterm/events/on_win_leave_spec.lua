---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local on_win_leave = require("ergoterm.events.on_win_leave")
local mode = require("ergoterm.mode")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".on_win_leave", function()
  it("persists mode if persist_mode is true", function()
    local term = Terminal:new({ persist_mode = true, start_in_insert = true }):start()
    local original_mode_get = mode.get
    ---@diagnostic disable-next-line: duplicate-set-field
    mode.get = function() return "n" end

    on_win_leave(term)

    assert.equal("n", term:get_state("mode"))

    mode.get = original_mode_get
  end)

  it("does not persist mode if persist_mode is false", function()
    local term = Terminal:new({ persist_mode = false, start_in_insert = true }):start()
    local original_mode_get = mode.get
    ---@diagnostic disable-next-line: duplicate-set-field
    mode.get = function() return "n" end

    on_win_leave(term)

    assert.equal("i", term:get_state("mode"))

    mode.get = original_mode_get
  end)

  it("closes terminal if layout is float", function()
    local term = Terminal:new({ layout = "float" }):open()

    on_win_leave(term)

    assert.is_false(term:is_open())
  end)

  it("does not close terminal if layout is not float", function()
    local term = Terminal:new({ layout = "below" }):open()

    on_win_leave(term)

    assert.is_true(term:is_open())
  end)
end)
