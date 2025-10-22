---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local Terminal = require("ergoterm.instance").Terminal
local start = require("ergoterm.instance.start")

after_each(function()
  collection.cleanup_all({ force = true })
  collection.reset_ids()
end)

describe(".start", function()
  it("recomputes dir", function()
    local original_termopen = vim.fn.termopen
    local original_cwd = vim.loop.cwd
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.termopen = function(_, _) return 1 end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.loop.cwd = function() return "/initial/dir" end

    local term = Terminal:new({})

    assert.equal("/initial/dir", term:get_state("dir"))

    ---@diagnostic disable-next-line: duplicate-set-field
    vim.loop.cwd = function() return "/changed/dir" end

    start(term)

    assert.equal("/changed/dir", term:get_state("dir"))

    vim.fn.termopen = original_termopen
    vim.loop.cwd = original_cwd
  end)

  it("initializes buffer", function()
    local term = Terminal:new()

    start(term)

    local bufnr = term:get_state("bufnr")
    assert.is_not_nil(bufnr)
    assert.is_true(vim.api.nvim_buf_is_valid(bufnr))
  end)

  it("sets has_been_started to true", function()
    local term = Terminal:new()

    start(term)

    assert.is_true(term:get_state("has_been_started"))
  end)

  it("starts job with the given command", function()
    local term = Terminal:new({ cmd = "echo hello" })
    local spy_termopen = spy.on(vim.fn, "termopen")

    start(term)

    assert.spy(spy_termopen).was_called_with("echo hello", match.is_table())
  end)

  it("starts job in the computed directory", function()
    local term = Terminal:new({})
    local spy_termopen = spy.on(vim.fn, "termopen")

    start(term)

    local args = spy_termopen.calls[1].refs[2]
    assert.equal(term:get_state("dir"), args.cwd)
  end)

  it("starts job with the configured exit handler", function()
    local term = Terminal:new({})
    local spy_termopen = spy.on(vim.fn, "termopen")

    start(term)

    local args = spy_termopen.calls[1].refs[2]
    assert.equal(term:get_state("on_job_exit"), args.on_exit)
  end)

  it("starts job with the configured stdout handler", function()
    local term = Terminal:new({})
    local spy_termopen = spy.on(vim.fn, "termopen")

    start(term)

    local args = spy_termopen.calls[1].refs[2]
    assert.equal(term:get_state("on_job_stdout"), args.on_stdout)
  end)

  it("starts job with the configured env", function()
    local term = Terminal:new({ env = { FOO = "bar" } })
    local spy_termopen = spy.on(vim.fn, "termopen")

    start(term)

    local args = spy_termopen.calls[1].refs[2]
    assert.same({ FOO = "bar" }, args.env)
  end)

  it("starts job with the configured clear_env", function()
    local term = Terminal:new({ clear_env = true })
    local spy_termopen = spy.on(vim.fn, "termopen")

    start(term)

    local args = spy_termopen.calls[1].refs[2]
    assert.is_true(args.clear_env)
  end)

  it("updates the state with the new job_id", function()
    local term = Terminal:new()

    start(term)

    local job_id = term:get_state("job_id")
    assert.is_number(job_id)
  end)

  it("runs the on_start callback", function()
    local called = false
    local term = Terminal:new({
      on_start = function() called = true end,
    })

    start(term)

    assert.is_true(called)
  end)

  it("does nothing if already started", function()
    local term = Terminal:new()
    start(term)
    local initial_bufnr = term:get_state("bufnr")
    local initial_job_id = term:get_state("job_id")

    start(term)

    assert.equal(initial_bufnr, term:get_state("bufnr"))
    assert.equal(initial_job_id, term:get_state("job_id"))
  end)
end)

describe(":is_started", function()
  it("returns true if terminal is started", function()
    local term = Terminal:new():start()

    assert.is_true(start.is_started(term))
  end)

  it("returns false if terminal is not started", function()
    local term = Terminal:new()

    assert.is_false(start.is_started(term))
  end)
end)
