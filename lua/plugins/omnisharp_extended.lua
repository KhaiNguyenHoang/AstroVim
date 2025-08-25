return {
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    ft = "cs",
    config = function()
      local keymap = vim.keymap.set

      -- Definition
      keymap("n", "gd", function()
        require("omnisharp_extended").lsp_definition()
        vim.cmd "Lspsaga goto_definition"
      end, { desc = "Goto Definition (C#)" })

      -- References
      keymap("n", "gr", function()
        require("omnisharp_extended").lsp_references()
        vim.cmd "Lspsaga finder"
      end, { desc = "Goto References (C#)" })

      -- Implementation
      keymap("n", "gi", function()
        require("omnisharp_extended").lsp_implementation()
        vim.cmd "Lspsaga finder imp" -- hoặc "Lspsaga goto_implementation"
      end, { desc = "Goto Implementation (C#)" })
    end,
  },
}
