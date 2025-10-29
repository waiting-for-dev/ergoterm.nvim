---@diagnostic disable: invisible

local M = {}

---@param term Terminal
---@param channel_id number
---@param data table
---@param name string
---@param callback on_job_stdout | on_job_stderr
function M.on_output(term, channel_id, data, name, callback)
  if term.auto_scroll then term:_scroll_bottom() end
  if term.watch_files then
    vim.schedule(function()
      vim.cmd('checktime')
    end)
  end
  callback(term, channel_id, data, name)
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.on_output(...)
  end
})
