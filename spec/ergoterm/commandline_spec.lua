---@diagnostic disable: undefined-field

local commandline = require("ergoterm.commandline")

describe("commandline.parse", function()
  it("parses simple key=value pairs", function()
    local args = "cmd=ls layout=right"

    local result = commandline.parse(args)

    assert.equal("ls", result.cmd)
    assert.equal("right", result.layout)
  end)

  it("parses quoted values (single quotes)", function()
    local args = "cmd='echo hello world' layout=below"

    local result = commandline.parse(args)

    assert.equal("echo hello world", result.cmd)
    assert.equal("below", result.layout)
  end)

  it("parses quoted values (double quotes)", function()
    local args = 'cmd="echo foo bar" layout=left'

    local result = commandline.parse(args)

    assert.equal("echo foo bar", result.cmd)
    assert.equal("left", result.layout)
  end)

  it("parses boolean values", function()
    local args = "trim=true new_line=false"

    local result = commandline.parse(args)

    assert.is_true(result.trim)
    assert.is_false(result.new_line)
  end)

  it("parses trailing arguments", function()
    local args = "cmd=ls layout=below some trailing args"

    local result = commandline.parse(args)

    assert.equal("ls", result.cmd)
    assert.equal("below", result.layout)
    assert.is_truthy(result.trailing)
  end)
end)

describe("commandline.term_send_complete", function()
  it("completes available options", function()
    local result = commandline.term_send_complete("", "", 0)

    assert.is_true(vim.tbl_contains(result, "text="))
    assert.is_true(vim.tbl_contains(result, "action="))
    assert.is_true(vim.tbl_contains(result, "decorator="))
    assert.is_true(vim.tbl_contains(result, "trim="))
    assert.is_true(vim.tbl_contains(result, "new_line="))
  end)

  it("completes boolean values for trim", function()
    local result = commandline.term_send_complete("trim=", "trim=", 5)

    assert.is_true(vim.tbl_contains(result, "trim=true"))
    assert.is_true(vim.tbl_contains(result, "trim=false"))
  end)

  it("completes action values", function()
    local result = commandline.term_send_complete("action=", "action=", 7)

    assert.is_true(vim.tbl_contains(result, "action=interactive"))
    assert.is_true(vim.tbl_contains(result, "action=silent"))
    assert.is_true(vim.tbl_contains(result, "action=visible"))
  end)

  it("completes decorator values", function()
    local decorators = require("ergoterm.text_decorators")
    local result = commandline.term_send_complete("decorator=", "decorator=", 10)

    assert.is_true(vim.tbl_contains(result, "decorator=" .. decorators.DECORATORS.IDENTITY))
    assert.is_true(vim.tbl_contains(result, "decorator=" .. decorators.DECORATORS.MARKDOWN_CODE))
  end)
end)

describe("commandline.term_new_complete", function()
  it("completes available options", function()
    local result = commandline.term_new_complete("", "", 0)

    assert.is_true(vim.tbl_contains(result, "dir="))
    assert.is_true(vim.tbl_contains(result, "layout="))
    assert.is_true(vim.tbl_contains(result, "name="))
  end)
end)

describe("commandline.term_update_complete", function()
  it("completes available options", function()
    local result = commandline.term_update_complete("", "", 0)

    assert.is_true(vim.tbl_contains(result, "layout="))
    assert.is_true(vim.tbl_contains(result, "name="))
    assert.is_true(vim.tbl_contains(result, "auto_scroll="))
    assert.is_true(vim.tbl_contains(result, "persist_mode="))
    assert.is_true(vim.tbl_contains(result, "selectable="))
    assert.is_true(vim.tbl_contains(result, "start_in_insert="))
  end)
end)
