---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local instance = require("ergoterm.instance")
local Terminal = instance.Terminal

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".find", function()
  it("returns the first terminal matching given predicate", function()
    local term = Terminal:new({ name = "test" })
    Terminal:new({ name = "foo" })
    Terminal:new({ name = "test" })

    local result = collection.find(function(t)
      return t.name == "test"
    end)

    assert.equal(result, term)
  end)

  it("returns nil when no terminal matches predicate", function()
    Terminal:new({ name = "foo" })

    local result = collection.find(function(t)
      return t.name == "bar"
    end)

    assert.is_nil(result)
  end)

  it("returns nil when there are no terminals", function()
    local result = collection.find(function()
      return true
    end)

    assert.is_nil(result)
  end)
end)

describe(".get_focused", function()
  it("returns currently focused terminal", function()
    local term = Terminal:new():focus()

    local result = collection.get_focused()

    assert.equal(result, term)
  end)

  it("returns nil when there are terminals but none are focused", function()
    Terminal:new()

    assert.is_nil(collection.get_focused())
  end)
end)

describe(".identify", function()
  it("returns terminal when current buffer matches terminal buffer", function()
    local term = Terminal:new():focus()

    local result = collection.identify()

    assert.equal(result, term)
  end)

  it("returns nil when current buffer doesn't match any terminal buffer", function()
    Terminal:new():start()
    local other_bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(other_bufnr)

    local result = collection.identify()

    assert.is_nil(result)
  end)
end)

describe(".get_target_for_bang", function()
  it("returns last focused terminal with `bang_target` flag when universal selection is disabled", function()
    local term1 = Terminal:new({ bang_target = false })
    local term2 = Terminal:new()
    term2:focus()
    term1:focus()

    local result = collection.get_target_for_bang()

    assert.equal(result, term2)
  end)

  it("returns last focused terminal regardless of bang_target flag when universal selection is enabled", function()
    local term1 = Terminal:new({ bang_target = false })
    local term2 = Terminal:new()
    term2:focus()
    term1:focus()
    collection.toggle_universal_selection()

    local result = collection.get_target_for_bang()

    assert.equal(result, term1)

    collection.toggle_universal_selection()
  end)

  it("returns nil when no terminal has been focused", function()
    assert.is_nil(collection.get_target_for_bang())
  end)
end)

describe(".get", function()
  it("returns terminal with given id", function()
    local term = Terminal:new()

    local result = collection.get(term.id)

    assert.equal(result, term)
  end)

  it("returns nil when terminal does not exist", function()
    assert.is_nil(collection.get(1))
  end)
end)

describe(".get_by_name", function()
  it("returns terminal with given name", function()
    local term = Terminal:new({ name = "test" })

    local result = collection.get_by_name("test")

    assert.equal(result, term)
  end)

  it("returns nil when terminal does not exist", function()
    assert.is_nil(collection.get_by_name("foo"))
  end)
end)

describe(".filter", function()
  it("returns all terminals matching given predicate", function()
    local term1 = Terminal:new({ tags = { "test" } })
    local term2 = Terminal:new({ tags = { "test" } })
    Terminal:new({ tags = { "foo" } })

    local result = collection.filter(function(t)
      return vim.tbl_contains(t.tags, "test")
    end)

    assert.equal(2, #result)
    assert.is_true(vim.tbl_contains(result, term1))
    assert.is_true(vim.tbl_contains(result, term2))
  end)

  it("returns empty table when no terminals match predicate", function()
    Terminal:new({ name = "foo" })

    local result = collection.filter(function(t)
      return t.name == "bar"
    end)

    assert.equal(0, #result)
  end)
end)

describe(".get_all", function()
  it("returns all terminals", function()
    local term1 = Terminal:new()
    local term2 = Terminal:new()

    local result = collection.get_all()

    assert.equal(2, #result)
    assert.is_true(vim.tbl_contains(result, term1))
    assert.is_true(vim.tbl_contains(result, term2))
  end)

  it("doesn't include deleted terminals", function()
    local term1 = Terminal:new()
    local term2 = Terminal:new()
    term1:cleanup()

    local result = collection.get_all()

    assert.equal(1, #result)
    assert.is_true(vim.tbl_contains(result, term2))
  end)
end)

describe(".filter_by_tag", function()
  it("returns all terminals with the specified tag", function()
    local term1 = Terminal:new({ name = "test1", tags = { "dev", "backend" } })
    local term2 = Terminal:new({ name = "test2", tags = { "dev", "frontend" } })
    Terminal:new({ name = "test3", tags = { "production", "backend" } })

    local result = collection.filter_by_tag("dev")

    assert.equal(2, #result)
    assert.is_true(vim.tbl_contains(result, term1))
    assert.is_true(vim.tbl_contains(result, term2))
  end)

  it("returns empty table when no terminals have the specified tag", function()
    Terminal:new({ name = "test1", tags = { "dev" } })
    Terminal:new({ name = "test2", tags = { "frontend" } })

    local result = collection.filter_by_tag("production")

    assert.equal(0, #result)
  end)
end)

describe(".select", function()
  it("calls select with provided defaults", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term = Terminal:new()
    local callbacks = {}

    local result = collection.select({ terminals = { term }, prompt = "prompt", callbacks = callbacks, picker = picker })

    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term))
    assert.equal("prompt", result[2])
    assert.equal(callbacks, result[3])
  end)

  it("includes auto_list started terminals", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term = Terminal:new({ auto_list = true }):start()
    Terminal:new({ auto_list = false }):start()

    local result = collection.select({ prompt = "prompt", callbacks = {}, picker = picker })

    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term))
  end)

  it("includes auto_list stopped but not cleaned up terminals", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term1 = Terminal:new({ auto_list = true }):start():stop()
    local term2 = Terminal:new({ auto_list = false }):start():stop()
    vim.api.nvim_buf_delete(term2:get_state("bufnr"), { force = true })

    local result = collection.select({ prompt = "prompt", callbacks = {}, picker = picker })

    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term1))
  end)

  it("includes auto_list sticky terminals", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term = Terminal:new({ auto_list = true, sticky = true })
    Terminal:new({ auto_list = false, sticky = true })

    local result = collection.select({ prompt = "prompt", callbacks = {}, picker = picker })

    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term))
  end)

  it("includes all terminals when universal selection is enabled", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local term1 = Terminal:new({ auto_list = true }):start()
    local term2 = Terminal:new({ auto_list = false }):start()
    local term3 = Terminal:new({ auto_list = true, sticky = true })
    local term4 = Terminal:new({ auto_list = false, sticky = true })
    collection.toggle_universal_selection()

    local result = collection.select({ prompt = "prompt", callbacks = {}, picker = picker })

    assert.equal(4, #result[1])
    assert.is_true(vim.tbl_contains(result[1], term1))
    assert.is_true(vim.tbl_contains(result[1], term2))
    assert.is_true(vim.tbl_contains(result[1], term3))
    assert.is_true(vim.tbl_contains(result[1], term4))
  end)
end)

