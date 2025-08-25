-- ~/.config/nvim/lua/plugins/llm.lua
return {
  "Kurama622/llm.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("llm").setup {
      default_provider = "gemini",
      providers = {
        gemini = {
          endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
          model = "gemini-2.5-flash",
          api_key = os.getenv "GEMINI_API_KEY", -- lấy key từ env
        },
      },
    }
  end,
}
