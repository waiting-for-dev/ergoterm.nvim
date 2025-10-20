---@diagnostic disable: undefined-field

local ergoterm = require("ergoterm")

after_each(function()
  ergoterm.cleanup_all({ force = true })
  ergoterm.reset_ids()
end)

it("provides access to collection methods", function()
  assert.is_function(ergoterm.find)
  assert.is_function(ergoterm.get_all)
  assert.is_function(ergoterm.filter)
  assert.is_function(ergoterm.get)
  assert.is_function(ergoterm.get_by_name)
  assert.is_function(ergoterm.get_focused)
  assert.is_function(ergoterm.get_last_focused)
  assert.is_function(ergoterm.identify)
  assert.is_function(ergoterm.filter_by_tag)
  assert.is_function(ergoterm.select)
  assert.is_function(ergoterm.select_started)
  assert.is_function(ergoterm.cleanup_all)
  assert.is_function(ergoterm.get_state)
  assert.is_function(ergoterm.toggle_universal_selection)
  assert.is_function(ergoterm.reset_ids)
end)

it("provides access to Terminal class", function()
  assert.is_not_nil(ergoterm.Terminal)
  assert.equal("table", type(ergoterm.Terminal))
  assert.is_function(ergoterm.Terminal.new)
  assert.is_function(ergoterm.Terminal.start)
end)

it("provides access to text_decorators", function()
  assert.equal("table", type(ergoterm.text_decorators))
  assert.is_function(ergoterm.text_decorators.identity)
end)

describe(":new()", function()
  it("creates a new terminal", function()
    local term = ergoterm:new({ name = "test" })

    assert.equal("test", term.name)
    assert.is_function(term.start)
    assert.is_function(term.stop)
  end)
end)

describe(".with_defaults()", function()
  it("returns a factory with a new method", function()
    local factory = ergoterm.with_defaults({ tags = { "test" } })

    assert.is_not_nil(factory.new)
    assert.equal("function", type(factory.new))
  end)

  it("creates terminals with provided defaults", function()
    local factory = ergoterm.with_defaults({ selectable = false })
    local term = factory:new()

    assert.is_false(term.selectable)
  end)

  it("allows overriding default", function()
    local factory = ergoterm.with_defaults({ selectable = false })
    local term = factory:new({ selectable = true })

    assert.is_true(term.selectable)
  end)

  it("falls back to global defaults for unspecified settings", function()
    local factory = ergoterm.with_defaults({ name = "factory_term" })
    local term = factory:new()

    assert.is_true(term.selectable)
    assert.equal("below", term.layout)
  end)

  it("deep merges nested tables settings", function()
    local factory = ergoterm.with_defaults({
      float_opts = { width = 100, height = 50 }
    })
    local term = factory:new({
      float_opts = { title = "custom" }
    })

    assert.equal(100, term.float_opts.width)
    assert.equal(50, term.float_opts.height)
    assert.equal("custom", term.float_opts.title)
  end)
end)
