local M = {}

function M.is_percentage(value)
  return type(value) == "string" and value:match("%%$") ~= nil
end

function M.is_vertical(layout)
  return layout == "left" or layout == "right"
end

function M.percentage_to_absolute(percentage_str, layout)
  local percentage = tonumber(percentage_str:match("(%d+)%%"))
  if M.is_vertical(layout) then
    return math.ceil(vim.o.columns * percentage / 100)
  else
    return math.ceil(vim.o.lines * percentage / 100)
  end
end

function M.absolute_to_percentage(size, layout)
  local percentage
  if M.is_vertical(layout) then
    percentage = math.floor((size / vim.o.columns) * 100 + 0.5)
  else
    percentage = math.floor((size / vim.o.lines) * 100 + 0.5)
  end
  return string.format("%d%%", percentage)
end

return M
