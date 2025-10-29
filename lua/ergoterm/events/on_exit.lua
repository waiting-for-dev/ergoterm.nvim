---@diagnostic disable: invisible

local M = {}

---@param term Terminal
---@param job number
---@param exit_code number
---@param event string
---@param callback on_job_exit
function M.on_exit(term, job, exit_code, event, callback)
  term._state.job_id = nil
  term._state.last_exit_code = exit_code

  M._maybe_show(term, exit_code)
  M._maybe_cleanup(term, exit_code)


  callback(term, job, exit_code, event)
end

function M._maybe_show(term, exit_code)
  if (exit_code == 0 and term.show_on_success) or
      (exit_code ~= 0 and term.show_on_failure) then
    vim.schedule(function()
      term:_show()
    end)
  end
end

function M._maybe_cleanup(term, exit_code)
  if (exit_code == 0 and term.cleanup_on_success) or
      (exit_code ~= 0 and term.cleanup_on_failure) then
    vim.schedule(function()
      term:cleanup()
    end)
  end
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.on_exit(...)
  end
})
