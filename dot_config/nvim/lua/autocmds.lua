require "nvchad.autocmds"

-- Day/night theme sync: ~/.local/bin/theme writes ~/.config/terminal-theme.
-- Running nvim instances pick the change up when they regain focus.
local nvim_theme_for = { light = "onenord_light", dark = "nord" }
local last_theme_mode = nil

local function sync_terminal_theme()
  local ok, lines = pcall(vim.fn.readfile, vim.fn.expand "~/.config/terminal-theme")
  if not ok or not lines[1] then
    return
  end

  local mode = lines[1] == "light" and "light" or "dark"
  if mode == last_theme_mode then
    return
  end

  vim.o.background = mode
  -- skip the reload on first run: chadrc already applied the right theme
  if last_theme_mode ~= nil then
    pcall(function()
      require("nvchad.themes.utils").reload_theme(nvim_theme_for[mode])
    end)
  end
  last_theme_mode = mode
end

vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter", "FocusGained", "VimResume" }, {
  callback = sync_terminal_theme,
})
