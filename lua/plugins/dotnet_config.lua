-- ~/.config/nvim/lua/user/plugins/dotnet.lua
return {
  {
    "local/dotnet-nvim",
    dir = vim.fn.stdpath "config" .. "/lua/dotnet-nvim",
    config = function()
      require("dotnet-nvim").setup {
        default_namespace = "MyProject",
        keymaps = {
          create_class = "<leader>dc",
          create_interface = "<leader>di",
          create_controller = "<leader>dr",
          create_model = "<leader>dm",
        },
      }
    end,
  },
}
