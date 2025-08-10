---@type LazySpec
return {
  "LudoPinelli/comment-box.nvim",
  optional = true,
  event = "User AstroFile",
  opts = {},
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<Leader>B"] = { desc = "󱋄" .. " Comment box/line" }
        maps.n["<Leader>Bb"] = { "<CMD>CBccbox<CR>", desc = "Box Title" }
        maps.n["<Leader>Bl"] = { "<CMD>CBllline<CR>", desc = "Line Title left" }
      end,
    },
  },
}
