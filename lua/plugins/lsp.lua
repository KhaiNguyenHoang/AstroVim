return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lspconfig = require "lspconfig"

    -- ví dụ: bật OmniSharp cho C#
    lspconfig.omnisharp.setup {
      cmd = { "omnisharp" },
      enable_editorconfig_support = true,
      enable_roslyn_analyzers = true,
      organize_imports_on_format = true,
    }
  end,
}
