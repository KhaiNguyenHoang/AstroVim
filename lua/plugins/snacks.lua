---@type LazySpec
return {
  "folke/snacks.nvim",
  optional = true,
  dependencies = {
    {
      "nvim-treesitter/nvim-treesitter",
      optional = true,
      opts = function(_, opts)
        if opts.ensure_installed ~= "all" then
          opts.ensure_installed =
            require("astrocore").list_insert_unique(opts.ensure_installed, { "markdown", "markdown_inline" })
        end
      end,
    },
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<Leader>fH"] = { function() require("snacks").picker.highlights() end, desc = "Find highlight colors" }

        -- Snacks.dashboard mappins
        maps.n["<F2>"] = {
          function()
            if vim.bo.filetype == "snacks_dashboard" then
              require("astrocore.buffer").close()
            else
              require("snacks").dashboard()
            end
          end,
          desc = "Home Screen",
        }
        maps.n["<Leader>fl"] = {
          function()
            local filetypes = {}
            for _, ft in ipairs(vim.fn.getcompletion("", "filetype")) do
              table.insert(filetypes, { text = ft, name = ft })
            end

            require("snacks").picker {
              items = filetypes,
              source = "filetypes",
              layout = "select", -- or vscode
              format = function(item)
                local icon, icon_hl = require("snacks.util").icon(item.text, "filetype")
                return {
                  { icon .. " ", icon_hl },
                  { item.text },
                }
              end,
              confirm = function(picker, item)
                picker:close()
                vim.cmd.set("ft=" .. item.text)
              end,
            }
          end,
          desc = "File language (types)",
        }
        maps.n["<Leader>fi"] = {
          function()
            require("snacks").picker.icons {
              icon_sources = { "nerd_fonts", "emoji" },
              finder = "icons",
              format = "icon",
              layout = { preset = "vscode" },
              confirm = "put",
            }
          end,
          desc = "Find old files",
        }
        maps.n["<Leader>fo"] = {
          function()
            require("snacks").picker.smart {
              multi = { "recent" },
              format = "file", -- use `file` format for all sources
              matcher = {
                cwd_bonus = false, -- boost cwd matches
                frecency = true, -- use frecency boosting
                sort_empty = false, -- sort even when the filter is empty
                history_bonus = true,
              },
              transform = "unique_file",
              sort_lastused = true,
            }
          end,
          desc = "Find old files",
        }
        maps.n["<Leader>fO"] = {
          function()
            require("snacks").picker.recent {
              filter = {
                cwd = true,
              },
            }
          end,
          desc = "Find old files (cwd)",
        }
      end,
    },
  },
  opts = {
    dashboard = {
      sections = {
        {
          section = "terminal",
          cmd = "fortune -s codememe | cowsay",
          hl = "header",
          padding = 1,
          indent = 8,
        },
        { section = "keys", gap = 1, padding = 3 },
        { section = "startup" },
      },
    },
    image = {
      force = true,
      doc = {
        enabled = true,
      },
    },
    quickfile = {},
    lazygit = {},
    picker = {
      win = {
        input = {
          keys = {
            ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
            ["<Tab>"] = { "list_down", mode = { "i", "n" } },
            ["<c-j>"] = { "select_and_next", mode = { "i", "n" } },
            ["<c-k>"] = { "select_and_prev", mode = { "i", "n" } },
          },
        },
      },
    },
  },
}
