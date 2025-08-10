---@type LazySpec
return {
  "folke/noice.nvim",
  optional = true,
  enabled = false,
  opts = {
    lsp = {
      hover = {
        enabled = false,
      },
      signature = {
        enabled = false,
      },
      progress = { enabled = false }, -- Optional: If you want less clutter
    },
    presets = {
      command_palette = true, -- If you're using a command palette (e.g., dressing.nvim)
    },
    messages = {
      enabled = true, -- Ensure messages are enabled
      view = "mini", -- Change to "notify" or "cmdline" if needed
    },
    routes = {
      {
        filter = {
          event = "msg_show",
          any = {
            { find = "Starting Supermaven" },
            { find = "Supermaven Free Tier" },
          },
        },
        skip = true,
      },
      {
        filter = { event = "msg_showmode" }, -- Ensure "recording" message is shown
        view = "mini", -- Change to "notify" or another Noice view if needed
      },
    },
  },
}
