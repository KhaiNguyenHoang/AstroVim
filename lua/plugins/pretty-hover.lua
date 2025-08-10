---@type LazySpec
return {
  "Fildo7525/pretty_hover",
  event = "LspAttach",
  dependencies = {
    {
      "AstroNvim/astrolsp",
      opts = {
        mappings = {
          n = {
            ["K"] = {
              function() require("pretty_hover").hover() end,
              cond = "textDocument/hover",
              desc = "Toggle pretty hover",
            },
          },
        },
      },
    },
  },
  opts = {},
}
