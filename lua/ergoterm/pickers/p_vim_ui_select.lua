local M = {}


function M.select(terminals, prompt, callbacks)
  vim.ui.select(terminals, {
    prompt = prompt,
    format_item = function(term) return term.id .. ": " .. term.name end,
  }, function(term)
    callbacks.default.fn(term)
  end)
end

return M