describe(".select_started", function()
  it("calls select_started with provided defaults", function()
    local picker = {
      select = function(terminals, prompt, callbacks)
        return { terminals, prompt, callbacks }
      end
    }
    local started_term = Terminal:new():start()
    local stopped_term = Terminal:new()
    local all_terminals = { started_term, stopped_term }

    local result = collection.select_started({ terminals = all_terminals, prompt = "prompt", picker = picker })

    assert.equal(1, #result[1])
    assert.is_true(vim.tbl_contains(result[1], started_term))
    assert.is_false(vim.tbl_contains(result[1], stopped_term))
  end)
end)

describe(".cleanup_all", function()
  it("cleans up all terminals", function()
    local term = Terminal:new()

    collection.cleanup_all()

    assert.is_nil(collection.get(term.id))
  end)

  it("stops any running terminals", function()
    local term = Terminal:new():start()

    collection.cleanup_all()

    assert.is_nil(collection.get(term.id))
  end)

  it("does not remove sticky terminals from session unless force is true", function()
    local regular_term = Terminal:new()
    local sticky_term = Terminal:new({ sticky = true })

    collection.cleanup_all()

    assert.is_nil(collection.get(regular_term.id))
    assert.is_not_nil(collection.get(sticky_term.id))
  end)

  it("removes sticky terminals from session when force is true", function()
    local regular_term = Terminal:new()
    local sticky_term = Terminal:new({ sticky = true })

    collection.cleanup_all({ force = true })

    assert.is_nil(collection.get(regular_term.id))
    assert.is_nil(collection.get(sticky_term.id))
  end)

  it("removes terminals from the session", function()
    local term = Terminal:new()
    term:open()

    collection.cleanup_all()

    assert.is_false(term:is_open())
    assert.is_nil(collection.get(term.id))
  end)
end)

describe(".get_state", function()
  it("returns value for a given key from the state", function()
    local term = Terminal:new({ foo = "bar" })

    assert.is_true(vim.tbl_contains(collection.get_state("terminals"), term))
  end)
end)

describe(".toggle_universal_selection", function()
  it("toggles universal selection state", function()
    local initial_state = collection.get_state("universal_selection")

    local result = collection.toggle_universal_selection()

    assert.equal(not initial_state, result)
    assert.equal(result, collection.get_state("universal_selection"))
  end)

  it("returns true when toggled from false", function()
    if collection.get_state("universal_selection") then
      collection.toggle_universal_selection()
    end

    local result = collection.toggle_universal_selection()

    assert.is_true(result)
  end)

  it("returns false when toggled from true", function()
    if not collection.get_state("universal_selection") then
      collection.toggle_universal_selection()
    end

    local result = collection.toggle_universal_selection()

    assert.is_false(result)
  end)
end)

describe(".reset_ids", function()
  it("resets sequence of terminal ids", function()
    local term1 = Terminal:new()
    term1:cleanup()

    collection.reset_ids()
    local term2 = Terminal:new()

    assert.equal(1, term2.id)
  end)
end)

describe(".with_defaults", function()
  local ergoterm = require("ergoterm")

  it("returns a factory with a new method", function()
    local factory = ergoterm.with_defaults({ tags = { "test" } })

    assert.is_not_nil(factory.new)
    assert.equal("function", type(factory.new))
  end)

  it("creates terminals with custom defaults merged with provided args", function()
    local factory = ergoterm.with_defaults({ tags = { "task" }, auto_list = false })
    local term = factory:new({ name = "foo" })

    assert.equal("foo", term.name)
    assert.is_false(term.auto_list)
    assert.equal(1, #term.tags)
    assert.is_true(vim.tbl_contains(term.tags, "task"))
  end)

  it("allows provided args to override custom defaults", function()
    local factory = ergoterm.with_defaults({ auto_list = false, name = "default" })
    local term = factory:new({ auto_list = true, name = "override" })

    assert.is_true(term.auto_list)
    assert.equal("override", term.name)
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

  it("still applies global config defaults", function()
    local factory = ergoterm.with_defaults({ tags = { "custom" } })
    local term = factory:new({ name = "test" })

    assert.is_true(term.bang_target)
    assert.equal("below", term.layout)
    assert.equal(vim.o.shell, term.cmd)
  end)
end)
