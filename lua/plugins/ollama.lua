-- ~/.config/nvim/lua/plugins/smart-ollama.lua

return {
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "MunifTanjim/nui.nvim",
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>a"] = { name = "🤖 AI Assistant" },
        ["<leader>ac"] = { name = "🧩 C# Tools" },
      },
    },
  },
  {
    name = "smart-ollama",
    dir = vim.fn.stdpath "config",
    lazy = false,
    config = function()
      local M = {}

      -- ========== Provider/Model State ==========
      local current_provider = "ollama" -- "ollama" | "gemini"
      local current_ollama_model = "deepseek-coder:1.3b"
      local current_gemini_model = "gemini-2.0-flash" -- bạn có thể đổi sang "gemini-2.5-flash" nếu có quyền
      local gemini_api_key = vim.env.GEMINI_API_KEY or vim.g.smart_ai_gemini_api_key

      local ollama_models = {
        { name = "🚀 DeepSeek-Coder 1.3B (Fast)", id = "deepseek-coder:1.3b" },
        { name = "⚡ Phi-3 Mini (Balanced)", id = "phi3:mini" },
        { name = "🧠 DeepSeek-Coder 6.7B (Smart)", id = "deepseek-coder:6.7b" },
        { name = "🔥 Qwen2.5-Coder 14B (Powerful)", id = "qwen2.5-coder:14b" },
        { name = "🦙 CodeLlama 7B (Meta)", id = "codellama:7b" },
      }

      local gemini_models = {
        { name = "⚡ Gemini 2.5 Flash (Fast)", id = "gemini-2.5-flash" },
        { name = "⚡ Gemini 2.0 Flash (Fast)", id = "gemini-2.0-flash" },
        { name = "🧠 Gemini 1.5 Pro (Smart)", id = "gemini-1.5-pro" },
      }

      -- ========== Utils ==========
      local function popup_input(title, placeholder, callback, opts)
        local Input = require "nui.input"
        local event = require("nui.utils.autocmd").event

        local input = Input({
          position = "50%",
          size = { width = (opts and opts.width) or 60, height = 3 },
          border = { style = "rounded", text = { top = " " .. title .. " ", top_align = "center" } },
          win_options = { winhighlight = "Normal:Normal,FloatBorder:FloatBorder" },
        }, {
          prompt = "❯ ",
          default_value = placeholder or "",
          on_close = function() end,
          on_submit = function(value)
            if value and value ~= "" then callback(value) end
          end,
        })

        input:mount()
        input:on(event.BufLeave, function() input:unmount() end)
      end

      local function show_loading() vim.notify("🤖 AI is thinking...", vim.log.levels.INFO, { timeout = 800 }) end

      -- Treat special/UI buffers as text to avoid weird prompts or write errors
      local function get_filetype()
        local ft = vim.bo.filetype or "text"
        local special_ft = {
          snacks_dashboard = true,
          alpha = true,
          ["neo-tree"] = true,
          ["TelescopePrompt"] = true,
          lazy = true,
          noice = true,
        }
        if special_ft[ft] or (vim.bo.buftype ~= "" and vim.bo.buftype ~= "acwrite") then return "text" end
        return ft
      end

      local function ensure_normal_buffer(target_ft)
        if vim.bo.buftype == "" and vim.bo.modifiable and not vim.bo.readonly then return end
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buf)
        if target_ft and target_ft ~= "text" then
          pcall(vim.api.nvim_buf_set_option, buf, "filetype", target_ft)
        else
          pcall(vim.api.nvim_buf_set_option, buf, "filetype", "markdown")
        end
        vim.notify("ℹ️ Output opened in a new scratch buffer", vim.log.levels.INFO)
      end

      local function open_float_markdown(lines, title)
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

        local width = math.min(100, vim.o.columns - 10)
        local height = math.min(30, #lines + 2)

        vim.api.nvim_open_win(buf, true, {
          relative = "cursor",
          width = width,
          height = height,
          col = 0,
          row = 1,
          style = "minimal",
          border = "rounded",
          title = " " .. (title or "AI") .. " ",
          title_pos = "center",
        })

        vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf })
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
      end

      local function extract_code(response)
        local code = response:match "```%w*%s*\n(.-)```"
        if code then return vim.split((code:gsub("^%s*", ""):gsub("%s*$", "")), "\n") end
        return vim.split((response:gsub("^%s*", ""):gsub("%s*$", "")), "\n")
      end

      -- ========== HTTP Clients ==========
      local function call_ollama(prompt, callback, opts)
        local temperature = (opts and opts.temperature) or 0.1
        local top_p = (opts and opts.top_p) or 0.9
        local model = (opts and opts.model) or current_ollama_model

        local body = vim.fn.json_encode {
          model = model,
          prompt = prompt,
          stream = false,
          options = { temperature = temperature, top_p = top_p },
        }

        local curl_command = {
          "curl",
          "-sS",
          "-X",
          "POST",
          "http://localhost:11434/api/generate",
          "-H",
          "Content-Type: application/json",
          "-d",
          body,
        }

        vim.fn.jobstart(curl_command, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            if not data or #data == 0 then return end
            local response_text = table.concat(data, "\n")
            if response_text == "" then return end
            local ok, response = pcall(vim.fn.json_decode, response_text)
            if ok and response and response.response then
              callback(response.response)
            else
              vim.notify("❌ Ollama: error parsing response", vim.log.levels.ERROR)
            end
          end,
          on_stderr = function(_, data)
            if data and #data > 0 and data[1] ~= "" then
              vim.notify("❌ Ollama error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
            end
          end,
          on_exit = function(_, code)
            if code ~= 0 then vim.notify("❌ Failed to connect to Ollama", vim.log.levels.ERROR) end
          end,
        })
      end

      local function call_gemini(prompt, callback, opts)
        local temperature = (opts and opts.temperature) or 0.1
        local top_p = (opts and opts.top_p) or 0.9
        local model = (opts and opts.model) or current_gemini_model
        local system_instruction = opts and opts.system

        if not gemini_api_key or gemini_api_key == "" then
          vim.notify("🔑 Missing GEMINI_API_KEY. Set env GEMINI_API_KEY or <leader>ak", vim.log.levels.WARN)
          return
        end

        local url = "https://generativelanguage.googleapis.com/v1beta/models/"
          .. model
          .. ":generateContent?key="
          .. gemini_api_key
        local body_tbl = {
          contents = { { role = "user", parts = { { text = prompt } } } },
          generationConfig = { temperature = temperature, topP = top_p },
        }
        if system_instruction and system_instruction ~= "" then
          body_tbl.systemInstruction = { role = "system", parts = { { text = system_instruction } } }
        end

        local body = vim.fn.json_encode(body_tbl)
        local curl_command = { "curl", "-sS", "-X", "POST", url, "-H", "Content-Type: application/json", "-d", body }

        vim.fn.jobstart(curl_command, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            if not data or #data == 0 then return end
            local response_text = table.concat(data, "\n")
            if response_text == "" then return end
            local ok, response = pcall(vim.fn.json_decode, response_text)
            if not ok or not response then
              vim.notify("❌ Gemini: error parsing JSON", vim.log.levels.ERROR)
              return
            end

            local text = ""
            if
              response
              and response.candidates
              and response.candidates[1]
              and response.candidates[1].content
              and response.candidates[1].content.parts
              and response.candidates[1].content.parts[1]
              and response.candidates[1].content.parts[1].text
            then
              text = response.candidates[1].content.parts[1].text
            else
              local parts = ((response or {}).candidates or {})[1]
              parts = parts and parts.content and parts.content.parts or {}
              local acc = {}
              for _, p in ipairs(parts or {}) do
                if type(p.text) == "string" then table.insert(acc, p.text) end
              end
              text = table.concat(acc, "\n")
            end

            callback(text)
          end,
          on_stderr = function(_, data)
            if data and #data > 0 and data[1] ~= "" then
              vim.notify("❌ Gemini error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
            end
          end,
        })
      end

      local function call_ai(prompt, callback, opts)
        if current_provider == "gemini" then
          return call_gemini(prompt, callback, opts)
        else
          return call_ollama(prompt, callback, opts)
        end
      end

      -- ========== Learning Mode ==========
      local learning_mode = false
      function M.toggle_learning_mode()
        learning_mode = not learning_mode
        vim.notify("🎓 Learning mode: " .. (learning_mode and "ON" or "OFF"), vim.log.levels.INFO)
      end

      -- ========== Core Actions ==========
      function M.generate_and_insert()
        popup_input("🤖 Generate Code", "Create a function to...", function(prompt)
          local filetype = get_filetype()
          local context = ""
          local lines = vim.api.nvim_buf_get_lines(0, 0, 50, false)
          if #lines > 0 then
            context = "Context from current "
              .. filetype
              .. " file:\n"
              .. table.concat(lines, "\n", 1, math.min(10, #lines))
              .. "\n\n"
          end

          local full_prompt = string.format(
            "%sGenerate %s code for: %s\n\nOnly return the code, no explanations. Make sure it fits the context.",
            context,
            filetype,
            prompt
          )

          show_loading()
          call_ai(full_prompt, function(response)
            ensure_normal_buffer(filetype)
            local code_lines = extract_code(response)
            local row = vim.api.nvim_win_get_cursor(0)[1]
            vim.api.nvim_buf_set_lines(0, row, row, false, code_lines)
            vim.api.nvim_win_set_cursor(0, { row + #code_lines, 0 })
            vim.notify("✅ Code generated and inserted!", vim.log.levels.INFO)
          end, { temperature = 0.1 })
        end)
      end

      function M.fix_code()
        local s = vim.fn.getpos "'<"
        local e = vim.fn.getpos "'>"
        local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)

        if #lines == 0 then
          vim.notify("⚠️  Please select code to fix", vim.log.levels.WARN)
          return
        end

        local selected_code = table.concat(lines, "\n")
        local filetype = get_filetype()

        local prompt
        if learning_mode then
          prompt = string.format(
            [[
You are in Learning Mode. Find and fix bugs in this %s code, but DO NOT output the full file.
- Prefer minimal unified diff (patch) or the smallest changed snippets.
- If using patch, wrap it in a fenced code block with "diff" or "patch".
- Otherwise list concise steps and only show short code fragments that change.
- No extra prose outside the patch/snippets.

```%s
%s
```]],
            filetype,
            filetype,
            selected_code
          )
        else
          prompt = string.format(
            "Fix this %s code. Only return the corrected code, no explanations:\n\n```%s\n%s\n```",
            filetype,
            filetype,
            selected_code
          )
        end

        show_loading()
        call_ai(prompt, function(response)
          if learning_mode then
            local out = vim.split(response, "\n")
            open_float_markdown(out, "🎓 Fix Suggestions (Learning)")
          else
            ensure_normal_buffer(filetype)
            local fixed_lines = extract_code(response)
            vim.api.nvim_buf_set_lines(0, s[2] - 1, e[2], false, fixed_lines)
            vim.notify("✅ Code fixed!", vim.log.levels.INFO)
          end
        end, { temperature = 0.15 })
      end

      function M.explain_code()
        local s = vim.fn.getpos "'<"
        local e = vim.fn.getpos "'>"
        local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
        if #lines == 0 then
          vim.notify("⚠️  Please select code to explain", vim.log.levels.WARN)
          return
        end

        local selected_code = table.concat(lines, "\n")
        local filetype = get_filetype()
        local prompt =
          string.format("Explain this %s code step by step:\n\n```%s\n%s\n```", filetype, filetype, selected_code)
        show_loading()
        call_ai(prompt, function(response)
          local out = vim.split(response, "\n")
          open_float_markdown(out, "🤖 Code Explanation")
        end, { temperature = 0.2 })
      end

      function M.add_comments()
        local s = vim.fn.getpos "'<"
        local e = vim.fn.getpos "'>"
        local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
        if #lines == 0 then
          vim.notify("⚠️  Please select code to add comments", vim.log.levels.WARN)
          return
        end

        local selected_code = table.concat(lines, "\n")
        local filetype = get_filetype()
        local prompt = string.format(
          "Add helpful comments to this %s code. Return the code with comments added. Only return the commented code:\n\n```%s\n%s\n```",
          filetype,
          filetype,
          selected_code
        )
        show_loading()
        call_ai(prompt, function(response)
          ensure_normal_buffer(filetype)
          local commented_lines = extract_code(response)
          vim.api.nvim_buf_set_lines(0, s[2] - 1, e[2], false, commented_lines)
          vim.notify("✅ Comments added!", vim.log.levels.INFO)
        end, { temperature = 0.2 })
      end

      function M.enhance_code()
        local s = vim.fn.getpos "'<"
        local e = vim.fn.getpos "'>"
        local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
        if #lines == 0 then
          vim.notify("⚠️  Please select code to enhance", vim.log.levels.WARN)
          return
        end

        local selected_code = table.concat(lines, "\n")
        local filetype = get_filetype()
        local prompt = string.format(
          "Enhance and optimize this %s code. Make it more efficient, readable, and follow best practices. Only return the improved code:\n\n```%s\n%s\n```",
          filetype,
          filetype,
          selected_code
        )
        show_loading()
        call_ai(prompt, function(response)
          ensure_normal_buffer(filetype)
          local enhanced_lines = extract_code(response)
          vim.api.nvim_buf_set_lines(0, s[2] - 1, e[2], false, enhanced_lines)
          vim.notify("✅ Code enhanced!", vim.log.levels.INFO)
        end, { temperature = 0.2 })
      end

      function M.refactor_code()
        local s = vim.fn.getpos "'<"
        local e = vim.fn.getpos "'>"
        local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
        if #lines == 0 then
          vim.notify("⚠️  Please select code to refactor", vim.log.levels.WARN)
          return
        end

        local selected_code = table.concat(lines, "\n")
        local filetype = get_filetype()

        popup_input("🔄 Refactor Request", "Make it more modular...", function(refactor_request)
          local prompt = string.format(
            "Refactor this %s code based on this request: %s\n\nOriginal code:\n```%s\n%s\n```\n\nReturn only the refactored code:",
            filetype,
            refactor_request,
            filetype,
            selected_code
          )
          show_loading()
          call_ai(prompt, function(response)
            ensure_normal_buffer(filetype)
            local refactored_lines = extract_code(response)
            vim.api.nvim_buf_set_lines(0, s[2] - 1, e[2], false, refactored_lines)
            vim.notify("✅ Code refactored!", vim.log.levels.INFO)
          end, { temperature = 0.2 })
        end)
      end

      function M.generate_tests()
        local s = vim.fn.getpos "'<"
        local e = vim.fn.getpos "'>"
        local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
        if #lines == 0 then
          vim.notify("⚠️  Please select code to generate tests for", vim.log.levels.WARN)
          return
        end

        local selected_code = table.concat(lines, "\n")
        local filetype = get_filetype()
        local prompt = string.format(
          "Generate comprehensive unit tests for this %s code:\n\n```%s\n%s\n```\n\nReturn only the test code:",
          filetype,
          filetype,
          selected_code
        )
        show_loading()
        call_ai(prompt, function(response)
          ensure_normal_buffer(filetype)
          local test_lines = extract_code(response)
          vim.api.nvim_buf_set_lines(0, e[2], e[2], false, { "" })
          vim.api.nvim_buf_set_lines(0, e[2] + 1, e[2] + 1, false, test_lines)
          vim.notify("✅ Unit tests generated!", vim.log.levels.INFO)
        end, { temperature = 0.2 })
      end

      function M.complete_from_comment()
        local line = vim.api.nvim_get_current_line()
        local filetype = get_filetype()
        local comment_patterns = {
          python = "^%s*#",
          javascript = "^%s*//",
          typescript = "^%s*//",
          lua = "^%s*%-%-",
          rust = "^%s*//",
          go = "^%s*//",
          java = "^%s*//",
          cpp = "^%s*//",
          c = "^%s*//",
          sh = "^%s*#",
          cs = "^%s*//",
          csharp = "^%s*//",
          text = "^%s*[#>%-%/]+",
        }
        local pattern = comment_patterns[filetype] or "^%s*#"

        if not line:match(pattern) then
          vim.notify("⚠️  Cursor must be on a comment line", vim.log.levels.WARN)
          return
        end

        local comment_text = line:gsub(pattern, ""):gsub("^%s*", "")
        local prompt = string.format(
          "Generate %s code based on this comment: %s\n\nOnly return the code implementation, no explanations.",
          filetype,
          comment_text
        )
        show_loading()
        call_ai(prompt, function(response)
          ensure_normal_buffer(filetype)
          local code_lines = extract_code(response)
          local row = vim.api.nvim_win_get_cursor(0)[1]
          vim.api.nvim_buf_set_lines(0, row, row, false, code_lines)
          vim.notify("✅ Code generated from comment!", vim.log.levels.INFO)
        end, { temperature = 0.2 })
      end

      -- ========== C# Specialized ==========
      local function is_csharp()
        local ft = get_filetype()
        return ft == "cs" or ft == "csharp"
      end

      local function read_file(path)
        local ok, data = pcall(vim.fn.readfile, path)
        if not ok then return nil end
        return table.concat(data, "\n")
      end

      local function glob_csproj() return vim.fn.glob("**/*.csproj", true, true) end

      local function detect_cs_test_framework()
        local projects = glob_csproj()
        for _, p in ipairs(projects) do
          local content = read_file(p) or ""
          if content:find("PackageReference.-xunit", 1, false) or content:find("xunit", true) then
            return "xunit"
          elseif content:find("PackageReference.-nunit", 1, false) or content:find("nunit", true) then
            return "nunit"
          elseif content:find("PackageReference.-MSTest", 1, false) or content:find("MSTest", true) then
            return "mstest"
          end
        end
        return nil
      end

      local function run_cmd_show(cmd)
        local out = vim.fn.systemlist(cmd)
        open_float_markdown(out or { "(no output)" }, table.concat(cmd, " "))
      end

      function M.cs_add_xml_docs()
        if not is_csharp() then
          vim.notify("ℹ️ Switch to a C# buffer to add XML docs", vim.log.levels.INFO)
          return
        end
        local s = vim.fn.getpos "'<"
        local e = vim.fn.getpos "'>"
        local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
        if #lines == 0 then
          vim.notify("⚠️  Please select C# code to document", vim.log.levels.WARN)
          return
        end
        local code = table.concat(lines, "\n")
        local prompt = ([[Add C# XML triple-slash documentation comments to this code.
Use /// <summary>, /// <param>, /// <returns>, and /// <exception> where appropriate.
Return only the updated code with XML docs, do not add extra explanations.

```csharp
%s
```]]):format(code)
        show_loading()
        call_ai(prompt, function(resp)
          ensure_normal_buffer "cs"
          local updated = extract_code(resp)
          vim.api.nvim_buf_set_lines(0, s[2] - 1, e[2], false, updated)
          vim.notify("✅ XML docs added", vim.log.levels.INFO)
        end, { temperature = 0.2 })
      end

      function M.cs_refactor_async()
        if not is_csharp() then
          vim.notify("ℹ️ Switch to a C# buffer to refactor async", vim.log.levels.INFO)
          return
        end
        local s = vim.fn.getpos "'<"
        local e = vim.fn.getpos "'>"
        local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
        if #lines == 0 then
          vim.notify("⚠️  Please select method(s) to refactor", vim.log.levels.WARN)
          return
        end
        local code = table.concat(lines, "\n")
        local prompt = ([[Refactor the following C# methods to use async/await best practices:
- Introduce CancellationToken parameters when appropriate
- Propagate cancellation
- Use ConfigureAwait(false) in library code if helpful
- Preserve semantics and signatures where necessary
Return only the refactored code.

```csharp
%s
```]]):format(code)
        show_loading()
        call_ai(prompt, function(resp)
          ensure_normal_buffer "cs"
          local updated = extract_code(resp)
          vim.api.nvim_buf_set_lines(0, s[2] - 1, e[2], false, updated)
          vim.notify("✅ Refactored to async/await", vim.log.levels.INFO)
        end, { temperature = 0.2 })
      end

      function M.cs_generate_interface()
        if not is_csharp() then
          vim.notify("ℹ️ Switch to a C# buffer to generate interface", vim.log.levels.INFO)
          return
        end
        local s = vim.fn.getpos "'<"
        local e = vim.fn.getpos "'>"
        local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
        if #lines == 0 then
          vim.notify("⚠️  Please select class to extract interface", vim.log.levels.WARN)
          return
        end
        local code = table.concat(lines, "\n")
        local prompt = ([[From the following C# class, generate a clean public interface (methods, properties, events). 
Keep namespaces and attributes relevant if necessary. Return only the interface code.

```csharp
%s
```]]):format(code)
        show_loading()
        call_ai(prompt, function(resp)
          ensure_normal_buffer "cs"
          local iface = extract_code(resp)
          local row = e[2]
          vim.api.nvim_buf_set_lines(0, row, row, false, { "", "// Generated interface:" })
          vim.api.nvim_buf_set_lines(0, row + 1, row + 1, false, iface)
          vim.notify("✅ Interface generated", vim.log.levels.INFO)
        end, { temperature = 0.2 })
      end

      function M.cs_generate_tests()
        if not is_csharp() then
          vim.notify("ℹ️ Switch to a C# buffer to generate tests", vim.log.levels.INFO)
          return
        end
        local framework = detect_cs_test_framework() or "xunit"
        local s = vim.fn.getpos "'<"
        local e = vim.fn.getpos "'>"
        local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
        if #lines == 0 then
          vim.notify("⚠️  Please select C# code to generate tests for", vim.log.levels.WARN)
          return
        end
        local code = table.concat(lines, "\n")
        local prompt = ([[Generate comprehensive %s unit tests for the following C# code.
Use proper using statements and idioms. Return only the test code.

```csharp
%s
```]]):format(framework, code)
        show_loading()
        call_ai(prompt, function(resp)
          ensure_normal_buffer "cs"
          local test_lines = extract_code(resp)
          vim.api.nvim_buf_set_lines(0, e[2], e[2], false, { "" })
          vim.api.nvim_buf_set_lines(0, e[2] + 1, e[2] + 1, false, test_lines)
          vim.notify("✅ C# tests generated (" .. framework .. ")", vim.log.levels.INFO)
        end, { temperature = 0.2 })
      end

      function M.cs_build() run_cmd_show { "bash", "-lc", "dotnet build" } end
      function M.cs_test() run_cmd_show { "bash", "-lc", "dotnet test" } end
      function M.cs_format() run_cmd_show { "bash", "-lc", "dotnet format" } end

      -- ========== Agent Tools ==========
      local tools = {}

      tools.read_file = function(args)
        local p = args and args.path
        if not p or p == "" then return "ERROR: missing 'path'" end
        if not vim.loop.fs_stat(p) then return "ERROR: file not found: " .. p end
        local ok, content = pcall(vim.fn.readfile, p)
        if not ok then return "ERROR: cannot read file" end
        return table.concat(content, "\n")
      end

      tools.write_file = function(args)
        local p = args and args.path
        local content = args and args.content
        if not p or not content then return "ERROR: missing 'path' or 'content'" end
        local choice = vim.fn.confirm("Agent wants to write file:\n" .. p .. "\nProceed?", "&Yes\n&No", 2)
        if choice ~= 1 then return "DENIED by user" end
        local ok, err = pcall(function()
          vim.fn.mkdir(vim.fn.fnamemodify(p, ":h"), "p")
          vim.fn.writefile(vim.split(content, "\n", { plain = true }), p)
        end)
        if not ok then return "ERROR: " .. tostring(err) end
        return "OK: wrote file " .. p
      end

      tools.list_files = function(args)
        local dir = (args and args.dir) or "."
        local pattern = (args and args.pattern) or "**/*"
        local items = vim.fn.globpath(dir, pattern, true, true)
        local out = {}
        local maxn = 300
        for i, it in ipairs(items) do
          if i > maxn then
            table.insert(out, ("... (%d more)"):format(#items - maxn))
            break
          end
          table.insert(out, it)
        end
        return table.concat(out, "\n")
      end

      tools.search = function(args)
        local q = args and args.query
        local dir = (args and args.dir) or "."
        if not q or q == "" then return "ERROR: missing 'query'" end
        local cmd = { "rg", "-n", "--no-heading", "-S", q, dir }
        local out = vim.fn.systemlist(cmd)
        return table.concat(out or {}, "\n")
      end

      tools.get_buffer = function(args)
        local path = vim.api.nvim_buf_get_name(0)
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        return ("Current buffer: %s\n\n%s"):format(path, table.concat(lines, "\n"))
      end

      tools.run = function(args)
        local command = args and args.command
        if not command or command == "" then return "ERROR: missing 'command'" end
        local choice = vim.fn.confirm("Agent wants to run:\n" .. command .. "\nProceed?", "&Yes\n&No", 2)
        if choice ~= 1 then return "DENIED by user" end
        local out = vim.fn.systemlist(command)
        return table.concat(out or {}, "\n")
      end

      tools.dotnet_build = function(args)
        local target = (args and args.project) or ""
        local cmd = target ~= "" and ("dotnet build " .. target) or "dotnet build"
        local choice = vim.fn.confirm("Agent runs: " .. cmd .. "\nProceed?", "&Yes\n&No", 2)
        if choice ~= 1 then return "DENIED by user" end
        return table.concat(vim.fn.systemlist(cmd) or {}, "\n")
      end

      tools.dotnet_test = function(args)
        local target = (args and args.project) or ""
        local cmd = target ~= "" and ("dotnet test " .. target) or "dotnet test"
        local choice = vim.fn.confirm("Agent runs: " .. cmd .. "\nProceed?", "&Yes\n&No", 2)
        if choice ~= 1 then return "DENIED by user" end
        return table.concat(vim.fn.systemlist(cmd) or {}, "\n")
      end

      tools.dotnet_format = function(args)
        local target = (args and args.project) or ""
        local cmd = target ~= "" and ("dotnet format " .. target) or "dotnet format"
        local choice = vim.fn.confirm("Agent runs: " .. cmd .. "\nProceed?", "&Yes\n&No", 2)
        if choice ~= 1 then return "DENIED by user" end
        return table.concat(vim.fn.systemlist(cmd) or {}, "\n")
      end

      local function parse_tool_calls(text)
        local calls = {}
        for line in (text .. "\n"):gmatch "([^\n]*)\n" do
          local json = line:match "^%s*TOOL_CALL:%s*(%b{})%s*$"
          if json then
            local ok, obj = pcall(vim.fn.json_decode, json)
            if ok and obj and obj.name then table.insert(calls, { name = obj.name, args = obj.args or {} }) end
          end
        end
        return calls
      end

      -- ========== Chat Popup + Agent ==========
      local Popup = require "nui.popup"
      local Input = require "nui.input"
      local event = require("nui.utils.autocmd").event

      local chat_state = {
        agent_mode = false,
        busy = false,
        messages = {}, -- {role="user"/"assistant"/"tools", content=""}
      }

      local function build_system_instruction(is_agent, is_learning)
        local base = "You are a helpful software engineering assistant."
        local learn = ""
        if is_learning then
          learn =
            " You are in Learning Mode: provide minimal hints, small patches or concise diffs. Do not print full files. Prefer fenced code blocks with 'diff' or 'patch' when proposing changes."
        end
        local agent = ""
        if is_agent then
          agent =
            ' You can request tools by emitting lines \'TOOL_CALL: {"name":"...","args":{...}}\' and must eventually reply with a single line \'FINAL_ANSWER: ...\'.'
        end
        return base .. learn .. agent
      end

      local function render_chat_lines(buf, messages, header)
        vim.api.nvim_buf_set_option(buf, "modifiable", true)
        local out = {}
        if header and header ~= "" then
          table.insert(out, header)
          table.insert(out, "")
        end
        for _, m in ipairs(messages) do
          if m.role == "user" then
            table.insert(out, "🧑 You:")
            for _, l in ipairs(vim.split(m.content, "\n")) do
              table.insert(out, "> " .. l)
            end
            table.insert(out, "")
          elseif m.role == "assistant" then
            table.insert(out, "🤖 Assistant:")
            local lines = vim.split(m.content, "\n")
            for _, l in ipairs(lines) do
              table.insert(out, l)
            end
            table.insert(out, "")
          elseif m.role == "tools" then
            table.insert(out, "🛠 Tool Results:")
            local lines = vim.split(m.content, "\n")
            for _, l in ipairs(lines) do
              table.insert(out, "    " .. l)
            end
            table.insert(out, "")
          end
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
        vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
        vim.api.nvim_buf_set_option(buf, "modifiable", false)
      end

      -- Thay thế hoàn toàn hàm create_chat_ui cũ bằng phiên bản này
      local Popup = require "nui.popup"
      local Input = require "nui.input"

      local function create_chat_ui(title)
        local width = math.min(100, vim.o.columns - 10)
        local height = math.min(32, vim.o.lines - 8)

        -- Cửa sổ chat (transcript)
        local chat_popup = Popup {
          enter = true,
          focusable = true,
          border = { style = "rounded", text = { top = " " .. title .. " ", top_align = "center" } },
          position = "50%",
          size = { width = width, height = height },
          win_options = { winhighlight = "Normal:Normal,FloatBorder:FloatBorder" },
        }
        chat_popup:mount()
        local chat_buf = chat_popup.bufnr
        vim.api.nvim_buf_set_option(chat_buf, "filetype", "markdown")
        vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, { "Chat started. Type your message below." })

        -- Placeholder sender sẽ được set từ M.open_chat
        local send_message = function(_) end
        local input -- giữ tham chiếu input hiện tại

        -- Hàm tạo/mount input. Sau khi submit sẽ tự remount để nhắn tiếp.
        local function mount_input()
          if input and input._.mounted then pcall(function() input:unmount() end) end

          input = Input({
            position = { row = "100%", col = "50%" },
            relative = "editor",
            size = { width = width, height = 3 },
            border = { style = "rounded", text = { top = " Message ", top_align = "center" } },
            win_options = { winhighlight = "Normal:Normal,FloatBorder:FloatBorder" },
          }, {
            prompt = "❯ ",
            default_value = "",
            on_close = function() end,
            on_submit = function(value)
              -- Gửi tin nhắn
              if send_message then send_message(value) end
              -- Remount input để tiếp tục nhắn
              vim.defer_fn(function()
                if chat_popup and chat_popup._.mounted then mount_input() end
              end, 10)
            end,
          })

          input:mount()
        end

        -- Mount input lần đầu
        mount_input()

        -- Đóng cả chat + input
        local function close_all()
          pcall(function()
            if input and input._.mounted then input:unmount() end
          end)
          pcall(function()
            if chat_popup and chat_popup._.mounted then chat_popup:unmount() end
          end)
        end

        -- Hotkeys đóng chat
        vim.keymap.set("n", "q", close_all, { buffer = chat_buf, nowait = true })
        vim.keymap.set("n", "<Esc>", close_all, { buffer = chat_buf, nowait = true })

        return {
          popup = chat_popup,
          buf = chat_buf,
          close = close_all,
          -- Cho phép M.open_chat set function gửi
          set_sender = function(fn) send_message = fn end,
          -- (tuỳ chọn) public API nếu cần remount input thủ công
          remount_input = mount_input,
        }
      end
      local function agent_converse(prompt, on_update, on_done)
        local max_steps = 6
        local step = 0
        local transcript = {}

        local function push(role, content) table.insert(transcript, ("[%s]\n%s\n"):format(role, content)) end

        local system = build_system_instruction(true, learning_mode)
        local tools_desc = [[
Available tools (call with: TOOL_CALL: {"name":"<tool_name>","args":{...}}):
- read_file(path)
- write_file(path, content)    [confirmation required]
- list_files(dir=".", pattern="**/*")
- search(query, dir=".")
- get_buffer()
- run(command)                  [confirmation required]
- dotnet_build(project?)        [confirmation required]
- dotnet_test(project?)         [confirmation required]
- dotnet_format(project?)       [confirmation required]
End your work with: FINAL_ANSWER: <...>]]

        push("SYSTEM", system .. "\n\n" .. tools_desc)
        push("USER", prompt)

        local function loop()
          step = step + 1
          if step > max_steps then
            on_done "Reached max steps without FINAL_ANSWER."
            return
          end

          local p = table.concat(transcript, "\n")
            .. ("\n[ASSISTANT]\nStep %d: Think, optionally call tools. Then finish with FINAL_ANSWER when done.\n"):format(
              step
            )

          call_ai(p, function(resp)
            on_update("assistant", resp)

            local final = resp:match "FINAL_ANSWER:%s*(.+)"
            if final and final ~= "" then
              on_done(final)
              return
            end

            local calls = parse_tool_calls(resp)
            if #calls == 0 then
              table.insert(transcript, ("[%s]\n%s\n"):format("ASSISTANT", resp))
              return loop()
            end

            local results = {}
            for _, c in ipairs(calls) do
              local out = "ERROR: tools unavailable"
              if tools[c.name] then
                local ok, val = pcall(tools[c.name], c.args or {})
                if ok then
                  out = val
                else
                  out = "ERROR: " .. tostring(val)
                end
              end
              table.insert(results, ("TOOL_RESULT[%s]:\n%s\nEND_TOOL_RESULT"):format(c.name, out))
            end
            local tool_block = table.concat(results, "\n\n")
            on_update("tools", tool_block)

            table.insert(transcript, ("[%s]\n%s\n"):format("ASSISTANT", resp))
            table.insert(transcript, ("[%s]\n%s\n"):format("TOOLS", tool_block))
            loop()
          end, { temperature = 0.2, system = system })
        end

        loop()
      end

      local function build_chat_prompt(user_msg, is_learning)
        local ft = get_filetype()
        local head = ("Filetype: %s\n"):format(ft)
        local lines = vim.api.nvim_buf_get_lines(0, 0, 80, false)
        if #lines > 0 then
          head = head
            .. "Context (first lines of current buffer):\n"
            .. table.concat(lines, "\n", 1, math.min(30, #lines))
            .. "\n\n"
        end
        local instr = build_system_instruction(false, is_learning)
        local prompt = instr .. "\n\n" .. head .. user_msg
        return prompt
      end

      function M.open_chat(opts)
        opts = opts or {}
        chat_state.agent_mode = opts.agent_mode or false
        chat_state.messages = {}
        chat_state.busy = false

        local function titleline()
          local prov = (current_provider or "ollama")
          local model = (prov == "gemini") and (current_gemini_model or "?") or (current_ollama_model or "?")
          local agent = chat_state.agent_mode and "Agent:ON" or "Agent:OFF"
          local learn = learning_mode and "Learn:ON" or "Learn:OFF"
          return ("AI Chat [%s/%s] [%s] [%s]"):format(prov, model, agent, learn)
        end

        local ui = create_chat_ui(titleline())
        local function refresh_title() ui.popup.border:set_text("top", " " .. titleline() .. " ") end

        local function append(role, content)
          table.insert(chat_state.messages, { role = role, content = content })
          render_chat_lines(ui.buf, chat_state.messages, "")
        end

        local function send_message(text)
          if chat_state.busy then
            vim.notify("⏳ Model is busy, please wait...", vim.log.levels.WARN)
            return
          end
          if not text or text:gsub("%s+", "") == "" then return end

          chat_state.busy = true
          append("user", text)
          show_loading()

          if chat_state.agent_mode then
            agent_converse(text, function(role, content) append(role, content) end, function(final)
              append("assistant", "FINAL_ANSWER: " .. final)
              chat_state.busy = false
            end)
          else
            local prompt = build_chat_prompt(text, learning_mode)
            call_ai(prompt, function(resp)
              append("assistant", resp)
              chat_state.busy = false
            end, { temperature = 0.2 })
          end
          refresh_title()
        end

        ui.set_sender(send_message)

        -- In-chat hotkeys
        vim.keymap.set("n", "a", function()
          chat_state.agent_mode = not chat_state.agent_mode
          refresh_title()
          vim.notify("🤖 Agent mode: " .. (chat_state.agent_mode and "ON" or "OFF"), vim.log.levels.INFO)
        end, { buffer = ui.buf })

        vim.keymap.set("n", "l", function()
          learning_mode = not learning_mode
          refresh_title()
          vim.notify("🎓 Learning mode: " .. (learning_mode and "ON" or "OFF"), vim.log.levels.INFO)
        end, { buffer = ui.buf })

        vim.keymap.set("n", "p", function()
          M.smart_provider_menu()
          refresh_title()
        end, { buffer = ui.buf })

        -- Initial header
        render_chat_lines(
          ui.buf,
          chat_state.messages,
          "Tips: type then <Enter> to send | a:Agent l:Learn p:Provider q/Esc:close"
        )
      end

      function M.open_agent_chat() return M.open_chat { agent_mode = true } end

      -- ========== Smart Provider/Model/API ==========
      function M.set_gemini_key(cb)
        local function set_key(k)
          gemini_api_key = k
          vim.g.smart_ai_gemini_api_key = k
          vim.notify("✅ Gemini API key set for this session", vim.log.levels.INFO)
          if type(cb) == "function" then cb() end
        end
        if gemini_api_key and gemini_api_key ~= "" then
          local choice = vim.fn.confirm("A Gemini API key already exists.\nReplace it?", "&Yes\n&No", 2)
          if choice ~= 1 then return end
        end
        local Input = require "nui.input"
        local event = require("nui.utils.autocmd").event
        local input = Input({
          position = "50%",
          size = { width = 72, height = 3 },
          border = { style = "rounded", text = { top = " 🔑 Set GEMINI_API_KEY ", top_align = "center" } },
          win_options = { winhighlight = "Normal:Normal,FloatBorder:FloatBorder" },
        }, {
          prompt = "❯ ",
          default_value = "",
          on_submit = function(value)
            if value and value ~= "" then set_key(value) end
          end,
        })
        input:mount()
        input:on(event.BufLeave, function() input:unmount() end)
      end

      function M.smart_provider_menu()
        local providers = {
          { name = "🖥️ Local (Ollama)", id = "ollama" },
          { name = "☁️ Cloud (Gemini)", id = "gemini" },
        }
        vim.ui.select(providers, {
          prompt = "Select Provider:",
          format_item = function(item) return item.name .. ((item.id == current_provider) and " ✅" or "") end,
        }, function(choice)
          if not choice then return end
          current_provider = choice.id
          vim.notify("🔀 Provider: " .. choice.name, vim.log.levels.INFO)

          if current_provider == "ollama" then
            vim.ui.select(ollama_models, {
              prompt = "Select Local (Ollama) Model:",
              format_item = function(i) return i.name .. ((i.id == current_ollama_model) and " ✅" or "") end,
            }, function(m)
              if m then
                current_ollama_model = m.id
                vim.notify("🚀 Local model: " .. m.name, vim.log.levels.INFO)
              end
            end)
          else
            local function select_gemini_model()
              vim.ui.select(gemini_models, {
                prompt = "Select Gemini Model:",
                format_item = function(i) return i.name .. ((i.id == current_gemini_model) and " ✅" or "") end,
              }, function(m)
                if m then
                  current_gemini_model = m.id
                  vim.notify("☁️ Gemini model: " .. m.name, vim.log.levels.INFO)
                end
              end)
            end

            if not gemini_api_key or gemini_api_key == "" then
              vim.notify("🔑 No GEMINI_API_KEY found. Please enter one.", vim.log.levels.WARN)
              return M.set_gemini_key(function() select_gemini_model() end)
            else
              select_gemini_model()
            end
          end
        end)
      end

      -- ========== Actions Menu ==========
      function M.open_actions_menu()
        local ft = get_filetype()
        local is_cs = (ft == "cs" or ft == "csharp")

        local items = {
          { label = "💬 Chat (popup)", fn = function() M.open_chat() end },
          { label = "🧭 Agent Chat (popup)", fn = function() M.open_agent_chat() end },
          { label = "🎓 Toggle Learning Mode", fn = function() M.toggle_learning_mode() end },
          { label = "—", sep = true },
          { label = "🤖 Generate & Insert", fn = M.generate_and_insert },
          { label = "🔧 Fix Selected Code", fn = M.fix_code },
          { label = "📖 Explain Selected Code", fn = M.explain_code },
          { label = "💬 Add Comments", fn = M.add_comments },
          { label = "⚡ Enhance Code", fn = M.enhance_code },
          { label = "🔄 Refactor Code", fn = M.refactor_code },
          { label = "🧪 Generate Tests", fn = M.generate_tests },
          { label = "💡 Complete from Comment", fn = M.complete_from_comment },
        }
        if is_cs then
          table.insert(items, { label = "—", sep = true })
          table.insert(items, { label = "C# ▶ Add XML Docs", fn = M.cs_add_xml_docs })
          table.insert(items, { label = "C# ▶ Refactor to async/await", fn = M.cs_refactor_async })
          table.insert(items, { label = "C# ▶ Generate Interface", fn = M.cs_generate_interface })
          table.insert(items, { label = "C# ▶ Generate Tests", fn = M.cs_generate_tests })
          table.insert(items, { label = "C# ▶ dotnet build", fn = M.cs_build })
          table.insert(items, { label = "C# ▶ dotnet test", fn = M.cs_test })
          table.insert(items, { label = "C# ▶ dotnet format", fn = M.cs_format })
        end

        local menu = {}
        for _, it in ipairs(items) do
          if it.sep then
            table.insert(menu, { title = true, text = "────────────" })
          else
            table.insert(menu, it)
          end
        end

        vim.ui.select(menu, {
          prompt = "Smart AI Actions:",
          format_item = function(it)
            if it.title then return it.text end
            return it.label
          end,
        }, function(choice)
          if not choice or choice.title then return end
          choice.fn()
        end)
      end

      -- ========== Keymaps: 3 phím chính ==========
      vim.keymap.set("n", "<leader>ap", M.smart_provider_menu, { desc = "🌐 Provider/Model/API (Smart)" })
      vim.keymap.set("n", "<leader>ak", function() M.set_gemini_key() end, { desc = "🔑 Set Gemini API Key" })
      vim.keymap.set("n", "<leader>aa", M.open_actions_menu, { desc = "📦 Smart AI Actions Menu" })

      _G.SmartOllama = M

      vim.notify("🚀 Smart AI loaded! Keys: <leader>ap / <leader>ak / <leader>aa", vim.log.levels.INFO)
    end,
  },
}
