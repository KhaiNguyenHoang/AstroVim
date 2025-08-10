local function has_words_before()
  local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
end

---@type LazySpec
return {
  "saghen/blink.cmp",
  version = "*",
  dependencies = {
    {
      "Kaiser-Yang/blink-cmp-git",
      dependencies = { "nvim-lua/plenary.nvim" },
      lazy = true,
    },
    { "disrupted/blink-cmp-conventional-commits", lazy = true },
    { "xzbdmw/colorful-menu.nvim", lazy = true },
    -- ... other dependencies
  },
  opts = {
    sources = {
      -- add 'git' to the list
      default = { "conventional_commits", "git" },
      providers = {
        git = {
          module = "blink-cmp-git",
          name = "Git",
          -- only enable this source when filetype is gitcommit, markdown, or 'octo'
          enabled = function() return vim.tbl_contains({ "octo", "gitcommit", "markdown" }, vim.bo.filetype) end,
          --- @module 'blink-cmp-git'
          --- @type blink-cmp-git.Options
          opts = {
            commit = {
              -- You may want to customize when it should be enabled
              -- The default will enable this when `git` is found and `cwd` is in a git repository
              -- enable = function() end
              -- You may want to change the triggers
              -- triggers = { ':' },
            },
            git_centers = {
              github = {
                -- Those below have the same fields with `commit`
                -- Those features will be enabled when `git` and `gh` (or `curl`) are found and
                -- remote contains `github.com`
                -- issue = {
                --     get_token = function() return '' end,
                -- },
                -- pull_request = {
                --     get_token = function() return '' end,
                -- },
                -- mention = {
                --     get_token = function() return '' end,
                --     get_documentation = function(item)
                --         local default = require('blink-cmp-git.default.github')
                --             .mention.get_documentation(item)
                --         default.get_token = function() return '' end
                --         return default
                --     end
                -- }
              },
              gitlab = {
                -- Those below have the same fields with `commit`
                -- Those features will be enabled when `git` and `glab` (or `curl`) are found and
                -- remote contains `gitlab.com`
                -- issue = {
                --     get_token = function() return '' end,
                -- },
                -- NOTE:
                -- Even for `gitlab`, you should use `pull_request` rather than`merge_request`
                -- pull_request = {
                --     get_token = function() return '' end,
                -- },
                -- mention = {
                --     get_token = function() return '' end,
                --     get_documentation = function(item)
                --         local default = require('blink-cmp-git.default.gitlab')
                --            .mention.get_documentation(item)
                --         default.get_token = function() return '' end
                --         return default
                --     end
                -- }
              },
            },
          },
        },
        conventional_commits = {
          name = "Conventional Commits",
          module = "blink-cmp-conventional-commits",
          enabled = function() return vim.bo.filetype == "gitcommit" end,
          ---@module 'blink-cmp-conventional-commits'
          ---@type blink-cmp-conventional-commits.Options
          opts = {}, -- none so far
        },
      },
    },
    cmdline = {
      keymap = {
        -- recommended, as the default keymap will only show and select the next item
        ["<Tab>"] = {
          function(cmp)
            if cmp.is_ghost_text_visible() and not cmp.is_menu_visible() then return cmp.accept() end
          end,
          "show_and_insert",
          "select_next",
        },
      },
      completion = {
        menu = {
          auto_show = true,
          draw = {
            columns = {
              { "kind_icon" },
              { "label", gap = 1 },
            },
          },
        },
        list = {
          selection = {
            preselect = false,
            auto_insert = true,
          },
        },
      },
    },
    signature = {
      enabled = true,
      window = {
        border = "rounded",
        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
        treesitter_highlighting = true,
        show_documentation = true,
      },
    },
    keymap = {
      ["<Tab>"] = {
        "select_next",
        function(cmp)
          if has_words_before() or vim.api.nvim_get_mode().mode == "c" then return cmp.show() end
        end,
        "fallback",
      },
      ["<S-Tab>"] = {
        "select_prev",
        function(cmp)
          if vim.api.nvim_get_mode().mode == "c" then return cmp.show() end
        end,
        "fallback",
      },
      -- ["<CR>"] = { "snippet_forward", "accept", "fallback" },
      ["<CR>"] = {
        "snippet_forward",
        "accept",
        "fallback",
      },
    },

    completion = {
      trigger = {
        show_on_backspace_in_keyword = true,
      },
      ghost_text = {
        enabled = true,
        show_with_menu = true,
      },
      list = { selection = { preselect = false, auto_insert = true } },
      documentation = {
        draw = function(opts)
          if opts.item and opts.item.documentation then
            local out = require("pretty_hover.parser").parse(opts.item.documentation.value)
            opts.item.documentation.value = out:string()
          end

          opts.default_implementation(opts)
        end,
      },
      menu = {
        draw = {
          columns = {
            { "kind_icon" },
            { "label", gap = 1 },
            { "source_name" },
          },
          components = {
            label = {
              text = function(ctx) return require("colorful-menu").blink_components_text(ctx) end,
              highlight = function(ctx) return require("colorful-menu").blink_components_highlight(ctx) end,
            },
            source_name = {
              width = { max = 30 },
              text = function(ctx) return "(" .. ctx.source_name .. ")" end,
              highlight = "BlinkCmpSource",
            },
          },
        },
      },
    },
  },
}
