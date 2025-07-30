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
  if entry.bufnr then
    self:set_preview_buf(entry.bufnr)
  end
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
    local transformed_key = M._transform_key_for_fzf(key)
    local transformed_desc = M._transform_description(definition.desc)
    actions[transformed_key] = {
      desc = transformed_desc,
      fn = function(selected)
        local id = M.get_term_id_from_selected(selected[1])
        local term = terms.get(id)
        definition.fn(term)
      end
    }
  end
  return actions
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

-- Transform Vim-style key notation to fzf-lua format
-- <C-s> -> ctrl-s, <M-s> -> alt-s, <S-F1> -> shift-f1, etc.
function M._transform_key_for_fzf(key)
  -- Handle Control keys: <C-s> -> ctrl-s
  if key:match("^<C%-(.+)>$") then
    local char = key:match("^<C%-(.+)>$")
    return "ctrl-" .. char:lower()
  end

  -- Handle Meta/Alt keys: <M-s> -> alt-s, <A-s> -> alt-s
  if key:match("^<[MA]%-(.+)>$") then
    local char = key:match("^<[MA]%-(.+)>$")
    return "alt-" .. char:lower()
  end

  -- Handle Shift keys: <S-F1> -> shift-f1
  if key:match("^<S%-(.+)>$") then
    local char = key:match("^<S%-(.+)>$")
    return "shift-" .. char:lower()
  end

  -- Handle function keys: <F1> -> f1, <F12> -> f12
  if key:match("^<F(%d+)>$") then
    local num = key:match("^<F(%d+)>$")
    return "f" .. num
  end

  -- Handle special keys: <Tab> -> tab, <Space> -> space, <Enter> -> enter
  local special_keys = {
    ["<Tab>"] = "tab",
    ["<Space>"] = "space",
    ["<Enter>"] = "enter",
    ["<Return>"] = "enter",
    ["<CR>"] = "enter",
    ["<Esc>"] = "esc",
    ["<BS>"] = "bs",
    ["<Backspace>"] = "bs",
    ["<Del>"] = "del",
    ["<Delete>"] = "del",
    ["<Home>"] = "home",
    ["<End>"] = "end",
    ["<PageUp>"] = "page-up",
    ["<PageDown>"] = "page-down",
    ["<Up>"] = "up",
    ["<Down>"] = "down",
    ["<Left>"] = "left",
    ["<Right>"] = "right"
  }

  if special_keys[key] then
    return special_keys[key]
  end

  -- Handle combination keys: <C-S-f> -> ctrl-shift-f, <M-C-s> -> alt-ctrl-s
  if key:match("^<.*>$") then
    local inner = key:match("^<(.*)>$")
    local parts = {}

    -- Split by hyphens and process each modifier
    for part in inner:gmatch("[^%-]+") do
      if part == "C" then
        table.insert(parts, "ctrl")
      elseif part == "M" or part == "A" then
        table.insert(parts, "alt")
      elseif part == "S" then
        table.insert(parts, "shift")
      else
        -- This is the actual key
        table.insert(parts, part:lower())
      end
    end

    if #parts > 1 then
      return table.concat(parts, "-")
    end
  end

  -- Return unchanged if no transformation needed
  return key
end

function M._transform_description(description)
  return description:lower():gsub("%s+", "-")
end

return M
