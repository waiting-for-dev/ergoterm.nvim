---@diagnostic disable: undefined-field

local collection = require("ergoterm.collection")
local commandline = require("ergoterm.commandline")
local terms = require("ergoterm")

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

  it("parses list values", function()
    local args = "tags=dev,prod,test"

    local result = commandline.parse(args)

    assert.is_table(result.tags)
    assert.equal(3, #result.tags)
    assert.equal("dev", result.tags[1])
    assert.equal("prod", result.tags[2])
    assert.equal("test", result.tags[3])
  end)

  it("parses list values with a single item", function()
    local args = "tags=dev"

    local result = commandline.parse(args)

    assert.is_table(result.tags)
    assert.equal(1, #result.tags)
  end)

  it("parses table values", function()
    local args = "size.below=20% size.above=10%"

    local result = commandline.parse(args)

    assert.is_table(result.size)
    assert.equal("20%", result.size.below)
    assert.equal("10%", result.size.above)
  end)

  it("parses table values with numeric values", function()
    local args = "size.below=20 size.above=10"

    local result = commandline.parse(args)

    assert.is_table(result.size)
    assert.equal(20, result.size.below)
    assert.equal(10, result.size.above)
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

    assert.is_true(vim.tbl_contains(result, "target="))
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

    assert.is_true(vim.tbl_contains(result, "action=focus"))
    assert.is_true(vim.tbl_contains(result, "action=open"))
    assert.is_true(vim.tbl_contains(result, "action=start"))
  end)

  it("completes decorator values", function()
    local result = commandline.term_send_complete("decorator=", "decorator=", 10)

    assert.is_true(vim.tbl_contains(result, "decorator=identity"))
    assert.is_true(vim.tbl_contains(result, "decorator=markdown_code"))
  end)

  it("completes partial option names", function()
    local result = commandline.term_send_complete("act", "act", 3)

    assert.is_true(vim.tbl_contains(result, "action="))
    assert.is_false(vim.tbl_contains(result, "text="))
    assert.is_false(vim.tbl_contains(result, "trim="))
  end)

  it("completes target with terminal names", function()
    terms.Terminal:new({ name = "term1" })
    terms.Terminal:new({ name = "term2" })

    local result = commandline.term_send_complete("target=", "target=", 7)

    assert.is_true(vim.tbl_contains(result, "target=term1"))
    assert.is_true(vim.tbl_contains(result, "target=term2"))

    collection.cleanup_all()
    collection.reset_ids()
  end)

  it("completes target with partial terminal names", function()
    terms.Terminal:new({ name = "term1" })
    terms.Terminal:new({ name = "term2" })
    terms.Terminal:new({ name = "other" })

    local result = commandline.term_send_complete("target=term", "target=term", 11)

    assert.is_true(vim.tbl_contains(result, "target=term1"))
    assert.is_true(vim.tbl_contains(result, "target=term2"))
    assert.is_false(vim.tbl_contains(result, "target=other"))

    collection.cleanup_all()
    collection.reset_ids()
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
    assert.is_true(vim.tbl_contains(result, "persist_size="))
    assert.is_true(vim.tbl_contains(result, "auto_list="))
    assert.is_true(vim.tbl_contains(result, "start_in_insert="))
    assert.is_true(vim.tbl_contains(result, "sticky="))
    assert.is_true(vim.tbl_contains(result, "cleanup_on_success="))
    assert.is_true(vim.tbl_contains(result, "cleanup_on_failure="))
    assert.is_true(vim.tbl_contains(result, "size.below="))
    assert.is_true(vim.tbl_contains(result, "size.above="))
    assert.is_true(vim.tbl_contains(result, "size.left="))
    assert.is_true(vim.tbl_contains(result, "size.right="))
    assert.is_true(vim.tbl_contains(result, "float_opts.border="))
    assert.is_true(vim.tbl_contains(result, "float_opts.width="))
    assert.is_true(vim.tbl_contains(result, "float_opts.height="))
    assert.is_true(vim.tbl_contains(result, "float_opts.title="))
    assert.is_true(vim.tbl_contains(result, "tags="))
    assert.is_true(vim.tbl_contains(result, "meta.="))
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

  it("completes boolean values for persist_size", function()
    local result = commandline.term_new_complete("persist_size=", "persist_size=", 13)

    assert.is_true(vim.tbl_contains(result, "persist_size=true"))
    assert.is_true(vim.tbl_contains(result, "persist_size=false"))
  end)

  it("completes boolean values for auto_list", function()
    local result = commandline.term_new_complete("auto_list=", "auto_list=", 11)

    assert.is_true(vim.tbl_contains(result, "auto_list=true"))
    assert.is_true(vim.tbl_contains(result, "auto_list=false"))
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

  it("completes values for float_opts.title_pos", function()
    local result = commandline.term_new_complete("float_opts.title_pos=", "float_opts.title_pos=", 20)

    assert.is_true(vim.tbl_contains(result, "float_opts.title_pos=left"))
    assert.is_true(vim.tbl_contains(result, "float_opts.title_pos=center"))
    assert.is_true(vim.tbl_contains(result, "float_opts.title_pos=right"))
  end)

  it("completes values for float_opts.border", function()
    local result = commandline.term_new_complete("float_opts.border=", "float_opts.border=", 18)

    assert.is_true(vim.tbl_contains(result, "float_opts.border=none"))
    assert.is_true(vim.tbl_contains(result, "float_opts.border=single"))
    assert.is_true(vim.tbl_contains(result, "float_opts.border=double"))
    assert.is_true(vim.tbl_contains(result, "float_opts.border=rounded"))
    assert.is_true(vim.tbl_contains(result, "float_opts.border=solid"))
    assert.is_true(vim.tbl_contains(result, "float_opts.border=shadow"))
  end)

  it("completes values for float_opts.relative", function()
    local result = commandline.term_new_complete("float_opts.relative=", "float_opts.relative=", 20)

    assert.is_true(vim.tbl_contains(result, "float_opts.relative=editor"))
    assert.is_true(vim.tbl_contains(result, "float_opts.relative=win"))
    assert.is_true(vim.tbl_contains(result, "float_opts.relative=cursor"))
    assert.is_true(vim.tbl_contains(result, "float_opts.relative=mouse"))
    assert.is_true(vim.tbl_contains(result, "float_opts.relative=laststatus"))
    assert.is_true(vim.tbl_contains(result, "float_opts.relative=tabline"))
  end)
end)

describe("commandline.term_update_complete", function()
  it("completes available options", function()
    local result = commandline.term_update_complete("", "", 0)

    assert.is_true(vim.tbl_contains(result, "target="))
    assert.is_true(vim.tbl_contains(result, "layout="))
    assert.is_true(vim.tbl_contains(result, "name="))
    assert.is_true(vim.tbl_contains(result, "auto_scroll="))
    assert.is_true(vim.tbl_contains(result, "bang_target="))
    assert.is_true(vim.tbl_contains(result, "persist_mode="))
    assert.is_true(vim.tbl_contains(result, "persist_size="))
    assert.is_true(vim.tbl_contains(result, "auto_list="))
    assert.is_true(vim.tbl_contains(result, "start_in_insert="))
    assert.is_true(vim.tbl_contains(result, "sticky="))
    assert.is_true(vim.tbl_contains(result, "cleanup_on_success="))
    assert.is_true(vim.tbl_contains(result, "cleanup_on_failure="))
    assert.is_true(vim.tbl_contains(result, "show_on_success="))
    assert.is_true(vim.tbl_contains(result, "show_on_failure="))
    assert.is_true(vim.tbl_contains(result, "size.below="))
    assert.is_true(vim.tbl_contains(result, "size.above="))
    assert.is_true(vim.tbl_contains(result, "size.left="))
    assert.is_true(vim.tbl_contains(result, "size.right="))
    assert.is_true(vim.tbl_contains(result, "float_opts.border="))
    assert.is_true(vim.tbl_contains(result, "float_opts.width="))
    assert.is_true(vim.tbl_contains(result, "float_opts.height="))
    assert.is_true(vim.tbl_contains(result, "float_opts.title="))
    assert.is_true(vim.tbl_contains(result, "tags="))
    assert.is_true(vim.tbl_contains(result, "meta.="))
  end)
end)

describe("commandline.term_inspect_complete", function()
  it("completes available options", function()
    local result = commandline.term_inspect_complete("", "", 0)

    assert.is_true(vim.tbl_contains(result, "target="))
  end)

  it("completes target with terminal names", function()
    local terms = require("ergoterm")
    local collection = require("ergoterm.collection")
    collection.reset_ids()
    collection._state.terminals = {}

    terms.Terminal:new({ name = "inspect-term1" })
    terms.Terminal:new({ name = "inspect-term2" })

    local result = commandline.term_inspect_complete("target=", "target=", 7)

    assert.is_true(vim.tbl_contains(result, "target=inspect-term1"))
    assert.is_true(vim.tbl_contains(result, "target=inspect-term2"))
  end)
end)
