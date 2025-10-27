---@diagnostic disable: invisible

local M = {}

---@param term Terminal
function M.stop(term)
  if term:is_started() then
    term:close()
    vim.fn.jobstop(term._state.job_id)
    term:on_stop()
  end
  return term
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.stop(...)
  end
})
