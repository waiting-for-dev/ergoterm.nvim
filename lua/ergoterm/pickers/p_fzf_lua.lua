local terms = require("ergoterm.terminal")

local M = {}

local fzf_lua = require("fzf-lua")
local fzf_lua_builtin_previewer = require("fzf-lua.previewer.builtin")

function M.get_term_id_from_selected(selected)
  return tonumber(selected:match("(%d+)-"))
end

M.previewer = fzf_lua_builtin_previewer.buffer_or_file:extend()

function M.previewer:new(o, opts, fzf_win)
  M.previewer.super.new(self, o, opts, fzf_win)
  setmetatable(self, M.previewer)
  return self
end

function M.previewer:parse_entry(entry_str)
  local term_id = M.get_term_id_from_selected(entry_str)
  local term = terms.get(term_id)
  if term then
    local bufnr = term:get_state("bufnr")
    local name = term.name
    local layout = term:get_state("layout")

    return {
      bufnr = tonumber(bufnr),
      name = name,
      layout = layout,
      do_not_cache = true
    }
  end
end

function M.previewer:safe_buf_delete()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

  if filetype ~= terms.FILETYPE then
    M.previewer.super.safe_buf_delete(self)
  end
end

function M.previewer:populate_preview_buf(entry_str)
  local entry = self:parse_entry(entry_str)
  self:set_preview_buf(entry.bufnr)
  self.win:update_preview_title(" " .. entry.name .. " (" .. entry.layout .. ") ")
end

function M.previewer:gen_winopts()
  local winopts = {
    wrap = true,
    cursorline = false,
    number = false
  }
  return vim.tbl_extend("keep", winopts, self.winopts)
end

function M.get_options(terminals)
  local options = {}
  for _, term in pairs(terminals) do
    table.insert(options, term.id .. "-" .. term.name)
  end
  return options
end

function M.get_actions(definitions)
  local actions = {}
  for key, definition in pairs(definitions) do
    actions[key] = {
      desc = definition.desc,
      fn = function(selected)
        local id = M.get_term_id_from_selected(selected[1])
        local term = terms.get(id)
        definition.fn(term)
      end
    }
  end
  return actions
end

function M.select_actions()
  return {
    default = { fn = function(term) term:focus() end, desc = "open" },
    ["ctrl-s"] = { fn = function(term) term:focus("below") end, desc = "open-in-horizontal-split" },
    ["ctrl-v"] = { fn = function(term) term:focus("right") end, desc = "open-in-vertical-split" },
    ["ctrl-t"] = { fn = function(term) term:focus("tab") end, desc = "open-in-tab" },
    ["ctrl-f"] = { fn = function(term) term:focus("float") end, desc = "open-in-float-window" }
  }
end

function M.select(terminals, prompt, definitions)
  fzf_lua.fzf_exec(
    M.get_options(terminals),
    {
      prompt = prompt,
      actions = M.get_actions(definitions),
      previewer = M.previewer
    }
  )
end

return M
