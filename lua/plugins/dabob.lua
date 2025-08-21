local prefix = "<leader>D"

---@type LazySpec
return {
  {
    "tpope/vim-dadbod",
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
      "kristijanhusak/vim-dadbod-completion",
    },
    config = function()
      -- Enable nerd fonts in UI
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    optional = true,
    dependencies = {
      { "AstroNvim/astroui", opts = { icons = { Database = "" } } },
      {
        "AstroNvim/astrocore",
        opts = function(_, opts)
          local maps = opts.mappings
          if not opts.mappings then opts.mappings = require("astrocore").empty_map_table() end
          maps.n[prefix] = { desc = require("astroui").get_icon("Database", 1, true) .. "Database" }
          maps.n[prefix .. "u"] = { "<CMD>DBUI<CR>", desc = "Database UI" }
          maps.n[prefix .. "t"] = { "<CMD>DBUIToggle<CR>", desc = "Toggle UI" }
          maps.n[prefix .. "n"] = { "<CMD>DBUIAddConnection<CR>", desc = "Add New Connection" }
          maps.n[prefix .. "f"] = { "<CMD>DBUIFindBuffer<CR>", desc = "Find Buffer" }
        end,
      },
    },
  },
}
