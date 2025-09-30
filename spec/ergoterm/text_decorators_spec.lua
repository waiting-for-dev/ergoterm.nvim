local decorators = require("ergoterm.text_decorators")

---@diagnostic disable: undefined-field

describe("text_decorators", function()
  describe(".identity", function()
    it("returns text unchanged", function()
      local input = { "line1", "line2", "" }

      local result = decorators.identity(input)

      assert.same(input, result)
    end)

    it("handles empty input", function()
      local input = {}

      local result = decorators.identity(input)

      assert.same({}, result)
    end)
  end)

  describe(".markdown_code", function()
    local original_bo

    before_each(function()
      original_bo = vim.bo
      vim.bo = { filetype = "lua" }
    end)

    after_each(function()
      vim.bo = original_bo
    end)

    it("wraps text in markdown code block with current filetype", function()
      local input = { "local x = 1", "print(x)" }

      local result = decorators.markdown_code(input)

      assert.same({
        "```lua",
        "local x = 1",
        "print(x)",
        "```",
        ""
      }, result)
    end)

    it("handles empty input", function()
      local input = {}

      local result = decorators.markdown_code(input)

      assert.same({
        "```lua",
        "```",
        ""
      }, result)
    end)

    it("preserves empty lines in the middle but skips trailing empty line", function()
      local input = { "local x = 1", "", "print(x)", "" }

      local result = decorators.markdown_code(input)

      assert.same({
        "```lua",
        "local x = 1",
        "",
        "print(x)",
        "```",
        ""
      }, result)
    end)

    it("uses current buffer filetype", function()
      vim.bo.filetype = "python"
      local input = { "x = 1", "print(x)" }

      local result = decorators.markdown_code(input)

      assert.same({
        "```python",
        "x = 1",
        "print(x)",
        "```",
        ""
      }, result)
    end)

    it("handles empty filetype", function()
      vim.bo.filetype = ""
      local input = { "some text" }

      local result = decorators.markdown_code(input)

      assert.same({
        "```",
        "some text",
        "```",
        ""
      }, result)
    end)
  end)

  describe(".prompt", function()
    it("adds prefix and empty line before text", function()
      local decorator = decorators.prompt(">>> ")
      local input = { "line1", "line2" }

      local result = decorator(input)

      assert.same({
        ">>> ",
        "",
        "line1",
        "line2"
      }, result)
    end)

    it("handles empty input", function()
      local decorator = decorators.prompt(">>> ")
      local input = {}

      local result = decorator(input)

      assert.same({}, result)
    end)
  end)
end)
