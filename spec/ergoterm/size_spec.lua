---@diagnostic disable: undefined-field

local size = require("ergoterm.size")

describe(".is_percentage", function()
  it("returns true for percentage strings", function()
    assert.is_true(size.is_percentage("50%"))
  end)

  it("returns false for numeric values", function()
    assert.is_false(size.is_percentage(50))
  end)
end)

describe(".is_vertical", function()
  it("returns true for left layout", function()
    assert.is_true(size.is_vertical("left"))
  end)

  it("returns true for right layout", function()
    assert.is_true(size.is_vertical("right"))
  end)

  it("returns false for below layout", function()
    assert.is_false(size.is_vertical("below"))
  end)

  it("returns false for above layout", function()
    assert.is_false(size.is_vertical("above"))
  end)

  it("returns false for other layouts", function()
    assert.is_false(size.is_vertical("float"))
    assert.is_false(size.is_vertical("tab"))
  end)
end)

describe(".percentage_to_absolute", function()
  it("converts percentage to absolute for vertical layouts", function()
    local original_lines = vim.o.lines
    vim.o.lines = 40

    local result = size.percentage_to_absolute("50%", "below")

    assert.equal(20, result)

    vim.o.lines = original_lines
  end)

  it("converts percentage to absolute for above layout", function()
    local original_lines = vim.o.lines
    vim.o.lines = 100

    local result = size.percentage_to_absolute("25%", "above")

    assert.equal(25, result)

    vim.o.lines = original_lines
  end)

  it("converts percentage to absolute for horizontal layouts", function()
    local original_columns = vim.o.columns
    vim.o.columns = 80

    local result = size.percentage_to_absolute("50%", "right")

    assert.equal(40, result)

    vim.o.columns = original_columns
  end)

  it("converts percentage to absolute for left layout", function()
    local original_columns = vim.o.columns
    vim.o.columns = 200

    local result = size.percentage_to_absolute("25%", "left")

    assert.equal(50, result)

    vim.o.columns = original_columns
  end)

  it("rounds up fractional results", function()
    local original_lines = vim.o.lines
    vim.o.lines = 41

    local result = size.percentage_to_absolute("50%", "below")

    assert.equal(21, result)

    vim.o.lines = original_lines
  end)
end)
