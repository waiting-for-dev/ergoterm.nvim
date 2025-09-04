local terms = require("ergoterm.terminal")

local M = {}


function M.select(terminals, prompt, definitions)
  local pickers = require("telescope.pickers")
  local conf = require("telescope.config").values
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  -- Create a custom previewer for terminals
  local terminal_previewer = previewers.new_buffer_previewer({
    title = "Terminal Preview",
    keep_last_buf = true, -- Prevent buffer deletion

    dynamic_title = function(_, entry)
      local term = entry.value
      return " " .. term.name .. " (" .. term.layout .. ") "
    end,

    get_buffer_by_name = function(_, entry)
      local term = entry.value
      return tostring(term:get_state("bufnr"))
    end,

    define_preview = function(self, entry, status)
      local term = entry.value
      local bufnr = term:get_state("bufnr")
      local preview_winid = status.layout.preview and status.layout.preview.winid

      if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        -- Use the existing terminal buffer directly
        self.state.bufnr = bufnr
        self.state.bufname = tostring(bufnr)

        vim.schedule(function()
          if vim.api.nvim_win_is_valid(preview_winid) then
            local utils = require("telescope.utils")
            utils.win_set_buf_noautocmd(preview_winid, bufnr)
            -- Clear telescope's preview window highlighting to show terminal colors properly
            vim.api.nvim_win_set_option(preview_winid, "winhl", "")
          end
        end)
      else
        local tmp_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(tmp_buf, 0, -1, false, { "Terminal not active" })
        vim.bo[tmp_buf].bufhidden = "wipe"
        self.state.bufnr = tmp_buf
        self.state.bufname = tostring(tmp_buf)

        vim.schedule(function()
          if vim.api.nvim_win_is_valid(preview_winid) then
            local utils = require("telescope.utils")
            utils.win_set_buf_noautocmd(preview_winid, tmp_buf)
          end
        end)
      end
    end,

    -- Override teardown to prevent terminal buffer deletion
    teardown = function(self)
      -- Clear references but don't delete terminal buffers
      if self.state then
        -- Only clear if it's not a terminal buffer
        if self.state.bufnr and vim.api.nvim_buf_is_valid(self.state.bufnr) then
          local ok, filetype = pcall(vim.api.nvim_buf_get_option, self.state.bufnr, 'filetype')
          if not ok or filetype ~= terms.FILETYPE then
            -- Only clear non-terminal buffers
            self.state.bufnr = nil
            self.state.bufname = nil
          end
        end
      end
    end,
  })

  -- Create the picker
  pickers.new({}, {
    prompt_title = prompt,
    finder = finders.new_table({
      results = terminals,
      entry_maker = function(term)
        return {
          value = term,
          display = term.name,
          ordinal = term.name,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = terminal_previewer,
    attach_mappings = function(prompt_bufnr, map)
      -- Map all the actions from definitions
      for key, definition in pairs(definitions) do
        if key == "default" then
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            definition.fn(selection.value)
          end)
        else
          map("i", key, function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            definition.fn(selection.value)
          end, { desc = definition.desc })
          map("n", key, function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            definition.fn(selection.value)
          end, { desc = definition.desc })
        end
      end
      return true
    end,
  }):find()
end

return M
