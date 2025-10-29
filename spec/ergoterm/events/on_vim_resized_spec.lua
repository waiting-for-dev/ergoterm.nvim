---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local on_vim_resized = require("ergoterm.events.on_vim_resized")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".on_vim_resized", function()
  it("applies new win config to float terminal", function()
    local term = Terminal:new({ layout = "float", float_opts = { width = 60, height = 30 } })
    term:open()
    local spy_win_set_config = spy.on(vim.api, "nvim_win_set_config")

    on_vim_resized(term)

    assert.spy(spy_win_set_config).was_called_with(term:get_state("window"), match.is_table())
  end)

  it("applies new win config to a split terminal", function()
    local term = Terminal:new({ layout = "right" })
    term:open()
    local spy_win_set_config = spy.on(vim.api, "nvim_win_set_config")

    on_vim_resized(term)

    assert.spy(spy_win_set_config).was_called_with(term:get_state("window"), match.is_table())
  end)

  it("does nothing if layout is not float or split", function()
    local term = Terminal:new({ layout = "tab" })
    term:open()
    local spy_win_set_config = spy.on(vim.api, "nvim_win_set_config")

    on_vim_resized(term)

    assert.spy(spy_win_set_config).was_not_called()
  end)
end)
