return {
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    ft = "cs",
    config = function()
      local keymap = vim.keymap.set

      -- Goto Definition
      keymap(
        "n",
        "gd",
        function() require("omnisharp_extended").lsp_definition() end,
        { desc = "Goto Definition (C#)" }
      )

      -- References
      keymap(
        "n",
        "gr",
        function() require("omnisharp_extended").lsp_references() end,
        { desc = "Goto References (C#)" }
      )

      -- Implementation / Type Definition
      keymap(
        "n",
        "gi",
        function() require("omnisharp_extended").lsp_implementation() end,
        { desc = "Goto Implementation (C#)" }
      )
    end,
  },
}
