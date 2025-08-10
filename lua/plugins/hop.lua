---@type LazySpec
return {
  enabled = false,
  optional = true,
  "smoka7/hop.nvim",
  event = "VeryLazy",
  opts = {
    -- excluded_filetypes = {
    --   "undotree",
    --   "qf",
    --   "netrw",
    --   "neo-tree",
    --   "dapui_scopes",
    --   "dapui_breakpoints",
    --   "dapui_watches",
    --   "dapui_console",
    --   "dap-repl",
    --   "dirvish",
    --   "fugitive",
    --   "alpha",
    --   "NvimTree",
    --   "lazy",
    --   "neogitstatus",
    --   "Trouble",
    --   "lir",
    --   "Outline",
    --   "spectre_panel",
    --   "toggleterm",
    --   "DressingSelect",
    --   "TelescopePrompt",
    --   "grug-far",
    --   "grug-far-history",
    --   "grug-far-help",
    -- },
  },
  dependencies = {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["f"] = { "<CMD>HopWord<CR>", desc = "Hop hint words" },
          ["<S-f>"] = { "<CMD>HopChar1MW<CR>", desc = "Hop hint 1 char multiple windows" },
        },
        v = {
          ["f"] = { "<CMD>HopWord<CR>", desc = "Hop hint words" },
          ["<S-f>"] = { "<CMD>HopChar1MW<CR>", desc = "Hop hint 1 char multiple windows" },
        },
      },
    },
  },
}
