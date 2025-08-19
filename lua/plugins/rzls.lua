-- ~/.config/nvim/lua/user/plugins/rzls.lua
return {
  "tris203/rzls.nvim", -- plugin highlight Razor
  lazy = true,          -- chỉ load khi mở file razor
  dependencies = { "neovim/nvim-lspconfig" },
  config = function()
    local lspconfig = require("lspconfig")
    local fn = vim.fn
    local uv = vim.loop

    -- Thư mục lưu Razor Language Server
    local rzls_path = fn.stdpath("data") .. "/rzls"

    -- Nếu chưa có repo, clone từ Microsoft
    if fn.isdirectory(rzls_path) == 0 then
      print("Cloning Razor Language Server...")
      fn.system({"git", "clone", "https://github.com/dotnet/aspnetcore.git", rzls_path})
    end

    -- Đường dẫn csproj của Razor LSP
    local csproj = rzls_path .. "/src/Razor/Microsoft.AspNetCore.Razor.LanguageServer.csproj"
    local binary = rzls_path .. "/src/Razor/bin/Release/net7.0/Microsoft.AspNetCore.Razor.LanguageServer.dll"

    -- Build Razor LSP (nếu chưa build)
    if fn.filereadable(binary) == 0 then
      print("Building Razor Language Server...")
      local build_cmd = {"dotnet", "build", csproj, "-c", "Release"}
      local result = fn.system(build_cmd)
      print(result)
    end

    -- Tạo custom LSP trong lspconfig
    lspconfig.rzls = {
      default_config = {
        cmd = { "dotnet", binary, "--stdio" },
        filetypes = { "razor" },
        root_dir = lspconfig.util.root_pattern("*.csproj", ".git"),
        settings = {},
      },
    }

    -- Setup server
    lspconfig.rzls.setup({})
    print("Razor Language Server is ready!")
  end,
}
