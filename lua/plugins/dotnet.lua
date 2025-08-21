return {
  {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim", -- AstroNvim đã tích hợp Telescope
    },
    config = function()
      require("easy-dotnet").setup {
        -- Không cung cấp get_sdk_path, plugin sẽ tự động tìm SDK
        test_runner = {
          viewmode = "float", -- Hoặc "split", "vsplit", "buf"
          enable_buffer_test_execution = true,
          noBuild = true,
          icons = {
            sln = "󰘐",
            project = "󰘐",
            dir = "📁",
            package = "📦",
            passed = "✅",
            skipped = "⏭️",
            failed = "❌",
            success = "🎉",
            reload = "🔄",
            test = "🧪",
          },
          mappings = {
            run_test_from_buffer = { lhs = "<leader>rt", desc = "Run test from buffer" },
            filter_failed_tests = { lhs = "<leader>tf", desc = "Filter failed tests" },
            debug_test = { lhs = "<leader>td", desc = "Debug test" },
            go_to_file = { lhs = "gf", desc = "Go to file" },
            run_all = { lhs = "<leader>tR", desc = "Run all tests" },
            run = { lhs = "<leader>tr", desc = "Run test" },
            peek_stacktrace = { lhs = "<leader>tp", desc = "Peek stacktrace" },
            expand = { lhs = "o", desc = "Expand" },
            expand_node = { lhs = "E", desc = "Expand node" },
            expand_all = { lhs = "-", desc = "Expand all" },
            collapse_all = { lhs = "W", desc = "Collapse all" },
            close = { lhs = "q", desc = "Close testrunner" },
            refresh_testrunner = { lhs = "<C-r>", desc = "Refresh testrunner" },
          },
          additional_args = {},
        },
        new = {
          project = {
            prefix = "sln",
          },
        },
        terminal = function(path, action, args)
          local commands = {
            run = string.format("dotnet run --project %s %s", path, args),
            test = string.format("dotnet test %s %s", path, args),
            restore = string.format("dotnet restore %s %s", path, args),
            build = string.format("dotnet build %s %s", path, args),
            watch = string.format("dotnet watch --project %s %s", path, args),
          }
          local command = commands[action]() .. "\r"
          vim.cmd("vsplit | term " .. command)
        end,
        secrets = {
          path = function(secret_guid)
            local home_dir = vim.fn.expand "~"
            return home_dir .. "/.microsoft/usersecrets/" .. secret_guid .. "/secrets.json"
          end,
        },
        csproj_mappings = true,
        fsproj_mappings = true,
        auto_bootstrap_namespace = {
          type = "block_scoped",
          enabled = true,
        },
        picker = "telescope", -- AstroNvim dùng Telescope mặc định
        background_scanning = true,
        notifications = {
          handler = function(start_event)
            local spinner = require("easy-dotnet.ui-modules.spinner").new()
            spinner:start_spinner(start_event.job.name)
            return function(finished_event)
              spinner:stop_spinner(finished_event.result.text, finished_event.result.level)
            end
          end,
        },
      }
    end,
  },
}
