local M = {}

---@alias error_types 'error' | 'info' | 'warn'

---@param msg string
---@param level error_types
function M.notify(msg, level)
  local computed_level = level:upper()
  vim.schedule(function() vim.notify(msg, vim.log.levels[computed_level], { title = "Ergoterm" }) end)
end

---@return string?
function M.git_dir()
  local gitdir = vim.fn.system(string.format("git -C %s rev-parse --show-toplevel", vim.fn.expand("%:p:h")))
  local isgitdir = vim.fn.matchstr(gitdir, "^fatal:.*") == ""
  if isgitdir then
    return vim.trim(gitdir)
  else
    M.notify("Not a valid git directory", "error")
  end
end

---@param str string?
---@return boolean
function M.str_is_empty(str)
  return str == nil or str == ""
end

---@param tbl table
---@return table
function M.tbl_filter_empty(tbl)
  return vim.tbl_filter(
    function(str) return not M.str_is_empty(str) end,
    tbl
  )
end

---@return boolean
function M.is_windows()
  return vim.fn.has("win32") == 1
end

---@param dir string?
---@return string?
function M.get_dir(dir)
  local parsed_dir = nil
  if dir == "git_dir" then
    parsed_dir = M.git_dir()
  elseif dir == nil then
    parsed_dir = vim.loop.cwd()
  else
    parsed_dir = vim.fn.expand(dir)
    if vim.fn.isdirectory(parsed_dir) == 0 then
      M.notify(
        string.format("%s is not a directory", parsed_dir),
        "error"
      )
    end
  end
  return parsed_dir
end

return M
