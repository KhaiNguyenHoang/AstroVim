return {
  "Davidyz/VectorCode",
  version = "*",
  build = "pipx upgrade vectorcode",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    n_query = 1,
    notify = true,
    timeout_ms = 5000,
    exclude_this = true,
  },
  cond = function() return vim.fn.executable("vectorcode") == 1 end,
}

