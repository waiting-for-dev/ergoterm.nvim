---Text decorators for terminal input

local M = {}

---Available decorator types
M.DECORATORS = {
  IDENTITY = "identity",
  MARKDOWN_CODE = "markdown_code"
}

---Identity decorator that returns text unchanged
---
---@param text string[]
---@return string[]
function M.identity(text)
  return text
end

---Wraps text in markdown code block with current buffer's filetype
---
---@param text string[]
---@return string[]
function M.markdown_code(text)
  local filetype = vim.bo.filetype
  local result = { "```" .. filetype }
  local lines_to_add = text
  if #text > 0 and text[#text] == "" then
    lines_to_add = vim.list_slice(text, 1, #text - 1)
  end
  for _, line in ipairs(lines_to_add) do
    table.insert(result, line)
  end
  table.insert(result, "```")
  table.insert(result, "")

  return result
end

return M
