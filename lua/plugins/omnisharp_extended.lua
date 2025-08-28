return {
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
  },
  lazy = true,
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = {
          handlers = {
            ["textDocument/definition"] = function(...) return require("omnisharp_extended").definition_handler(...) end,
            ["textDocument/typeDefinition"] = function(...)
              return require("omnisharp_extended").type_definition_handler(...)
            end,
            ["textDocument/references"] = function(...) return require("omnisharp_extended").references_handler(...) end,
            ["textDocument/implementation"] = function(...)
              return require("omnisharp_extended").implementation_handler(...)
            end,
          },
        },
      },
    },
  },
}
