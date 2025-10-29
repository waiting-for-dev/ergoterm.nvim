---@diagnostic disable: invisible

local M = {}

local WINDOW_LAYOUTS = { "float", "above", "below", "left", "right" }

---@param term Terminal
function M.on_vim_resized(term)
  if vim.tbl_contains(WINDOW_LAYOUTS, term._state.layout) and term:is_open() then
    vim.api.nvim_win_set_config(term._state.window, term:_compute_win_config(term._state.layout))
  end
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.on_vim_resized(...)
  end
})
