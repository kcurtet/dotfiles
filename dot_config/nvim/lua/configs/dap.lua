local dap = require "dap"
local mason_data = vim.fn.stdpath "data" .. "/mason/packages/js-debug-adapter"

require("dapui").setup {
  controls = {
    element = "repl", -- añade esto
    enabled = true,
  },
}

-- C/C++
dap.adapters.codelldb = {
  type = "executable",
  command = "codelldb", -- or if not in $PATH: "/absolute/path/to/codelldb"

  -- On windows you may have to uncomment this:
  -- detached = false,
}

dap.configurations.c = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {}, -- pass CLI args here if needed: { "arg1", "arg2" }
  },
  {
    name = "Attach to process",
    type = "codelldb",
    request = "attach",
    pid = require("dap.utils").pick_process,
    cwd = "${workspaceFolder}",
  },
}

dap.configurations.cpp = {
  {
    name = "Launch",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/build/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}

-- Un solo adapter para todo
dap.adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "9229",
  executable = {
    command = "node",
    args = { mason_data .. "/js-debug/src/dapDebugServer.js", "9229" },
  },
}

dap.adapters["pwa-chrome"] = {
  type = "server",
  host = "localhost",
  port = "9222",
  executable = {
    command = "node",
    args = { mason_data .. "/js-debug/src/dapDebugServer.js", "9222" },
  },
}

dap.listeners.after.event_initialized["debug"] = function(session)
  print("DAP initialized: " .. vim.inspect(session.config))
end

dap.listeners.after.event_stopped["debug"] = function(session, body)
  print("DAP stopped: " .. vim.inspect(body))
end

dap.listeners.after.event_terminated["debug"] = function()
  print "DAP terminated"
end

dap.configurations.javascript = {
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch file (Node)",
    function()
      return vim.fn.input("Entry point: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = true,
    console = "integratedTerminal",
    sourceMaps = true,
    -- outputCapture = "std",
    -- runtimeExecutable = "node",
  },
  {
    type = "pwa-node",
    request = "attach",
    name = "Attach to Node process",
    processId = require("dap.utils").pick_process,
    cwd = "${workspaceFolder}",
  },
  {
    type = "pwa-chrome",
    request = "launch",
    name = "Launch Chrome",
    url = "http://localhost:3000",
    webRoot = "${workspaceFolder}",
    sourceMaps = true,
  },
}

dap.configurations.typescript = dap.configurations.javascript
