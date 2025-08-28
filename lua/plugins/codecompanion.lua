local prefix = "<Leader>A"

---@type LazySpec
return {
  "olimorris/codecompanion.nvim",
  optional = true,
  dependencies = {
    "ravitemer/codecompanion-history.nvim",
    -- Add mcphub.nvim as a dependency
    { "ravitemer/mcphub.nvim", optional = true },
  },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        if not opts.mappings then opts.mappings = {} end
        opts.mappings.n = opts.mappings.n or {}
        opts.mappings.v = opts.mappings.v or {}
        opts.mappings.n[prefix .. "h"] = { "<cmd>CodeCompanionHistory<cr>", desc = "Open history" }
        opts.mappings.v[prefix .. "s"] = { "<cmd>CodeCompanionSummaries<cr>", desc = "Browse summaries" }
      end,
    },
  },
  opts = {
    extensions = {
      history = {
        enabled = true,
        opts = {
          -- Keymap to open history from chat buffer (default: gh)
          keymap = "gh",
          -- Keymap to save the current chat manually (when auto_save is disabled)
          save_chat_keymap = "sc",
          -- Save all chats by default (disable to save only manually using 'sc')
          auto_save = true,
          -- Number of days after which chats are automatically deleted (0 to disable)
          expiration_days = 0,
          -- Picker interface (auto resolved to a valid picker)
          picker = "default", --- ("telescope", "snacks", "fzf-lua", or "default")
          ---Optional filter function to control which chats are shown when browsing
          chat_filter = nil, -- function(chat_data) return boolean end
          -- Customize picker keymaps (optional)
          -- picker_keymaps = {
          --   rename = { n = "r", i = "<M-r>" },
          --   delete = { n = "d", i = "<M-d>" },
          --   duplicate = { n = "<C-y>", i = "<C-y>" },
          -- },
          ---On exiting and entering neovim, loads the last chat on opening chat
          continue_last_chat = false,
          ---When chat is cleared with `gx` delete the chat from history
          delete_on_clearing_chat = false,
          ---Directory path to save the chats
          dir_to_save = vim.fn.stdpath "data" .. "/codecompanion-history",

          -- Summary system
          summary = {
            -- Keymap to generate summary for current chat (default: "gcs")
            create_summary_keymap = "gcs",
            -- Keymap to browse summaries (default: "gbs")
            browse_summaries_keymap = "gbs",

            generation_opts = {
              adapter = nil, -- defaults to current chat adapter
              model = nil, -- defaults to current chat model
              context_size = 90000, -- max tokens that the model supports
              include_references = true, -- include slash command content
              include_tool_outputs = true, -- include tool execution results
              system_prompt = nil, -- custom system prompt (string or function)
              format_summary = nil, -- custom function to format generated summary e.g to remove <think/> tags from summary
            },
          },

          -- Memory system (requires VectorCode CLI)
          memory = {
            -- Automatically index summaries when they are generated
            auto_create_memories_on_summary_generation = true,
            -- Path to the VectorCode executable
            vectorcode_exe = "vectorcode",
            -- Tool configuration
            tool_opts = {
              -- Default number of memories to retrieve
              default_num = 10,
            },
            -- Enable notifications for indexing progress
            notify = true,
            -- Index all existing memories on startup
            -- (requires VectorCode 0.6.12+ for efficient incremental indexing)
            index_on_startup = true,
          },
        },
      },
    },
    language = "English",
    adapters = {
      nvidia = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          formatted_name = "Nvidia",
          env = {
            url = "https://integrate.api.nvidia.com",
            api_key = "NVIDIA_API_KEY",
            chat_url = "/v1/chat/completions",
            models_endpoint = "/v1/models",
          },
          schema = {
            model = {
              default = "openai/gpt-oss-120b",
            },

            temperature = {
              order = 2,
              mapping = "parameters",
              type = "number",
              optional = true,
              default = 0.8,
              desc = "What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or top_p but not both.",
              validate = function(n) return n >= 0 and n <= 2, "Must be between 0 and 2" end,
            },
            max_completion_tokens = {
              order = 3,
              mapping = "parameters",
              type = "integer",
              optional = true,
              default = nil,
              desc = "An upper bound for the number of tokens that can be generated for a completion.",
              validate = function(n) return n > 0, "Must be greater than 0" end,
            },
            stop = {
              order = 4,
              mapping = "parameters",
              type = "string",
              optional = true,
              default = nil,
              desc = "Sets the stop sequences to use. When this pattern is encountered the LLM will stop generating text and return. Multiple stop patterns may be set by specifying multiple separate stop parameters in a modelfile.",
              validate = function(s) return s:len() > 0, "Cannot be an empty string" end,
            },
            logit_bias = {
              order = 5,
              mapping = "parameters",
              type = "map",
              optional = true,
              default = nil,
              desc = "Modify the likelihood of specified tokens appearing in the completion. Maps tokens (specified by their token ID) to an associated bias value from -100 to 100. Use https://platform.openai.com/tokenizer to find token IDs.",
              subtype_key = {
                type = "integer",
              },
              subtype = {
                type = "integer",
                validate = function(n) return n >= -100 and n <= 100, "Must be between -100 and 100" end,
              },
            },
          },
        })
      end,
      gemini = function()
        return require("codecompanion.adapters").extend("gemini", {
          schema = {
            model = {
              default = "gemini-2.5-flash",
            },
          },
        })
      end,
    },
    strategies = {
      chat = {
        adapter = "nvidia",
      },
      inline = {
        adapter = "nvidia",
      },
      cmd = {
        adapter = "nvidia",
      },
    },
  },
}
