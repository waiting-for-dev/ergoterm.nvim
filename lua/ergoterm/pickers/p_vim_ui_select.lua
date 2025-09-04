local M = {}


function M.select(terminals, prompt, callbacks)
  vim.ui.select(terminals, {
    prompt = prompt,
    format_item = function(term)
      local status_icon = term:get_status_icon()
      return status_icon .. " " .. term.name
    end,
  }, function(term)
    callbacks.default.fn(term)
  end)
end

return M
