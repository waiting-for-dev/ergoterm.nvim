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

    assert.is_true(vim.tbl_contains(result, "cmd="))
    assert.is_true(vim.tbl_contains(result, "dir="))
    assert.is_true(vim.tbl_contains(result, "layout="))
    assert.is_true(vim.tbl_contains(result, "name="))
    assert.is_true(vim.tbl_contains(result, "auto_scroll="))
    assert.is_true(vim.tbl_contains(result, "bang_target="))
    assert.is_true(vim.tbl_contains(result, "persist_mode="))
    assert.is_true(vim.tbl_contains(result, "selectable="))
    assert.is_true(vim.tbl_contains(result, "start_in_insert="))
    assert.is_true(vim.tbl_contains(result, "sticky="))
    assert.is_true(vim.tbl_contains(result, "cleanup_on_success="))
    assert.is_true(vim.tbl_contains(result, "cleanup_on_failure="))
  end)

  it("completes boolean values for auto_scroll", function()
    local result = commandline.term_new_complete("auto_scroll=", "auto_scroll=", 12)

    assert.is_true(vim.tbl_contains(result, "auto_scroll=true"))
    assert.is_true(vim.tbl_contains(result, "auto_scroll=false"))
  end)

  it("completes boolean values for bang_target", function()
    local result = commandline.term_new_complete("bang_target=", "bang_target=", 12)

    assert.is_true(vim.tbl_contains(result, "bang_target=true"))
    assert.is_true(vim.tbl_contains(result, "bang_target=false"))
  end)

  it("completes boolean values for persist_mode", function()
    local result = commandline.term_new_complete("persist_mode=", "persist_mode=", 13)

    assert.is_true(vim.tbl_contains(result, "persist_mode=true"))
    assert.is_true(vim.tbl_contains(result, "persist_mode=false"))
  end)

  it("completes boolean values for selectable", function()
    local result = commandline.term_new_complete("selectable=", "selectable=", 11)

    assert.is_true(vim.tbl_contains(result, "selectable=true"))
    assert.is_true(vim.tbl_contains(result, "selectable=false"))
  end)

  it("completes boolean values for start_in_insert", function()
    local result = commandline.term_new_complete("start_in_insert=", "start_in_insert=", 16)

    assert.is_true(vim.tbl_contains(result, "start_in_insert=true"))
    assert.is_true(vim.tbl_contains(result, "start_in_insert=false"))
  end)

  it("completes boolean values for sticky", function()
    local result = commandline.term_new_complete("sticky=", "sticky=", 7)

    assert.is_true(vim.tbl_contains(result, "sticky=true"))
    assert.is_true(vim.tbl_contains(result, "sticky=false"))
  end)

  it("completes boolean values for cleanup_on_success", function()
    local result = commandline.term_new_complete("cleanup_on_success=", "cleanup_on_success=", 18)

    assert.is_true(vim.tbl_contains(result, "cleanup_on_success=true"))
    assert.is_true(vim.tbl_contains(result, "cleanup_on_success=false"))
  end)

  it("completes boolean values for cleanup_on_failure", function()
    local result = commandline.term_new_complete("cleanup_on_failure=", "cleanup_on_failure=", 18)

    assert.is_true(vim.tbl_contains(result, "cleanup_on_failure=true"))
    assert.is_true(vim.tbl_contains(result, "cleanup_on_failure=false"))
  end)
end)

describe("commandline.term_update_complete", function()
  it("completes available options", function()
    local result = commandline.term_update_complete("", "", 0)

    assert.is_true(vim.tbl_contains(result, "layout="))
    assert.is_true(vim.tbl_contains(result, "name="))
    assert.is_true(vim.tbl_contains(result, "auto_scroll="))
    assert.is_true(vim.tbl_contains(result, "bang_target="))
    assert.is_true(vim.tbl_contains(result, "persist_mode="))
    assert.is_true(vim.tbl_contains(result, "selectable="))
    assert.is_true(vim.tbl_contains(result, "start_in_insert="))
    assert.is_true(vim.tbl_contains(result, "sticky="))
    assert.is_true(vim.tbl_contains(result, "cleanup_on_success="))
    assert.is_true(vim.tbl_contains(result, "cleanup_on_failure="))
  end)
end)
