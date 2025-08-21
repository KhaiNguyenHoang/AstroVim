-- dotnet-nvim/init.lua
-- Plugin để tạo class C#/.NET dễ dàng trong Neovim

local M = {}

-- Cấu hình mặc định
local config = {
  default_namespace = "MyProject",
  templates_dir = vim.fn.stdpath "data" .. "/dotnet-nvim/templates",
  keymaps = {
    create_class = "<leader>dc",
    create_interface = "<leader>di",
    create_controller = "<leader>dr",
    create_model = "<leader>dm",
  },
}

-- Hàm tạo thư mục nếu chưa tồn tại
local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then vim.fn.mkdir(path, "p") end
end

-- Hàm lấy namespace từ đường dẫn
local function get_namespace_from_path(file_path)
  local cwd = vim.fn.getcwd()
  local relative_path = string.gsub(file_path, cwd .. "/", "")
  local namespace = string.gsub(relative_path, "/", ".")
  -- Loại bỏ filename
  namespace = string.gsub(namespace, "/[^/]*$", "")
  return namespace ~= "" and namespace or config.default_namespace
end

-- Template cho các loại class khác nhau
local templates = {
  class = [[using System;

namespace {namespace}
{
    public class {classname}
    {
        // Constructor
        public {classname}()
        {
            
        }
    }
}]],

  interface = [[using System;

namespace {namespace}
{
    public interface I{classname}
    {
        
    }
}]],

  controller = [[using Microsoft.AspNetCore.Mvc;

namespace {namespace}.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class {classname}Controller : ControllerBase
    {
        [HttpGet]
        public IActionResult Get()
        {
            return Ok();
        }
    }
}]],

  model = [[using System;
using System.ComponentModel.DataAnnotations;

namespace {namespace}.Models
{
    public class {classname}
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string Name { get; set; } = string.Empty;
        
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}]],
}

-- Hàm tạo file từ template
local function create_file_from_template(template_type, namespace, classname, file_path)
  local template = templates[template_type]
  if not template then
    vim.notify("Template không tồn tại: " .. template_type, vim.log.levels.ERROR)
    return false
  end

  -- Thay thế placeholder
  local content = string.gsub(template, "{namespace}", namespace)
  content = string.gsub(content, "{classname}", classname)

  -- Tạo thư mục nếu cần
  local dir = vim.fn.fnamemodify(file_path, ":h")
  ensure_dir(dir)

  -- Ghi file
  local file = io.open(file_path, "w")
  if file then
    file:write(content)
    file:close()
    return true
  else
    vim.notify("Không thể tạo file: " .. file_path, vim.log.levels.ERROR)
    return false
  end
end

-- UI để nhập thông tin
local function create_class_ui(template_type)
  local current_dir = vim.fn.expand "%:p:h"
  local namespace = get_namespace_from_path(current_dir)

  -- Input directory
  vim.ui.input({
    prompt = "📁 Thư mục (Enter = current): ",
    default = current_dir,
    completion = "dir",
  }, function(directory)
    if not directory then return end

    -- Input class name
    vim.ui.input({
      prompt = "📝 Tên " .. template_type .. ": ",
      default = "",
    }, function(classname)
      if not classname or classname == "" then
        vim.notify("Tên class không được để trống!", vim.log.levels.WARN)
        return
      end

      -- Validate class name
      if not string.match(classname, "^[A-Za-z][A-Za-z0-9_]*$") then
        vim.notify("Tên class không hợp lệ! Chỉ sử dụng chữ cái, số và _", vim.log.levels.ERROR)
        return
      end

      -- Create file path
      local file_extension = ".cs"
      local filename = classname .. file_extension
      local file_path = directory .. "/" .. filename

      -- Check if file exists
      if vim.fn.filereadable(file_path) == 1 then
        vim.ui.select({ "Có", "Không" }, {
          prompt = "File đã tồn tại! Ghi đè?",
        }, function(choice)
          if choice == "Có" then
            if create_file_from_template(template_type, namespace, classname, file_path) then
              vim.cmd("edit " .. file_path)
              vim.notify("✅ Tạo " .. template_type .. " thành công: " .. filename, vim.log.levels.INFO)
            end
          end
        end)
      else
        if create_file_from_template(template_type, namespace, classname, file_path) then
          vim.cmd("edit " .. file_path)
          vim.notify("✅ Tạo " .. template_type .. " thành công: " .. filename, vim.log.levels.INFO)
        end
      end
    end)
  end)
end

-- Hàm tạo project structure
local function create_project_structure()
  vim.ui.input({
    prompt = "📁 Tên project: ",
    default = "MyDotNetProject",
  }, function(project_name)
    if not project_name or project_name == "" then return end

    local current_dir = vim.fn.getcwd()
    local project_dir = current_dir .. "/" .. project_name

    -- Tạo structure
    local dirs = {
      project_dir,
      project_dir .. "/Controllers",
      project_dir .. "/Models",
      project_dir .. "/Services",
      project_dir .. "/Data",
      project_dir .. "/Views",
      project_dir .. "/wwwroot",
    }

    for _, dir in ipairs(dirs) do
      ensure_dir(dir)
    end

    -- Tạo Program.cs
    local program_content = [[using Microsoft.AspNetCore;

namespace ]] .. project_name .. [[

{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateWebHostBuilder(args).Build().Run();
        }

        public static IWebHostBuilder CreateWebHostBuilder(string[] args) =>
            WebHost.CreateDefaultBuilder(args)
                .UseStartup<Startup>();
    }
}]]

    local program_file = io.open(project_dir .. "/Program.cs", "w")
    if program_file then
      program_file:write(program_content)
      program_file:close()
    end

    vim.notify("✅ Tạo project structure thành công: " .. project_name, vim.log.levels.INFO)
    vim.cmd("cd " .. project_dir)
  end)
end

-- Hàm setup plugin
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  -- Tạo commands
  vim.api.nvim_create_user_command(
    "DotNetCreateClass",
    function() create_class_ui "class" end,
    { desc = "Tạo C# Class" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateInterface",
    function() create_class_ui "interface" end,
    { desc = "Tạo C# Interface" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateController",
    function() create_class_ui "controller" end,
    { desc = "Tạo ASP.NET Controller" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateModel",
    function() create_class_ui "model" end,
    { desc = "Tạo C# Model" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateProject",
    function() create_project_structure() end,
    { desc = "Tạo .NET Project Structure" }
  )

  -- Setup keymaps
  if config.keymaps then
    vim.keymap.set(
      "n",
      config.keymaps.create_class,
      ":DotNetCreateClass<CR>",
      { desc = "Tạo C# Class", silent = true }
    )
    vim.keymap.set(
      "n",
      config.keymaps.create_interface,
      ":DotNetCreateInterface<CR>",
      { desc = "Tạo C# Interface", silent = true }
    )
    vim.keymap.set(
      "n",
      config.keymaps.create_controller,
      ":DotNetCreateController<CR>",
      { desc = "Tạo Controller", silent = true }
    )
    vim.keymap.set("n", config.keymaps.create_model, ":DotNetCreateModel<CR>", { desc = "Tạo Model", silent = true })
  end
end

-- Export functions
M.create_class = function() create_class_ui "class" end
M.create_interface = function() create_class_ui "interface" end
M.create_controller = function() create_class_ui "controller" end
M.create_model = function() create_class_ui "model" end
M.create_project = create_project_structure

return M
