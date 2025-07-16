---@diagnostic disable: undefined-field

local utils = require("ergoterm.utils")
local test_helpers = require("test_helpers")

describe(".notify", function()
  it("notifies with correct message, uppercased level, and title", function()
    local original_schedule = vim.schedule
    local original_notify = vim.notify
    vim.notify = function(...) end
    ---@diagnostic disable: duplicate-set-field
    vim.schedule = function(fn) fn() end
    spy.on(vim, "notify")
    spy.on(vim, "schedule")

    utils.notify("hello", "info")

    assert.spy(vim.schedule).was_called()
    assert.spy(vim.notify).was_called_with("hello", vim.log.levels.INFO, { title = "Ergoterm" })

    vim.schedule = original_schedule
    vim.notify = original_notify
  end)
end)

describe(".git_dir", function()
  local original_system

  before_each(function()
    original_system = vim.fn.system
  end)

  after_each(function()
    vim.fn.system = original_system
  end)

  it("returns trimmed git dir path when inside a git directory", function()
    ---@diagnostic disable: unused-vararg
    vim.fn.system = function(...) return "/home/user/project\n" end

    local result = utils.git_dir()

    assert.equal("/home/user/project", result)
  end)

  it("notifies and returns nil when not inside a git directory", function()
    ---@diagnostic disable: unused-vararg
    vim.fn.system = function(...) return "fatal: not a git repository\n" end

    local notify_result = test_helpers.mocking_notify(function()
      local result = utils.git_dir()
      assert.is_nil(result)
    end)

    ---@diagnostic disable: need-check-nil
    assert.equal("Not a valid git directory", notify_result.msg)
    assert.equal("error", notify_result.level)
    ---@diagnostic enable: need-check-nil
  end)
end)

describe(".str_is_empty", function()
  it("returns true for nil", function()
    assert.is_true(utils.str_is_empty(nil))
  end)

  it("returns true for empty string", function()
    assert.is_true(utils.str_is_empty(""))
  end)

  it("returns false for non-empty string", function()
    assert.is_false(utils.str_is_empty("hello"))
  end)

  it("returns false for whitespace string", function()
    assert.is_false(utils.str_is_empty("   "))
  end)
end)

describe(".tbl_filter_empty", function()
  it("filters out nil and empty strings", function()
    local input = { "a", "", nil, "b", " ", "", "c" }

    local result = utils.tbl_filter_empty(input)

    assert.same({ "a", "b", " ", "c" }, result)
  end)

  it("returns empty table if all values are empty or nil", function()
    local input = { "", nil, "" }

    local result = utils.tbl_filter_empty(input)

    assert.same({}, result)
  end)
end)

describe(".is_windows", function()
  local original_has

  before_each(function()
    original_has = vim.fn.has
  end)

  after_each(function()
    vim.fn.has = original_has
  end)

  it("returns true when vim.fn.has('win32') == 1", function()
    vim.fn.has = function(arg) return arg == "win32" and 1 or 0 end
    assert.is_true(utils.is_windows())
  end)

  it("returns false when vim.fn.has('win32') ~= 1", function()
    vim.fn.has = function(arg) return arg == "win32" and 0 or 1 end
    assert.is_false(utils.is_windows())
  end)
end)

describe(".get_dir", function()
  local original_git_dir = utils.git_dir
  local original_cwd = vim.loop.cwd
  local original_expand = vim.fn.expand
  local original_isdirectory = vim.fn.isdirectory

  before_each(function()
    ---@diagnostic disable: duplicate-set-field
    utils.git_dir = function() return "/git/dir" end
    vim.loop.cwd = function() return "/current/dir" end
    vim.fn.expand = function(arg) return "/expanded/" .. arg end
    vim.fn.isdirectory = function(_) return 1 end
  end)

  after_each(function()
    utils.git_dir = original_git_dir
    vim.loop.cwd = original_cwd
    vim.fn.expand = original_expand
    vim.fn.isdirectory = original_isdirectory
  end)

  it("returns git dir when dir == 'git_dir'", function()
    assert.equal("/git/dir", utils.get_dir("git_dir"))
  end)

  it("returns cwd when dir == nil", function()
    assert.equal("/current/dir", utils.get_dir(nil))
  end)

  it("returns expanded dir when dir is a valid directory", function()
    vim.fn.isdirectory = function(_) return 1 end

    assert.equal("/expanded/mydir", utils.get_dir("mydir"))
  end)

  it("notifies when dir is not a directory", function()
    vim.fn.isdirectory = function(_) return 0 end

    local notify_result = test_helpers.mocking_notify(function()
      local result = utils.get_dir("notadir")
      assert.are.equal("/expanded/notadir", result)
    end)

    ---@diagnostic disable: need-check-nil
    assert.equal("/expanded/notadir is not a directory", notify_result.msg)
    assert.equal("error", notify_result.level)
    ---@diagnostic enable: need-check-nil
  end)
end)
