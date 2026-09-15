require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- ═══════════════════════════════════════════
-- LSP Mappings
-- ═══════════════════════════════════════════

map("n", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP Code Action" })
map("n", "<leader>lr", function()
  return ":IncRename " .. vim.fn.expand "<cword>"
end, { expr = true, desc = "LSP Rename (inc-rename)" })
map("n", "<leader>lf", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "LSP Format" })

map("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to Declaration" })
map("n", "gr", vim.lsp.buf.references, { desc = "Go to References" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
map("n", "gt", vim.lsp.buf.type_definition, { desc = "Go to Type Definition" })

map("n", "K", vim.lsp.buf.hover, { desc = "LSP Hover" })
map("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "LSP Signature Help" })

map("n", "<leader>ls", vim.lsp.buf.signature_help, { desc = "LSP Signature" })
map("n", "<leader>lI", "<cmd>LspInfo<cr>", { desc = "LSP Info" })
map("n", "<leader>lR", "<cmd>LspRestart<cr>", { desc = "LSP Restart" })

-- Diagnostics
map("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "[d", function()
  vim.diagnostic.jump { count = -1 }
end, { desc = "Prev Diagnostic" })
map("n", "]d", function()
  vim.diagnostic.jump { count = 1 }
end, { desc = "Next Diagnostic" })
map("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Diagnostic Quickfix" })

-- ═══════════════════════════════════════════
-- DAP Mappings
-- ═══════════════════════════════════════════

map("n", "<leader>db", require("dap").toggle_breakpoint, { desc = "DAP Breakpoint" })
map("n", "<leader>dd", require("dap").run_to_cursor, { desc = "DAP Run to Cursor" })
map("n", "<leader>dc", require("dap").continue, { desc = "DAP Continue" })
map("n", "<leader>dn", require("dap").step_over, { desc = "DAP Step Over" })
map("n", "<leader>di", require("dap").step_into, { desc = "DAP Step Into" })
map("n", "<leader>do", require("dap").step_out, { desc = "DAP Step Out" })
map("n", "<leader>dt", require("dap").terminate, { desc = "DAP Terminate" })
map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "DAP UI Toggle" })

-- ═══════════════════════════════════════════
-- LSP Import (quick fix)
-- ═══════════════════════════════════════════

map("n", "<leader>ai", require("lspimport").import, { desc = "Auto Import", noremap = true })
