return {
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    ft = "cs",
    config = function()
      local keymap = vim.keymap.set
      local saga = require "lspsaga"

      -- Goto Definition (popup Saga, dùng omnisharp_extended cho C#)
      keymap("n", "gd", function()
        require("omnisharp_extended").lsp_definition()
        saga.definition:goto_definition()
      end, { desc = "Goto Definition (C#)" })

      -- References
      keymap("n", "gr", function()
        require("omnisharp_extended").lsp_references()
        saga.finder:lsp_finder()
      end, { desc = "Goto References (C#)" })

      -- Implementation
      keymap("n", "gi", function()
        require("omnisharp_extended").lsp_implementation()
        saga.definition:goto_type_definition()
      end, { desc = "Goto Implementation (C#)" })
    end,
  },
}
