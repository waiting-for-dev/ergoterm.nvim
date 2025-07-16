local M = {}

function M.select_actions()
  return {
    default = { fn = function(term) term:focus() end, desc = "" },
  }
end

function M.select(terminals, prompt, callbacks)
  vim.ui.select(terminals, {
    prompt = prompt,
    format_item = function(term) return term.id .. ": " .. term.name end,
  }, function(term)
    callbacks.default(term)
  end)
end

return M
