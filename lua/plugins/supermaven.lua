---@type LazySpec
return {
  "supermaven-nvim",
  enabled = function() return vim.env.DISPLAY ~= nil and vim.env.DISPLAY ~= "" end,
  lazy = true,
  event = "VeryLazy",
  opts = {
    -- ignore_filetypes = { cpp = true }, -- or { "cpp", }
    -- color = {
    --   suggestion_color = "#ffffff",
    --   cterm = 244,
    -- },
    condition = function()
      local buf_utils = require "astrocore.buffer"
      return buf_utils.is_large(nil, { size = false, lines = 10000, enabled = true })
    end,
  },
  specs = {
    {
      "saghen/blink.cmp",
      optional = true,
      opts = {
        sources = {
          default = { "supermaven" },
          providers = {
            supermaven = {
              name = "supermaven",
              module = "blink.compat.source",
              -- score_offset = 100,
            },
          },
        },
      },
    },
  },
}
