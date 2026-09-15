require("nvchad.configs.lspconfig").defaults()

vim.lsp.config("clangd", {
  root_markers = { ".clang-format", "compile_commands.json" },
  cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed" },
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
        },
      },
    },
  },
})

local servers = { "html", "cssls", "ols", "lua_ls", "clangd", "ts_ls" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers

vim.diagnostic.config {
  virtual_text = { prefix = "●", spacing = 4 },
  signs = true,
  underline = true,
  float = { border = "rounded", source = true },
}
