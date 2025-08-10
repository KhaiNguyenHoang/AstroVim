---@type LazySpec
return {
  "yetone/avante.nvim",
  optional = true,
  enabled = false,
  opts = {
    behaviour = {
      auto_suggestions = false, -- Experimental stage
      enable_cursor_planning_mode = false,
      enable_token_counting = false,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = true,
      minimize_diff = true, -- Whether to remove unchanged lines when applying a code block
      enable_claude_text_editor_tool_mode = false,
    },
    suggestion = {
      debounce = 600,
      throttle = 1000,
    },
    windows = {
      ---@type "right" | "left" | "top" | "bottom"
      position = "right", -- the position of the sidebar
      wrap = true, -- similar to vim.o.wrap
      width = 50, -- default % based on available width
      sidebar_header = {
        enabled = true, -- true, false to enable/disable the header
        align = "center", -- left, center, right for title
        rounded = true,
      },
      input = {
        prefix = "> ",
        height = 8, -- Height of the input window in vertical layout
      },
      edit = {
        border = "rounded",
        start_insert = true, -- Start insert mode when opening the edit window
      },
      ask = {
        floating = false, -- Open the 'AvanteAsk' prompt in a floating window
        start_insert = true, -- Start insert mode when opening the ask window
        border = "rounded",
        ---@type "ours" | "theirs"
        focus_on_apply = "ours", -- which diff to focus after applying
      },
    },
    -- list: rag_search, python, git_diff, git_commit, list_files, search_files, search_keyword, read_file_toplevel_symbols, read_file, create_file, rename_file, delete_file, create_dir, rename_dir, delete_dir, bash, web_search, fetch
    disabled_tools = {},
    -- file_selector = {
    --- @alias FileSelectorProvider "native" | "fzf" | "mini.pick" | "snacks" | "telescope" | string | fun(params: avante.file_selector.IParams|nil): nil
    -- provider = "snacks",
    --   provider_opts = {},
    -- },
    auto_suggestions_provider = nil,
    providers = {
      gemini = {
        endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
        model = "gemini-2.5-flash-preview-05-20",
        timeout = 30000, -- Timeout in milliseconds
        extra_request_body = {
          generationConfig = {
            temperature = 0,
            maxOutputTokens = 20480,
            thinkingConfig = {
              includeThoughts = false,
            },
          },
        },
      },
      groq = {
        __inherited_from = "openai",
        api_key_name = "GROQ_API_KEY",
        endpoint = "https://api.groq.com/openai/v1",
        model = "deepseek-r1-distill-llama-70b",
        -- disable_tools = true,
      },
      ovh = {
        __inherited_from = "openai",
        api_key_name = "OVH_API_KEY",
        endpoint = "https://deepseek-r1-distill-llama-70b.endpoints.kepler.ai.cloud.ovh.net/api/openai_compat/v1",
        model = "DeepSeek-R1-Distill-Llama-70B",
        extra_request_body = {
          max_tokens = 1024,
          top_p = 0.9,
          temperature = 0,
        },
        -- disable_tools = true,
      },
    },
    provider = "gemini",
    rag_service = {
      enabled = false, -- Enables the RAG service
      host_mount = os.getenv "HOME" .. "/git", -- Host mount path for the rag service
      runner = "docker",
      llm = { -- Language Model (LLM) configuration for RAG service
        provider = "gemini", -- LLM provider
        endpoint = "https://generativelanguage.googleapis.com/v1beta/models", -- LLM API endpoint
        api_key = "GEMINI_API_KEY", -- Environment variable name for the LLM API key
        model = "gemini-2.5-flash-preview-05-20", -- LLM model name
        extra = nil, -- Additional configuration options for LLM
      },
      embed = { -- Embedding model configuration for RAG service
        provider = "openai", -- Embedding provider
        endpoint = "https://generativelanguage.googleapis.com/v1beta/models", -- Embedding API endpoint
        api_key = "GEMINI_API_KEY", -- Environment variable name for the embedding API key
        model = "gemini-embedding-exp-03-07", -- Embedding model name
        extra = nil, -- Additional configuration options for the embedding model
      },
      docker_extra_args = "", -- Extra arguments to pass to the docker command
    },
  },
  specs = {
    -- {
    --   "saghen/blink.cmp",
    --   optional = true,
    --   opts = {
    --     sources = {
    --       default = {
    --         "avante_commands",
    --         "avante_mentions",
    --         "avante_files",
    --       },
    --       providers = {
    --         avante_commands = {
    --           name = "avante_commands",
    --           module = "blink.compat.source",
    --           score_offset = 90, -- show at a higher priority than lsp
    --           opts = {},
    --         },
    --         avante_files = {
    --           name = "avante_files",
    --           module = "blink.compat.source",
    --           score_offset = 100, -- show at a higher priority than lsp
    --           opts = {},
    --         },
    --         avante_mentions = {
    --           name = "avante_mentions",
    --           module = "blink.compat.source",
    --           score_offset = 1000, -- show at a higher priority than lsp
    --           opts = {},
    --         },
    --       },
    --     },
    --   },
    -- },
  },
}
