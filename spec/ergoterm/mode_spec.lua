---@diagnostic disable: undefined-field

local mode = require("ergoterm.mode")

describe(".get", function()
  local original_get_mode

  before_each(function()
    original_get_mode = vim.api.nvim_get_mode
  end)

  after_each(function()
    vim.api.nvim_get_mode = original_get_mode
  end)

  it("returns NORMAL for mode 'nt'", function()
    vim.api.nvim_get_mode = function() return { mode = "nt" } end

    assert.equal(mode.NORMAL, mode.get())
  end)

  it("returns INSERT for mode 't'", function()
    vim.api.nvim_get_mode = function() return { mode = "t" } end

    assert.equal(mode.INSERT, mode.get())
  end)

  it("returns nil for unknown mode", function()
    vim.api.nvim_get_mode = function() return { mode = "x" } end

    assert.is_nil(mode.get())
  end)
end)

describe(".get_initial", function()
  it("returns INSERT when start_in_insert is true", function()
    assert.equal(mode.INSERT, mode.get_initial(true))
  end)

  it("returns NORMAL when start_in_insert is false", function()
    assert.equal(mode.NORMAL, mode.get_initial(false))
  end)
end)

describe(".set_initial", function()
  local original_set

  before_each(function()
    original_set = mode.set
    ---@diagnostic disable: duplicate-set-field
    mode.set = function(_) end
    spy.on(mode, "set")
  end)

  after_each(function()
    mode.set = original_set
  end)

  it("calls set with INSERT when start_in_insert is true", function()
    mode.set_initial(true)

    assert.spy(mode.set).was_called_with(mode.INSERT)
  end)

  it("calls set with NORMAL when start_in_insert is false", function()
    mode.set_initial(false)

    assert.spy(mode.set).was_called_with(mode.NORMAL)
  end)
end)

describe(".set", function()
  local original_defer_fn
  local original_cmd

  before_each(function()
    original_defer_fn = vim.defer_fn
    original_cmd = vim.cmd
    vim.defer_fn = function(fn, _) fn() end
    vim.cmd = function(_) end
    spy.on(vim, "cmd")
  end)

  after_each(function()
    vim.defer_fn = original_defer_fn
    vim.cmd = original_cmd
  end)

  it("calls startinsert when mode is INSERT", function()
    mode.set(mode.INSERT)

    assert.spy(vim.cmd).was_called_with("startinsert")
  end)

  it("calls stopinsert when mode is NORMAL", function()
    mode.set(mode.NORMAL)

    assert.spy(vim.cmd).was_called_with("stopinsert")
  end)
end)
