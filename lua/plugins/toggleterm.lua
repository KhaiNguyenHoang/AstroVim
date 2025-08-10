---@type LazySpec
return {
  "akinsho/toggleterm.nvim",
  optional = true,
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.t["<F8>"] = { "<C-\\><C-n>", desc = "Toggle visual mode" } -- requires terminal that supports binding <C-'>
      end,
    },
  },
}
