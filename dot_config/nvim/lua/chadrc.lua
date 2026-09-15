-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

-- Day/night theme sync: ~/.local/bin/theme writes ~/.config/terminal-theme
-- Running instances live-switch via the autocmd in lua/autocmds.lua
local function terminal_mode()
  local f = io.open(vim.fn.expand "~/.config/terminal-theme", "r")
  if not f then
    return "dark"
  end
  local t = f:read "*l"
  f:close()
  return t == "light" and "light" or "dark"
end

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = terminal_mode() == "light" and "onenord_light" or "nord",

  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}

M.nvdash = { load_on_startup = true }
M.ui = {
  tabufline = {
    lazyload = false,
  },
}

return M
