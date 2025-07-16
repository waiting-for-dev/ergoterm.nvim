---@diagnostic disable: undefined-field

local config = require("ergoterm.config")

describe("config.get", function()
  it("returns the full config when called without arguments", function()
    local conf = config.get()

    assert.is_table(conf)
    assert.is_not_nil(conf.layout)
  end)

  it("returns a specific config value when key is provided", function()
    assert.equal(config.get("layout"), "below")
  end)
end)

describe("config.set", function()
  it("overrides config values with user config", function()
    local old_layout = config.get("layout")

    ---@diagnostic disable: missing-fields
    config.set({ layout = "left", auto_scroll = false })

    assert.equal(config.get("layout"), "left")
    assert.is_false(config.get("auto_scroll"))

    config.set({ layout = old_layout, auto_scroll = true })
  end)

  it("merges deeply into nested tables", function()
    ---@diagnostic disable: missing-fields
    config.set({ float_opts = { width = 123 } })

    assert.equal(config.get("float_opts").width, 123)
  end)
end)

describe("config.build_picker", function()
  local original_pcall

  before_each(function()
    original_pcall = pcall
  end)

  after_each(function()
    pcall = original_pcall
  end)

  it("autodetects picker when none is given", function()
    pcall = function(_, _)
      return false
    end

    local conf = { picker = nil }
    local picker = config.build_picker(conf)

    assert.is_not_nil(picker)
    assert.is_function(picker.select)
  end)

  it("returns built-in picker when picker is a string", function()
    local conf = { picker = "vim-ui-select" }
    local picker = config.build_picker(conf)

    assert.is_not_nil(picker)
    assert.is_function(picker.select)
  end)

  it("returns custom picker object when picker is an object", function()
    local custom_picker = {
      select = function() end,
      select_actions = function() return {} end
    }
    local conf = { picker = custom_picker }
    local picker = config.build_picker(conf)

    assert.equal(picker, custom_picker)
  end)

  it("throws error for unknown picker name", function()
    local conf = { picker = "unknown-picker" }

    assert.has_error(function()
      config.build_picker(conf)
    end, "Unknown picker name: unknown-picker")
  end)
end)
