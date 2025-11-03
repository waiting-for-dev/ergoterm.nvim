---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local mode = require("ergoterm.mode")
local unfocus = require("ergoterm.instance.unfocus")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".unfocus", function()
  it("calls on_win_leave handler", function()
    local term = Terminal:new({ persist_mode = true, start_in_insert = true }):focus()
    local original_mode_get = mode.get
    ---@diagnostic disable-next-line: duplicate-set-field
    mode.get = function() return "n" end

    unfocus(term)

    assert.equal("n", term:get_state("mode"))

    mode.get = original_mode_get
  end)

  it("switches to given window if provided and valid", function()
    local term = Terminal:new()
    term:focus()
    local other_win = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, { split = "above" })

    unfocus(term, other_win)

    assert.equal(other_win, vim.api.nvim_get_current_win())
    vim.api.nvim_win_close(other_win, true)
  end)

  it("runs the on_unfocus callback", function()
    local called = false
    local term = Terminal:new({
      on_unfocus = function() called = true end,
    })
    term:focus()

    unfocus(term)

    assert.is_true(called)
  end)

  it("does nothing if terminal is not focused", function()
    local called = false
    local term = Terminal:new({
      on_unfocus = function() called = true end,
    })
    term:open()

    unfocus(term)

    assert.is_false(called)
  end)
end)
