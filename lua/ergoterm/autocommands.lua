---@module "ergoterm.lazy"
local lazy = require("ergoterm.lazy")

---@module "ergoterm.terminal"
local terms = lazy.require("ergoterm.terminal")

local AUGROUP = "ErgoTermAutoCommands"

local M = {}

function M.on_buf_enter()
  local term = terms.identify()
  term:on_buf_enter()
end


function M.on_win_leave()
  local term = terms.identify()
  term:on_win_leave()
end

function M.on_filetype(ev)
  local bufnr = ev.buf
  vim.api.nvim_buf_set_option(bufnr, "foldmethod", "manual")
  vim.api.nvim_buf_set_option(bufnr, "foldtext", "foldtext()")
end

-- Setup autocommands for the plugin.
function M.setup()
  vim.api.nvim_create_augroup(AUGROUP, { clear = true })
  local ergoterm_pattern = { "term://*#ergoterm#*", "term://*::ergoterm::*" }

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

  vim.api.nvim_create_autocmd("FileType", {
    group = AUGROUP,
    pattern = ergoterm_pattern,
    callback = M.on_filetype
  })
end

return M
