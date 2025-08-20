---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    optional = true,
    opts = {
      ensure_installed = {
        -- install language servers
        "lua-language-server",
        "hyprls",
        "taplo",
        "docker-compose-language-service",
        "dockerfile-language-server",
        "emmet-ls",
        "hyprls",
        "json-lsp",
        "marksman",
        "sqls",
        "yaml-language-server",

        -- install formatters
        "stylua",
        "markdown-toc",
        "isort",
        "black",

        -- linters
        "shellcheck",
        "dotenv-linter",

        -- install debuggers
        "debugpy",

        -- install any other package
        "tree-sitter-cli",
        "firefox-debug-adapter",
      },
    },
  },
  {
    "williamboman/mason.nvim",
    optional = true,
    opts = {
      registries = {
        "github:Crashdummyy/mason-registry",
      },
    },
  },
}
