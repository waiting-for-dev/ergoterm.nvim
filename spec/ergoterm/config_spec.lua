---@diagnostic disable: undefined-field

local config = require("ergoterm.config")

describe("config.get", function()
  it("returns the full config when called without arguments", function()
    local conf = config.get()

    assert.is_table(conf)
    assert.is_not_nil(conf.terminal_defaults)
    assert.is_not_nil(conf.picker)
  end)

  it("returns a specific config value when key is provided", function()
    assert.equal(config.get("terminal_defaults.layout"), "below")
  end)

  it("returns nested config sections", function()
    local terminal_defaults = config.get("terminal_defaults")
    assert.is_table(terminal_defaults)
    assert.equal(terminal_defaults.layout, "below")

    local picker_config = config.get("picker")
    assert.is_table(picker_config)
  end)

  it("returns nil for non-existent keys", function()
    assert.is_nil(config.get("nonexistent"))
    assert.is_nil(config.get("terminal_defaults.nonexistent"))
  end)
end)

describe("config.set", function()
  it("overrides config values with user config", function()
    local old_layout = config.get("terminal_defaults.layout")

    ---@diagnostic disable: missing-fields
    config.set({ terminal_defaults = { layout = "left", auto_scroll = false } })

    assert.equal(config.get("terminal_defaults.layout"), "left")
    assert.is_false(config.get("terminal_defaults.auto_scroll"))

    config.set({ terminal_defaults = { layout = old_layout, auto_scroll = false } })
  end)

  it("merges deeply into nested tables", function()
    ---@diagnostic disable: missing-fields
    config.set({ terminal_defaults = { float_opts = { width = 123 } } })

    assert.equal(config.get("terminal_defaults.float_opts").width, 123)
  end)

  it("allows setting size configuration", function()
    ---@diagnostic disable: missing-fields
    config.set({ terminal_defaults = { size = { below = 25, right = "75%" } } })

    assert.equal(config.get("terminal_defaults.size").below, 25)
    assert.equal(config.get("terminal_defaults.size").right, "75%")
  end)

  it("allows setting picker configuration", function()
    ---@diagnostic disable: missing-fields
    config.set({ picker = { picker = "telescope" } })

    assert.equal(config.get("picker.picker"), "telescope")
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

    local conf = { picker = { picker = nil } }
    local picker = config.build_picker(conf)

    assert.is_not_nil(picker)
    assert.is_function(picker.select)
  end)

  it("returns built-in picker when picker is a string", function()
    local conf = { picker = { picker = "vim-ui-select" } }
    local picker = config.build_picker(conf)

    assert.is_not_nil(picker)
    assert.is_function(picker.select)
  end)

  it("returns custom picker object when picker is an object", function()
    local custom_picker = {
      select = function() end
    }
    local conf = { picker = { picker = custom_picker } }
    local picker = config.build_picker(conf)

    assert.equal(picker, custom_picker)
  end)

  it("throws error for unknown picker name", function()
    local conf = { picker = { picker = "unknown-picker" } }

    assert.has_error(function()
      config.build_picker(conf)
    end, "Unknown picker name: unknown-picker")
  end)
end)
