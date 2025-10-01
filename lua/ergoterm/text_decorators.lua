---Text decorators for terminal input

local M = {}

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
  local lines_to_add = text
  if #text > 0 and text[#text] == "" then
    lines_to_add = vim.list_slice(text, 1, #text - 1)
  end
  local result = { "```" .. filetype }
  vim.list_extend(result, lines_to_add)
  vim.list_extend(result, { "```", "" })
  return result
end

---Returns a function that prepends a prefix and an empty line to the text
---
---@param prefix string The prefix to prepend
---@return fun(text: string[]): string[]
function M.prompt(prefix)
  return function(text)
    if #text == 0 then return text end
    return vim.list_extend({ prefix, "" }, text)
  end
end

return M
