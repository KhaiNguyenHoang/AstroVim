return {
  -- 使用 `autocmd` 方式启动(默认)
  -- 默认使用 mason 或 ~/.vscode/extensions/vmware.vscode-spring-boot-x.xx.x 中的 jar
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = {
      "mfussenegger/nvim-jdtls", -- or nvim-java, nvim-lspconfig
      "ibhagwan/fzf-lua", -- 可选，用于符号选择等UI功能。也可以使用其他选择器（例如 telescope.nvim）。
    },
    ---@type bootls.Config
    opts = {},
  },
}
