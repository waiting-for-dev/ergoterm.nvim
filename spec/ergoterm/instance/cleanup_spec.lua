---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local cleanup = require("ergoterm.instance.cleanup")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".cleanup", function()
  it("stops the terminal if started", function()
    local term = Terminal:new()
    term:start()

    cleanup(term)
    vim.wait(100)

    assert.is_false(term:is_started())
  end)

  it("resets the buffer id in the state", function()
    local term = Terminal:new()
    term:start()

    cleanup(term)

    assert.is_nil(term:get_state("bufnr"))
  end)

  it("removes the terminal from the last focused cache if it was focused", function()
    local term = Terminal:new()
    term:focus()

    cleanup(term)

    assert.is_nil(collection.get_target_for_bang())
  end)

  it("removes the terminal from the state if not sticky terminal", function()
    local term = Terminal:new()

    cleanup(term)

    assert.is_nil(collection.get(term.id))
  end)

  it("does not remove sticky terminals from state", function()
    local term = Terminal:new({ sticky = true })

    cleanup(term)

    assert.is_not_nil(collection.get(term.id))
  end)

  it("removes sticky terminals from state when force is true", function()
    local term = Terminal:new({ sticky = true })

    cleanup(term, { force = true })

    assert.is_nil(collection.get(term.id))
  end)
end)

describe(".is_cleaned_up", function()
  it("returns true if the terminal has been started and manually cleaned up", function()
    local term = Terminal:new()
    term:start()

    cleanup(term)

    assert.is_true(cleanup.is_cleaned_up(term))
  end)

  it("returns false if the terminal has been started but not cleaned up", function()
    local term = Terminal:new()
    term:start()

    assert.is_false(cleanup.is_cleaned_up(term))
  end)

  it("returns false if the terminal has not been started yet", function()
    local term = Terminal:new()

    assert.is_false(cleanup.is_cleaned_up(term))
  end)
end)
