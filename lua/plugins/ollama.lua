-- ~/.config/nvim/lua/plugins/simple-ai.lua

return {
  {
    "David-Kunz/gen.nvim",
    lazy = false,
    config = function()
      local gen = require "gen"

      -- Simple setup first
      gen.setup {
        model = "deepseek-coder:1.3b",
        host = "localhost",
        port = "11434",
      }

      -- Model list
      local models = {
        "deepseek-coder:1.3b",
        "phi3:mini",
        "deepseek-coder:6.7b",
        "codellama:7b",
        "qwen2.5-coder:7b",
        "starcoder2:3b",
        "qwen2.5-coder:14b",
      }

      -- Simple model selector using vim.ui.select
      local function select_model()
        vim.ui.select(models, {
          prompt = "Select AI Model:",
          format_item = function(item) return "🤖 " .. item end,
        }, function(choice)
          if choice then
            gen.setup { model = choice }
            vim.notify("✅ Switched to: " .. choice, vim.log.levels.INFO)
          end
        end)
      end

      -- Keymaps
      vim.keymap.set("n", "<leader>am", select_model, { desc = "Select AI Model" })
      vim.keymap.set({ "n", "v" }, "<leader>ag", ":Gen<CR>", { desc = "Gen AI" })
      vim.keymap.set({ "n", "v" }, "<leader>ac", ":Gen Chat<CR>", { desc = "AI Chat" })

      -- Custom prompts
      gen.prompts["Fix_Code"] = {
        prompt = "Fix this code, only return the corrected code:\n```$filetype\n$text\n```",
        replace = true,
      }

      gen.prompts["Explain"] = {
        prompt = "Explain this code step by step:\n```$filetype\n$text\n```",
        replace = false,
      }

      vim.keymap.set("v", "<leader>af", ":Gen Fix_Code<CR>", { desc = "Fix Code" })
      vim.keymap.set("v", "<leader>ae", ":Gen Explain<CR>", { desc = "Explain Code" })
    end,
  },
}
