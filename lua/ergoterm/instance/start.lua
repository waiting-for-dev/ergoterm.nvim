---@diagnostic disable: invisible

---@module "ergoterm.events.on_win_closed"
local on_win_closed = require("ergoterm.events.on_win_closed")

local FILETYPE = "ergoterm"

local M = {}

---@param term Terminal
---
---@return Terminal
function M.start(term)
  if not M.is_started(term) then
    term._state.dir = term:_compute_dir()
    term._state.bufnr = vim.api.nvim_create_buf(false, false)
    term._state.has_been_started = true
    vim.api.nvim_buf_call(term._state.bufnr, function()
      term._state.job_id = M._start_job(term)
    end)
    M._setup_buffer_autocommands(term)
    M._set_buffer_options(term)
    term:on_start()
  end
  return term
end

---@param term Terminal
function M.is_started(term)
  return term._state.job_id ~= nil
end

---@private
---@param term Terminal
function M._setup_buffer_autocommands(term)
  local group = vim.api.nvim_create_augroup("ErgoTermBuffer", { clear = true })
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = term._state.bufnr,
    group = group,
    callback = function() term:on_vim_resized() end
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = term._state.bufnr,
    group = group,
    callback = function() term:cleanup() end
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = term._state.bufnr,
    group = group,
    callback = function() on_win_closed(term) end
  })
end

---@private
---@param term Terminal
function M._start_job(term)
  return vim.fn.termopen(term.cmd, {
    detach = 1,
    cwd = term._state.dir,
    on_exit = term._state.on_job_exit,
    on_stdout = term._state.on_job_stdout,
    on_stderr = term._state.on_job_stderr,
    env = term.env,
    clear_env = term.clear_env,
  })
end

---@private
---@param term Terminal
function M._set_buffer_options(term)
  local bufnr = term._state.bufnr
  vim.api.nvim_set_option_value("filetype", FILETYPE, { scope = "local", buf = bufnr })
  vim.api.nvim_set_option_value("buflisted", false, { scope = "local", buf = bufnr })
  vim.api.nvim_set_option_value("bufhidden", "hide", { scope = "local", buf = bufnr })
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.start(...)
  end
})
