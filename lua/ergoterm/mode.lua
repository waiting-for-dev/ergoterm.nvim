---@alias Mode "n" | "i" | "?"

local M = {}

M.INSERT = "i"
M.NORMAL = "n"

function M.get()
  local raw_mode = vim.api.nvim_get_mode().mode
  if raw_mode:match("nt") then
    return M.NORMAL
  elseif raw_mode:match("t") then
    return M.INSERT
  end
end

function M.get_initial(start_in_insert)
  if start_in_insert then
    return M.INSERT
  else
    return M.NORMAL
  end
end

function M.set_initial(start_in_insert)
  M.set(M.get_initial(start_in_insert))
end

function M.set(mode)
  if mode == M.INSERT then
    vim.defer_fn(function() vim.cmd("startinsert") end, 100)
  elseif mode == M.NORMAL then
    vim.defer_fn(function() vim.cmd("stopinsert") end, 100)
  end
end

return M
