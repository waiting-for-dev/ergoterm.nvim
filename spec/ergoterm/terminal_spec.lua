---@diagnostic disable: undefined-field

local test_helpers = require("test_helpers")

after_each(function()
  local terms = require("ergoterm.terminal")
  terms.cleanup_all({ force = true })
  terms.reset_ids()
end)

describe("ergoterm.terminal (deprecated module)", function()
  it("shows deprecation warning on require", function()
    local result = test_helpers.mocking_notify(function()
      package.loaded["ergoterm.terminal"] = nil
      require("ergoterm.terminal")
    end)

    assert.equal("require('ergoterm.terminal') is deprecated. Use require('ergoterm') instead.", result.msg)
    assert.equal("warn", result.level)
  end)

  it("still provides access to collection methods", function()
    local terms = require("ergoterm.terminal")

    assert.is_function(terms.find)
    assert.is_function(terms.get_all)
    assert.is_function(terms.filter)
    assert.is_function(terms.get)
    assert.is_function(terms.get_by_name)
    assert.is_function(terms.cleanup_all)
    assert.is_function(terms.select)
  end)

  it("still provides access to Terminal class", function()
    local terms = require("ergoterm.terminal")

    assert.is_not_nil(terms.Terminal)
    assert.equal("table", type(terms.Terminal))
  end)

  it("Terminal class still works", function()
    local terms = require("ergoterm.terminal")

    local term = terms.Terminal:new({ name = "test" })

    assert.equal("test", term.name)
    assert.is_function(term.start)
    assert.is_function(term.stop)
    assert.is_function(term.open)
    assert.is_function(term.close)
  end)

  it("collection methods still work correctly", function()
    local terms = require("ergoterm.terminal")

    local term1 = terms.Terminal:new({ name = "foo" })
    local term2 = terms.Terminal:new({ name = "bar" })

    local all_terms = terms.get_all()
    assert.equal(2, #all_terms)
    assert.is_true(vim.tbl_contains(all_terms, term1))
    assert.is_true(vim.tbl_contains(all_terms, term2))

    local found = terms.find(function(t)
      return t.name == "foo"
    end)
    assert.equal(term1, found)
  end)

  it("with_defaults factory still works", function()
    local terms = require("ergoterm.terminal")

    local factory = terms.with_defaults({ tags = { "test" } })
    local term = factory:new({ name = "custom" })

    assert.equal("custom", term.name)
    assert.equal(1, #term.tags)
    assert.is_true(vim.tbl_contains(term.tags, "test"))
  end)
end)
