local M = {}

function M.check()
  vim.health.start("ErgoTerm")

  local has_fzf_lua = pcall(require, "fzf-lua")
  local has_telescope = pcall(require, "telescope")

  if has_fzf_lua then
    vim.health.ok("fzf-lua is available")
  end

  if has_telescope then
    vim.health.ok("telescope is available")
  end

  if not has_fzf_lua and not has_telescope then
    vim.health.warn("No advanced pickers found", {
      "Install fzf-lua or telescope for better terminal selection",
      "Falling back to vim.ui.select"
    })
  end

  local config_ok, config = pcall(require, "ergoterm.config")
  if config_ok then
    vim.health.ok("Configuration module loaded successfully")

    local picker = config.get("picker.picker")
    if picker then
      if type(picker) == "string" then
        vim.health.ok("Picker configured: " .. picker)

        if picker == "fzf-lua" and not has_fzf_lua then
          vim.health.error("Picker set to 'fzf-lua' but fzf-lua is not available", {
            "Install fzf-lua or change picker in configuration"
          })
        elseif picker == "telescope" and not has_telescope then
          vim.health.error("Picker set to 'telescope' but telescope is not available", {
            "Install telescope or change picker in configuration"
          })
        elseif picker == "vim-ui-select" then
          vim.health.ok("Using vim.ui.select picker (always available)")
        end
      else
        vim.health.ok("Custom picker object configured")
      end
    else
      vim.health.warn("No picker explicitly configured", {
        "ErgoTerm will auto-detect available picker"
      })
    end
  else
    vim.health.error("Failed to load configuration module", {
      "Check for syntax errors in ergoterm configuration"
    })
  end

  local main_ok, _ = pcall(require, "ergoterm")
  if main_ok then
    vim.health.ok("ErgoTerm main module loaded successfully")
  else
    vim.health.error("Failed to load main ErgoTerm module", {
      "Check plugin installation and configuration"
    })
  end
end

return M
