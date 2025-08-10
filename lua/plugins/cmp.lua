local function has_words_before()
  local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
end

local function is_visible(cmp) return cmp.core.view:visible() or vim.fn.pumvisible() == 1 end

---when inside a snippet, seeks to the nearest luasnip field if possible, and checks if it is jumpable
---@param dir number 1 for forward, -1 for backward; defaults to 1
---@return boolean true if a jumpable luasnip field is found while inside a snippet
local function jumpable(dir)
  local luasnip_ok, luasnip = pcall(require, "luasnip")
  if not luasnip_ok then return false end

  local win_get_cursor = vim.api.nvim_win_get_cursor
  local get_current_buf = vim.api.nvim_get_current_buf

  ---sets the current buffer's luasnip to the one nearest the cursor
  ---@return boolean true if a node is found, false otherwise
  local function seek_luasnip_cursor_node()
    -- TODO(kylo252): upstream this
    -- for outdated versions of luasnip
    if not luasnip.session.current_nodes then return false end

    local node = luasnip.session.current_nodes[get_current_buf()]
    if not node then return false end

    local snippet = node.parent.snippet
    local exit_node = snippet.insert_nodes[0]

    local pos = win_get_cursor(0)
    pos[1] = pos[1] - 1

    -- exit early if we're past the exit node
    if exit_node then
      local exit_pos_end = exit_node.mark:pos_end()
      if (pos[1] > exit_pos_end[1]) or (pos[1] == exit_pos_end[1] and pos[2] > exit_pos_end[2]) then
        snippet:remove_from_jumplist()
        luasnip.session.current_nodes[get_current_buf()] = nil

        return false
      end
    end

    node = snippet.inner_first:jump_into(1, true)
    while node ~= nil and node.next ~= nil and node ~= snippet do
      local n_next = node.next
      local next_pos = n_next and n_next.mark:pos_begin()
      local candidate = n_next ~= snippet and next_pos and (pos[1] < next_pos[1])
        or (pos[1] == next_pos[1] and pos[2] < next_pos[2])

      -- Past unmarked exit node, exit early
      if n_next == nil or n_next == snippet.next then
        snippet:remove_from_jumplist()
        luasnip.session.current_nodes[get_current_buf()] = nil

        return false
      end

      if candidate then
        luasnip.session.current_nodes[get_current_buf()] = node
        return true
      end

      local ok
      ok, node = pcall(node.jump_from, node, 1, true) -- no_move until last stop
      if not ok then
        snippet:remove_from_jumplist()
        luasnip.session.current_nodes[get_current_buf()] = nil

        return false
      end
    end

    -- No candidate, but have an exit node
    if exit_node then
      -- to jump to the exit node, seek to snippet
      luasnip.session.current_nodes[get_current_buf()] = snippet
      return true
    end

    -- No exit node, exit from snippet
    snippet:remove_from_jumplist()
    luasnip.session.current_nodes[get_current_buf()] = nil
    return false
  end

  if dir == -1 then
    return luasnip.in_snippet() and luasnip.jumpable(-1)
  else
    return luasnip.in_snippet() and seek_luasnip_cursor_node() and luasnip.jumpable(1)
  end
end

