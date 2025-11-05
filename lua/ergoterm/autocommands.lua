local AUGROUP = "ErgoTermAutoCommands"

local M = {}

function M.on_buf_enter()
  local term = require("ergoterm").identify()
  if term then
    term:on_buf_enter()
  end
end

function M.on_win_leave()
  local term = require("ergoterm").identify()
  if term then
    term:on_win_leave()
  end
end

-- Setup autocommands for the plugin.
function M.setup()
  vim.api.nvim_create_augroup(AUGROUP, { clear = true })
  local ergoterm_pattern = { "term://*" }

  vim.api.nvim_create_autocmd("BufEnter", {
    group = AUGROUP,
    pattern = ergoterm_pattern,
    nested = true, -- this is necessary in case the buffer is the last
    callback = M.on_buf_enter
  })

  vim.api.nvim_create_autocmd("WinLeave", {
    group = AUGROUP,
    pattern = ergoterm_pattern,
    callback = M.on_win_leave
  })
end

return M
