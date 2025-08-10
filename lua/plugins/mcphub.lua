---@type LazySpec
return {
  "ravitemer/mcphub.nvim",
  optional = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "Joakker/lua-json5",
  },
  build = "yarn global add mcp-hub@latest",
  opts = {
    port = 9001,
    cmd = os.getenv "HOME" .. "/.yarn/bin/mcp-hub",
    config = vim.fn.expand "~/.vscode/mcp.json",
    -- json_decode = require("json5").parse,
    global_env = {
      -- Array-style: uses os.getenv("VAR")
      "DBUS_SESSION_BUS_ADDRESS",
      -- Hash-style: explicit value
      "GITHUB_PERSONAL_ACCESS_TOKEN",
      "GEMINI_API_KEY",
    },
    auto_approve = function(params)
      -- Auto-approve GitHub issue reading
      if params.server_name == "github" and params.tool_name == "get_issue" then
        return true -- Auto approve
      end

      -- Block access to private repos
      if params.arguments.repo == "private" then
        return "You can't access my private repo" -- Error message
      end

      -- Auto-approve safe file operations in current project
      if
        params.tool_name == "read_file"
        or params.tool_name == "find_files"
        or params.tool_name == "list_directory"
      then
        local path = params.arguments.path or ""
        if path:match("^" .. vim.fn.getcwd()) then
          return true -- Auto approve
        end
      end

      if params.tool_name == "read_multiple_files" then
        local paths = params.arguments.paths or {}
        for _, path in ipairs(paths) do
          if path:match("^" .. vim.fn.getcwd()) then
            return true -- Auto approve
          end
        end
      end

      -- Block access to sudo commands
      if params.tool_name == "execute_command" then
        if params.command:match("^" .. "sudo") then return "You can't use sudo" end
      end

      -- Check if tool is configured for auto-approval in servers.json
      if params.is_auto_approved_in_server then
        return true -- Respect servers.json configuration
      end

      return false -- Show confirmation prompt
    end,
    log = {
      level = vim.log.levels.WARN,
      to_file = false,
      file_path = nil,
      prefix = "MCPHub",
    },
  },
}
