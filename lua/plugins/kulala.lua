return {
  "mistweaverco/kulala.nvim",
  ft = { "http", "rest" },
  opts = {
    global_keymaps = true,
  },
  keys = {
    { "<leader>Rs", "<cmd>KulalaSend<cr>", desc = "Send request" },
    { "<leader>Ra", "<cmd>KulalaSendAll<cr>", desc = "Send all requests" },
    { "<leader>Rb", "<cmd>KulalaScratchpadOpen<cr>", desc = "Open scratchpad" },
  },
}
