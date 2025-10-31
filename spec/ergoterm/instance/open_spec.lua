---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local open = require("ergoterm.instance.open")
local test_helpers = require("test_helpers")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".open", function()
  it("starts the terminal if it is not yet started", function()
    local term = Terminal:new()

    open.open(term)

    assert.is_true(term:is_started())
  end)

  it("opens the terminal above if layout is above", function()
    local term = Terminal:new()

    open.open(term, "above")

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("above", win_config.split)
  end)

  it("opens the terminal below if layout is below", function()
    local term = Terminal:new()

    open.open(term, "below")

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("below", win_config.split)
  end)

  it("opens the terminal at the left if layout is left", function()
    local term = Terminal:new()

    open.open(term, "left")

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("left", win_config.split)
  end)

  it("opens the terminal at the right if layout is right", function()
    local term = Terminal:new()

    open.open(term, "right")

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("right", win_config.split)
  end)

  it("opens the terminal in another tab if layout is tab", function()
    local term = Terminal:new()
    local current_tabpage = vim.api.nvim_get_current_tabpage()

    open.open(term, "tab")

    local tabpage = term:get_state("tabpage")
    assert.is_true(vim.api.nvim_tabpage_is_valid(tabpage))
    assert.not_equal(current_tabpage, tabpage)
  end)

  it("opens the terminal in a float window if layout is float", function()
    local term = Terminal:new()

    open.open(term, "float")

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.is_true(win_config.relative == "editor")
  end)

  it("opens the terminal in the current window if layout is window", function()
    local term = Terminal:new()
    local current_window = vim.api.nvim_get_current_win()

    open.open(term, "window")

    local win_id = term:get_state("window")
    assert.equal(current_window, win_id)
  end)

  it("opens with the initial layout if not provided", function()
    local term = Terminal:new({ layout = "below" })

    open.open(term)

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("below", win_config.split)
  end)

  it("opens with the last used layout if not provided", function()
    local term = Terminal:new({ layout = "below" })

    open.open(term, "right")
    term:close()
    open.open(term)

    local win_id = term:get_state("window")
    local win_config = vim.api.nvim_win_get_config(win_id)
    assert.equal("right", win_config.split)
  end)

  it("errors if layout is invalid", function()
    local term = Terminal:new()

    local result = test_helpers.mocking_notify(function()
      ---@diagnostic disable-next-line: param-type-mismatch
      open.open(term, "invalid_layout")
    end)

    assert.equal("Invalid layout option: invalid_layout", result.msg)
    assert.equal("error", result.level)
  end)

  it("keeps focus on the original window", function()
    local term = Terminal:new()
    local original_window = vim.api.nvim_get_current_win()

    open.open(term, "right")

    assert.equal(original_window, vim.api.nvim_get_current_win())
  end)

  it("stores the layout in the state", function()
    local term = Terminal:new()

    open.open(term, "right")

    assert.equal("right", term:get_state("layout"))
  end)

  it("stores the window in the state", function()
    local term = Terminal:new()

    open.open(term, "right")

    assert.is_not_nil(term:get_state("window"))
  end)

  it("stores the tab in the state", function()
    local term = Terminal:new()

    open.open(term, "tab")

    assert.is_not_nil(term:get_state("tabpage"))
  end)

  it("runs the on_open callback", function()
    local called = false
    local term = Terminal:new({
      on_open = function() called = true end,
    })

    open.open(term)

    assert.is_true(called)
  end)

  it("sets the window as no number", function()
    local term = Terminal:new()

    open.open(term)

    assert.is_false(vim.wo[term:get_state("window")].number)
  end)

  it("sets the window as no sign column", function()
    local term = Terminal:new()

    open.open(term)

    assert.equal("no", vim.wo[term:get_state("window")].signcolumn)
  end)

  it("sets the window as no relative number", function()
    local term = Terminal:new()

    open.open(term)

    assert.is_false(vim.wo[term:get_state("window")].relativenumber)
  end)

  it("sets the window with foldmethod manual", function()
    local term = Terminal:new()

    open.open(term)

    assert.equal("manual", vim.wo[term:get_state("window")].foldmethod)
  end)

  it("sets the window with foldtext foldtext()", function()
    local term = Terminal:new()

    open.open(term)

    assert.equal("foldtext()", vim.wo[term:get_state("window")].foldtext)
  end)

  it("sets the window as no side scroll when layout is float", function()
    local term = Terminal:new()

    open.open(term, "float")

    assert.equal(0, vim.wo[term:get_state("window")].sidescrolloff)
  end)

  it("sets the window with float_windblend given in initialization if layout is float", function()
    local term = Terminal:new({ float_winblend = 20 })

    open.open(term, "float")

    assert.equal(20, vim.wo[term:get_state("window")].winblend)
  end)
end)

describe(".is_open", function()
  it("returns false if terminal is not open", function()
    local term = Terminal:new()
    assert.is_false(open.is_open(term))
  end)

  it("returns true if terminal is open", function()
    local term = Terminal:new()
    open.open(term)

    assert.is_true(open.is_open(term))
  end)

  it("returns true if terminal is open in another tab", function()
    local term = Terminal:new()
    open.open(term, "tab")

    assert.is_true(term:is_open())
  end)
end)
