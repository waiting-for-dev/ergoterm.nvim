---@diagnostic disable: undefined-field

local selector = require("ergoterm.text_selector")

local function set_selection_mock(val)
  local selection_mock = { get = function() return val end }
  setmetatable(vim.opt, {
    __index = function(_, k)
      if k == "selection" then return selection_mock end
      return nil
    end
  })
end

describe(".select", function()
  local original_win_get_cursor
  local original_getline
  local original_getpos
  local original_buf_get_text
  local original_buf_get_lines
  local original_visualmode
  local original_opt
  local original_cmd

  before_each(function()
    original_win_get_cursor = vim.api.nvim_win_get_cursor
    original_getline = vim.fn.getline
    original_getpos = vim.fn.getpos
    original_buf_get_text = vim.api.nvim_buf_get_text
    original_buf_get_lines = vim.api.nvim_buf_get_lines
    original_visualmode = vim.fn.visualmode
    original_opt = vim.opt
    original_cmd = vim.cmd
  end)

  after_each(function()
    vim.api.nvim_win_get_cursor = original_win_get_cursor
    vim.fn.getline = original_getline
    vim.fn.getpos = original_getpos
    vim.api.nvim_buf_get_text = original_buf_get_text
    vim.api.nvim_buf_get_lines = original_buf_get_lines
    vim.fn.visualmode = original_visualmode
    vim.opt = original_opt
    vim.cmd = original_cmd
  end)

  it("returns current line for 'single_line'", function()
    vim.api.nvim_win_get_cursor = function() return { 2, 3 } end
    ---@diagnostic disable-next-line: unused-local
    vim.fn.getline = function(_line) return "hello world" end

    local result = selector.select("single_line")

    assert.same({ "hello world" }, result)
  end)

  it("returns selected lines for 'visual_lines'", function()
    vim.fn.getpos = function(mark)
      if mark == "'<" then return { 0, 2, 1 } end
      if mark == "'>" then return { 0, 4, 1 } end
    end
    ---@diagnostic disable-next-line: unused-local
    vim.api.nvim_buf_get_lines = function(_, start, end_, _)
      return { "line2", "line3", "line4" }
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.cmd = function(_) end

    local result = selector.select("visual_lines")

    assert.same({ "line2", "line3", "line4" }, result)
  end)

  it("returns selected text for 'visual_selection' (characterwise)", function()
    --- @diagnostic disable-next-line: duplicate-set-field
    vim.fn.visualmode = function() return "v" end
    vim.fn.getpos = function(mark)
      if mark == "'<" then return { 0, 2, 2 } end
      if mark == "'>" then return { 0, 2, 5 } end
    end
    vim.api.nvim_buf_get_lines = function(_, _, _, _) return { "abcdef" } end
    vim.api.nvim_buf_get_text = function(_, sline, scol, eline, ecol, _)
      assert.equal(sline, 1)
      assert.equal(scol, 1)
      assert.equal(eline, 1)
      assert.equal(ecol, 5)
      return { "bcde" }
    end
    set_selection_mock("inclusive")
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.cmd = function(_) end

    local result = selector.select("visual_selection")

    assert.same({ "bcde" }, result)
  end)

  it("returns selected lines for 'line'", function()
    vim.fn.getpos = function(mark)
      if mark == "'[" then return { 0, 3, 1 } end
      if mark == "']" then return { 0, 5, 1 } end
    end
    ---@diagnostic disable-next-line: unused-local
    vim.api.nvim_buf_get_lines = function(_, start, end_, _)
      return { "line3", "line4", "line5" }
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.cmd = function(_) end

    local result = selector.select("line")

    assert.same({ "line3", "line4", "line5" }, result)
  end)

  it("returns selected text for 'char' (motion)", function()
    --- @diagnostic disable-next-line: duplicate-set-field
    vim.fn.visualmode = function() return "v" end
    vim.fn.getpos = function(mark)
      if mark == "'[" then return { 0, 2, 2 } end
      if mark == "']" then return { 0, 2, 4 } end
    end
    vim.api.nvim_buf_get_lines = function(_, _, _, _) return { "abcdef" } end
    vim.api.nvim_buf_get_text = function(_, sline, scol, eline, ecol, _)
      assert.equal(sline, 1)
      assert.equal(scol, 1)
      assert.equal(eline, 1)
      assert.equal(ecol, 4)
      return { "bcd" }
    end
    set_selection_mock("inclusive")
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.cmd = function(_) end

    local result = selector.select("char")

    assert.same({ "bcd" }, result)
  end)

  it("returns empty string if no lines are selected", function()
    vim.api.nvim_win_get_cursor = function() return { 1, 0 } end
    vim.fn.getline = function(_) return "" end

    local result = selector.select("single_line")

    assert.same({ "" }, result)
  end)

  it("handles blockwise visual selection", function()
    --- @diagnostic disable-next-line: duplicate-set-field
    vim.fn.visualmode = function() return string.char(22) end
    vim.fn.getpos = function(mark)
      if mark == "'<" then return { 0, 2, 2 } end
      if mark == "'>" then return { 0, 4, 4 } end
    end
    ---@diagnostic disable-next-line: unused-local
    vim.api.nvim_buf_get_lines = function(_, start, end_, _)
      return { "abcde", "vwxyz", "12345" }
    end
    set_selection_mock("inclusive")
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.cmd = function(_) end
    local res = {
      start_pos = { 2, 2 },
      end_pos = { 4, 4 },
      selected_lines = { "abcde", "vwxyz", "12345" }
    }

    local result = selector._get_visual_selection(res)

    assert.same({ "bcd", "wxy", "234" }, result)
  end)

  it("handles exclusive selection", function()
    --- @diagnostic disable-next-line: duplicate-set-field
    vim.fn.visualmode = function() return "v" end
    vim.fn.getpos = function(mark)
      if mark == "'<" then return { 0, 2, 2 } end
      if mark == "'>" then return { 0, 2, 5 } end
    end
    ---@diagnostic disable-next-line: unused-local
    vim.api.nvim_buf_get_text = function(_, sline, scol, eline, ecol, _)
      assert.equal(ecol, 4)
      return { "bcd" }
    end
    set_selection_mock("exclusive")
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.cmd = function(_) end

    local result = selector.select("visual_selection")

    assert.same({ "bcd" }, result)
  end)
end)