---@type LazySpec
return {
  "hrsh7th/nvim-cmp",
  optional = true,
  enabled = false,
  dependencies = {
    "onsails/lspkind.nvim",
    -- "FelipeLema/cmp-async-path",
    {
      "tzachar/cmp-tabnine",
      as = "cmp_tabnine",
      build = "./install.sh",
      lazy = true,
      event = "InsertEnter",
      config = function()
        require("cmp_tabnine.config"):setup {
          max_lines = 1000,
          max_num_results = 10,
          sort = true,
          run_on_every_keystroke = true,
          snippet_placeholder = "..",
          ignored_file_types = {
            -- default is not to ignore
            -- uncomment to ignore in lua:
            -- lua = true
          },
          show_prediction_strength = true,
          min_percent = 0,
        }
      end,
    },
    {
      "David-Kunz/cmp-npm",
      ft = { "json" },
      lazy = true,
      dependencies = { "nvim-lua/plenary.nvim", "hrsh7th/nvim-cmp" },
      config = function() require("cmp-npm").setup {} end,
    },
  },
  opts = function(_, opts)
    -- local cmp = require "cmp"
    local lspkind = require "lspkind"
    local astroui = require "astroui"
    local luasnip, cmp = require "luasnip", require "cmp"
    table.insert(opts.sources, { name = "npm", priority = 700 })
    table.insert(opts.sources, { name = "cmp_tabnine", priority = 600 })
    opts.formatting = {
      fields = { "kind", "abbr", "menu" },
      max_width = 0,
      kind_icons = lspkind.symbol_map,
      source_names = {
        nvim_lsp = "(LSP)",
        emoji = "(Emoji)",
        path = "(Path)",
        calc = "(Calc)",
        cmp_tabnine = "(Tabnine)",
        vsnip = "(Snippet)",
        luasnip = "(Snippet)",
        buffer = "(Buffer)",
        tmux = "(TMUX)",
        copilot = "(Copilot)",
        treesitter = "(TreeSitter)",
      },
      duplicates = {
        buffer = 1,
        path = 1,
        nvim_lsp = 0,
        luasnip = 1,
      },
      duplicates_default = 0,
      format = function(entry, vim_item)
        local max_width = 0
        if max_width ~= 0 and #vim_item.abbr > max_width then
          vim_item.abbr = string.sub(vim_item.abbr, 1, max_width - 1) .. astroui.get_icon "Ellipsis"
        end
        vim_item.kind = opts.formatting.kind_icons[vim_item.kind]

        if entry.source.name == "cmp_tabnine" then
          vim_item.kind = "󰚩"
          vim_item.kind_hl_group = "CmpItemKindTabnine"
        end

        if entry.source.name == "crates" then
          vim_item.kind = ""
          vim_item.kind_hl_group = "CmpItemKindCrate"
        end

        if entry.source.name == "lab.quick_data" then
          vim_item.kind = ""
          vim_item.kind_hl_group = "CmpItemKindConstant"
        end

        if entry.source.name == "emoji" then
          vim_item.kind = ""
          vim_item.kind_hl_group = "CmpItemKindEmoji"
        end
        vim_item.menu = opts.formatting.source_names[entry.source.name]
        vim_item.dup = opts.formatting.duplicates[entry.source.name] or opts.formatting.duplicates_default
        return vim_item
      end,
    }

    opts.completion = {
      ---@usage The minimum length of a word to complete on.
      keyword_length = 1,
      autocomplete = {
        require("cmp.types").cmp.TriggerEvent.TextChanged,
        require("cmp.types").cmp.TriggerEvent.InsertEnter,
        completeopt = "menu,menuone,noinsert,noselect",
      },
    }
    if not opts.mappings then opts.mappings = {} end
    -- opts.mappings["<C-K>"] = nil
    -- opts.mappings["<C-J>"] = nil
    opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
      if is_visible(cmp) then
        local selectBehavior = vim.b.visual_multi and cmp.SelectBehavior.Select or cmp.SelectBehavior.Insert
        cmp.select_next_item { behavior = selectBehavior }
      elseif vim.api.nvim_get_mode().mode ~= "c" and luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      elseif jumpable(1) then
        luasnip.jump(1)
      elseif has_words_before() then
        -- cmp.complete()
        fallback()
      else
        fallback()
      end
    end, { "i", "s" })
    opts.mapping["<S-Tab>"] = cmp.mapping(function(fallback)
      if is_visible(cmp) then
        local selectBehavior = vim.b.visual_multi and cmp.SelectBehavior.Select or cmp.SelectBehavior.Insert
        cmp.select_prev_item { behavior = selectBehavior }
      elseif vim.api.nvim_get_mode().mode ~= "c" and jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" })
    opts.mapping["<CR>"] = cmp.mapping(function(fallback)
      if cmp.visible() and cmp.get_selected_entry() then
        local confirm_opts = {
          behavior = cmp.ConfirmBehavior.Replace,
          select = false,
        } -- avoid mutating the original opts below
        local is_insert_mode = function() return vim.api.nvim_get_mode().mode:sub(1, 1) == "i" end
        if is_insert_mode() then -- prevent overwriting brackets
          confirm_opts.behavior = cmp.ConfirmBehavior.Insert
        end
        if cmp.confirm(confirm_opts) then
          return -- success, exit early
        end

        local entry = cmp.get_selected_entry()
        local is_AI_selected = entry and entry.source.name == "copilot" or entry.source.name == "cmp_tabnine"
        if is_AI_selected then
          confirm_opts.behavior = cmp.ConfirmBehavior.Replace
          confirm_opts.select = true
        end
        -- when no selected any entry
      elseif jumpable(1) then
        luasnip.jump(1)
        return
      end
      fallback() -- if not exited early, always fallback
    end)
    -- return opts
  end,
}
