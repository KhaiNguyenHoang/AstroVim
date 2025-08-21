-- dotnet-nvim/init.lua
-- Plugin nâng cấp để tạo mọi loại file C#/.NET và project trong Neovim

local M = {}

-- Cấu hình mặc định
local config = {
  default_namespace = "MyProject",
  default_directory = vim.fn.getcwd(),
  keymaps = {
    create_menu = "<leader>dn",
    create_class = "<leader>dc",
    create_interface = "<leader>di",
    create_controller = "<leader>dr",
    create_model = "<leader>dm",
    create_service = "<leader>ds",
    create_repository = "<leader>dp",
    create_project = "<leader>dP",
  },
}

-- Các loại project template sử dụng dotnet new
local project_templates = {
  console = {
    name = "🖥️  Console Application",
    description = "Ứng dụng console đơn giản",
    template = "console",
    language = "C#",
  },

  webapi = {
    name = "🌐 ASP.NET Core Web API",
    description = "Web API với Swagger, CORS",
    template = "webapi",
    language = "C#",
    options = "--use-controllers",
  },

  mvc = {
    name = "🎭 ASP.NET Core MVC",
    description = "MVC Web Application",
    template = "mvc",
    language = "C#",
  },

  webapp = {
    name = "🌍 ASP.NET Core Web App",
    description = "Web App (Razor Pages)",
    template = "webapp",
    language = "C#",
  },

  blazorserver = {
    name = "🔥 Blazor Server",
    description = "Blazor Server Application",
    template = "blazorserver",
    language = "C#",
  },

  blazorwasm = {
    name = "✨ Blazor WebAssembly",
    description = "Blazor WebAssembly Client",
    template = "blazorwasm",
    language = "C#",
  },

  blazor = {
    name = "🚀 Blazor Web App (.NET 8)",
    description = "Blazor Web App mới nhất",
    template = "blazor",
    language = "C#",
  },

  classlib = {
    name = "📚 Class Library",
    description = "Class Library (.NET Standard)",
    template = "classlib",
    language = "C#",
  },

  winforms = {
    name = "🪟 Windows Forms",
    description = "Windows Forms Application",
    template = "winforms",
    language = "C#",
  },

  wpf = {
    name = "🎨 WPF Application",
    description = "Windows Presentation Foundation",
    template = "wpf",
    language = "C#",
  },

  worker = {
    name = "⚙️ Worker Service",
    description = "Background Service/Worker",
    template = "worker",
    language = "C#",
  },

  grpc = {
    name = "🔗 gRPC Service",
    description = "gRPC Service Application",
    template = "grpc",
    language = "C#",
  },

  xunit = {
    name = "🧪 xUnit Test Project",
    description = "Unit Test với xUnit",
    template = "xunit",
    language = "C#",
  },

  nunit = {
    name = "🔬 NUnit Test Project",
    description = "Unit Test với NUnit",
    template = "nunit",
    language = "C#",
  },

  mstest = {
    name = "🧮 MSTest Project",
    description = "Unit Test với MSTest",
    template = "mstest",
    language = "C#",
  },

  razor = {
    name = "📄 Razor Class Library",
    description = "Razor Components Library",
    template = "razorclasslib",
    language = "C#",
  },

  solution = {
    name = "📁 Solution File",
    description = "Tạo .sln solution file",
    template = "sln",
    language = "",
  },
}

-- Template cho các file C#
local file_templates = {
  -- 📝 Basic Types
  class = {
    template = [[using System;

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
    description = "Basic C# Class",
  },

  abstract_class = {
    template = [[using System;

namespace {namespace}
{
    public abstract class {classname}
    {
        // Abstract method
        public abstract void DoSomething();
        
        // Virtual method
        public virtual void Process()
        {
            // Default implementation
        }
    }
}]],
    description = "Abstract Class",
  },

  interface = {
    template = [[using System;
using System.Threading.Tasks;

namespace {namespace}
{
    public interface I{classname}
    {
        Task<T> GetAsync<T>(int id);
        Task<IEnumerable<T>> GetAllAsync<T>();
        Task<T> CreateAsync<T>(T entity);
        Task<T> UpdateAsync<T>(T entity);
        Task DeleteAsync(int id);
    }
}]],
    description = "Interface",
  },

  record = {
    template = [[using System;

namespace {namespace}
{
    public record {classname}(int Id, string Name, DateTime CreatedAt);
}]],
    description = "Record Class",
  },

  enum_basic = {
    template = [[namespace {namespace}
{
    public enum {classname}
    {
        None = 0,
        Active = 1,
        Inactive = 2,
        Pending = 3
    }
}]],
    description = "Basic Enum",
  },

  controller = {
    template = [[using Microsoft.AspNetCore.Mvc;

namespace {namespace}.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class {classname}Controller : ControllerBase
    {
        [HttpGet]
        public IActionResult Get()
        {
            return Ok("Hello from {classname}Controller!");
        }

        [HttpGet("{id}")]
        public IActionResult Get(int id)
        {
            return Ok($"Getting item with ID: {id}");
        }

        [HttpPost]
        public IActionResult Post([FromBody] object model)
        {
            return CreatedAtAction(nameof(Get), new { id = 1 }, model);
        }

        [HttpPut("{id}")]
        public IActionResult Put(int id, [FromBody] object model)
        {
            return Ok($"Updated item {id}");
        }

        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            return NoContent();
        }
    }
}]],
    description = "Web API Controller",
  },

  model = {
    template = [[using System;
using System.ComponentModel.DataAnnotations;

namespace {namespace}.Models
{
    public class {classname}
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;
        
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? UpdatedAt { get; set; }
    }
}]],
    description = "Data Model",
  },

  service = {
    template = [[using System;
using System.Threading.Tasks;

namespace {namespace}.Services
{
    public interface I{classname}Service
    {
        Task<T> GetByIdAsync<T>(int id);
        Task<IEnumerable<T>> GetAllAsync<T>();
        Task<T> CreateAsync<T>(T entity);
        Task<T> UpdateAsync<T>(T entity);
        Task DeleteAsync(int id);
    }

    public class {classname}Service : I{classname}Service
    {
        public async Task<T> GetByIdAsync<T>(int id)
        {
            // Implementation here
            await Task.CompletedTask;
            throw new NotImplementedException();
        }

        public async Task<IEnumerable<T>> GetAllAsync<T>()
        {
            // Implementation here
            await Task.CompletedTask;
            throw new NotImplementedException();
        }

        public async Task<T> CreateAsync<T>(T entity)
        {
            // Implementation here
            await Task.CompletedTask;
            throw new NotImplementedException();
        }

        public async Task<T> UpdateAsync<T>(T entity)
        {
            // Implementation here
            await Task.CompletedTask;
            throw new NotImplementedException();
        }

        public async Task DeleteAsync(int id)
        {
            // Implementation here
            await Task.CompletedTask;
            throw new NotImplementedException();
        }
    }
}]],
    description = "Service with Interface",
  },

  repository = {
    template = [[using System;
using System.Linq.Expressions;

namespace {namespace}.Repositories
{
    public interface I{classname}Repository<T> where T : class
    {
        Task<T?> GetByIdAsync(int id);
        Task<IEnumerable<T>> GetAllAsync();
        Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
        Task<T> AddAsync(T entity);
        Task<T> UpdateAsync(T entity);
        Task DeleteAsync(int id);
        Task<bool> ExistsAsync(int id);
    }

    public class {classname}Repository<T> : I{classname}Repository<T> where T : class
    {
        public async Task<T?> GetByIdAsync(int id)
        {
            // Implementation here
            await Task.CompletedTask;
            throw new NotImplementedException();
        }

        public async Task<IEnumerable<T>> GetAllAsync()
        {
            // Implementation here  
            await Task.CompletedTask;
            throw new NotImplementedException();
        }

        public async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate)
        {
            // Implementation here
            await Task.CompletedTask;
            throw new NotImplementedException();
        }

        public async Task<T> AddAsync(T entity)
        {
            // Implementation here
            await Task.CompletedTask;
            throw new NotImplementedException();
        }

        public async Task<T> UpdateAsync(T entity)
        {
            // Implementation here
            await Task.CompletedTask;
            throw new NotImplementedException();
        }

        public async Task DeleteAsync(int id)
        {
            // Implementation here
            await Task.CompletedTask;
        }

        public async Task<bool> ExistsAsync(int id)
        {
            // Implementation here
            await Task.CompletedTask;
            return false;
        }
    }
}]],
    description = "Generic Repository",
  },

  dto = {
    template = [[using System;
using System.ComponentModel.DataAnnotations;

namespace {namespace}.DTOs
{
    public class {classname}Dto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    public class Create{classname}Dto
    {
        [Required]
        [StringLength(100, MinimumLength = 2)]
        public string Name { get; set; } = string.Empty;
    }

    public class Update{classname}Dto
    {
        [Required]
        [StringLength(100, MinimumLength = 2)]
        public string Name { get; set; } = string.Empty;
    }
}]],
    description = "Data Transfer Objects",
  },

  middleware = {
    template = [[using Microsoft.AspNetCore.Http;

namespace {namespace}.Middleware
{
    public class {classname}Middleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<{classname}Middleware> _logger;

        public {classname}Middleware(RequestDelegate next, ILogger<{classname}Middleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            _logger.LogInformation("{classname}Middleware: Before request");
            
            await _next(context);
            
            _logger.LogInformation("{classname}Middleware: After request");
        }
    }

    // Extension method for easy registration
    public static class {classname}MiddlewareExtensions
    {
        public static IApplicationBuilder Use{classname}(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<{classname}Middleware>();
        }
    }
}]],
    description = "ASP.NET Middleware",
  },

  test = {
    template = [[using Xunit;
using FluentAssertions;

namespace {namespace}.Tests
{
    public class {classname}Tests
    {
        [Fact]
        public void Should_Return_True_When_Valid_Input()
        {
            // Arrange
            var sut = new {classname}();
            
            // Act
            var result = true; // Replace with actual method call
            
            // Assert
            result.Should().BeTrue();
        }

        [Theory]
        [InlineData(1, "expected1")]
        [InlineData(2, "expected2")]
        public void Should_Return_Expected_Value_For_Input(int input, string expected)
        {
            // Arrange
            var sut = new {classname}();
            
            // Act
            var result = expected; // Replace with actual method call
            
            // Assert
            result.Should().Be(expected);
        }
    }
}]],
    description = "xUnit Test Class",
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
  -- Loại bỏ filename và extension
  namespace = string.gsub(namespace, "/[^/]*$", "")
  namespace = string.gsub(namespace, "%.cs$", "")
  return namespace ~= "" and namespace or config.default_namespace
end

-- Hàm chạy dotnet command
local function run_dotnet_command(cmd, directory, callback, options)
  options = options or {}
  local original_cwd = vim.fn.getcwd()
  local output_buffer = {}
  local error_buffer = {}

  -- Change to target directory
  if directory and vim.fn.isdirectory(directory) == 1 then vim.cmd("cd " .. vim.fn.fnameescape(directory)) end

  local job_id = vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      -- Restore original directory
      vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))

      if callback then callback(exit_code, output_buffer, error_buffer) end
    end,
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output_buffer, line)
            if not options.silent then vim.notify(line, vim.log.levels.INFO) end
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(error_buffer, line)
            if not options.silent then vim.notify(line, vim.log.levels.ERROR) end
          end
        end
      end
    end,
  })

  return job_id
end

-- Hàm tìm project file trong directory
local function find_project_file(directory)
  directory = directory or vim.fn.getcwd()
  local project_patterns = { "*.csproj", "*.fsproj", "*.vbproj" }

  for _, pattern in ipairs(project_patterns) do
    local files = vim.fn.glob(directory .. "/" .. pattern, false, true)
    if #files > 0 then return files[1] end
  end

  -- Tìm trong parent directories
  local parent = vim.fn.fnamemodify(directory, ":h")
  if parent ~= directory then return find_project_file(parent) end

  return nil
end

-- Hàm tìm solution file
local function find_solution_file(directory)
  directory = directory or vim.fn.getcwd()
  local files = vim.fn.glob(directory .. "/*.sln", false, true)
  if #files > 0 then return files[1] end

  -- Tìm trong parent directories
  local parent = vim.fn.fnamemodify(directory, ":h")
  if parent ~= directory then return find_solution_file(parent) end

  return nil
end

-- Development Workflow Commands
local workflow_commands = {
  build = {
    name = "🔨 Build Project",
    description = "Build the current project",
    command = "build",
  },

  build_release = {
    name = "🚀 Build Release",
    description = "Build project in Release mode",
    command = "build",
    args = { "-c", "Release" },
  },

  clean = {
    name = "🧹 Clean Project",
    description = "Clean build artifacts",
    command = "clean",
  },

  restore = {
    name = "📦 Restore Packages",
    description = "Restore NuGet packages",
    command = "restore",
  },

  run = {
    name = "▶️  Run Project",
    description = "Run the current project",
    command = "run",
  },

  watch = {
    name = "👁️  Watch & Run",
    description = "Run with hot reload (dotnet watch run)",
    command = "watch",
    args = { "run" },
  },

  test = {
    name = "🧪 Run Tests",
    description = "Run all tests in solution/project",
    command = "test",
  },

  test_verbose = {
    name = "📝 Run Tests (Verbose)",
    description = "Run tests with detailed output",
    command = "test",
    args = { "-v", "detailed" },
  },

  publish = {
    name = "📤 Publish Project",
    description = "Publish project for deployment",
    command = "publish",
  },

  publish_release = {
    name = "🎯 Publish Release",
    description = "Publish in Release mode",
    command = "publish",
    args = { "-c", "Release" },
  },
}

-- Hàm execute workflow command
local function execute_workflow_command(cmd_key, custom_args)
  local cmd_info = workflow_commands[cmd_key]
  if not cmd_info then
    vim.notify("Command không tồn tại: " .. cmd_key, vim.log.levels.ERROR)
    return
  end

  local project_file = find_project_file()
  local solution_file = find_solution_file()

  if not project_file and not solution_file then
    vim.notify("❌ Không tìm thấy project hoặc solution file!", vim.log.levels.ERROR)
    return
  end

  -- Build command
  local cmd = { "dotnet", cmd_info.command }

  -- Add default args
  if cmd_info.args then
    for _, arg in ipairs(cmd_info.args) do
      table.insert(cmd, arg)
    end
  end

  -- Add custom args
  if custom_args then
    for _, arg in ipairs(custom_args) do
      table.insert(cmd, arg)
    end
  end

  local work_dir = vim.fn.getcwd()
  vim.notify("🚀 " .. cmd_info.description .. "...", vim.log.levels.INFO)

  run_dotnet_command(cmd, work_dir, function(exit_code, output, errors)
    if exit_code == 0 then
      vim.notify("✅ " .. cmd_info.description .. " thành công!", vim.log.levels.INFO)

      -- Special handling for some commands
      if cmd_key == "test" or cmd_key == "test_verbose" then
        -- Show test results summary
        local test_summary = {}
        for _, line in ipairs(output) do
          if line:match "Total tests:" or line:match "Passed:" or line:match "Failed:" or line:match "Skipped:" then
            table.insert(test_summary, line)
          end
        end

        if #test_summary > 0 then
          vim.notify("📊 Test Results:\n" .. table.concat(test_summary, "\n"), vim.log.levels.INFO)
        end
      end
    else
      vim.notify("❌ " .. cmd_info.description .. " thất bại!", vim.log.levels.ERROR)

      -- Show error details
      if #errors > 0 then
        local error_msg = table.concat(errors, "\n")
        -- Limit error message length
        if #error_msg > 500 then error_msg = error_msg:sub(1, 500) .. "..." end
        vim.notify("Chi tiết lỗi:\n" .. error_msg, vim.log.levels.ERROR)
      end
    end
  end)
end

-- UI cho workflow commands
local function show_workflow_menu()
  local workflow_list = {}
  local workflow_keys = {}

  -- Tạo danh sách hiển thị
  for key, data in pairs(workflow_commands) do
    table.insert(workflow_list, data.name .. " - " .. data.description)
    table.insert(workflow_keys, key)
  end

  vim.ui.select(workflow_list, {
    prompt = "⚙️  .NET Workflow Commands:",
    format_item = function(item) return item end,
  }, function(choice, idx)
    if choice and idx then
      local cmd_key = workflow_keys[idx]

      -- Special handling cho một số commands
      if cmd_key == "publish" or cmd_key == "publish_release" then
        -- Hỏi output directory cho publish
        vim.ui.input({
          prompt = "📁 Output directory (Enter = default): ",
          default = "./publish",
        }, function(output_dir)
          local args = {}
          if output_dir and output_dir ~= "" then
            table.insert(args, "-o")
            table.insert(args, output_dir)
          end
          execute_workflow_command(cmd_key, args)
        end)
      else
        execute_workflow_command(cmd_key)
      end
    end
  end)
end

-- Hàm build với configuration options
local function build_with_config()
  local configs = { "Debug", "Release" }

  vim.ui.select(configs, {
    prompt = "🔧 Chọn Build Configuration:",
  }, function(choice)
    if choice then execute_workflow_command("build", { "-c", choice }) end
  end)
end

-- Hàm run với arguments
local function run_with_args()
  vim.ui.input({
    prompt = "⚙️  Arguments (Enter = none): ",
    default = "",
  }, function(args)
    local arg_list = {}
    if args and args ~= "" then
      -- Parse arguments
      for arg in args:gmatch "%S+" do
        table.insert(arg_list, arg)
      end
    end
    execute_workflow_command("run", arg_list)
  end)
end

-- Hàm test với filter
local function test_with_filter()
  vim.ui.input({
    prompt = "🔍 Test filter (Enter = run all): ",
    default = "",
  }, function(filter)
    local args = {}
    if filter and filter ~= "" then
      table.insert(args, "--filter")
      table.insert(args, filter)
    end
    execute_workflow_command("test", args)
  end)
end

-- Hàm tạo project bằng dotnet new
local function create_project_with_dotnet(project_type, project_name, directory)
  local template_info = project_templates[project_type]
  if not template_info then
    vim.notify("Project template không tồn tại: " .. project_type, vim.log.levels.ERROR)
    return
  end

  -- Tạo command dotnet new
  local cmd = { "dotnet", "new", template_info.template, "-n", project_name }

  -- Thêm language nếu có
  if template_info.language and template_info.language ~= "" then
    table.insert(cmd, "--language")
    table.insert(cmd, template_info.language)
  end

  -- Thêm options nếu có
  if template_info.options then
    for option in template_info.options:gmatch "%S+" do
      table.insert(cmd, option)
    end
  end

  -- Tạo thư mục parent nếu cần
  ensure_dir(directory)

  vim.notify("🚀 Đang tạo project: " .. project_name, vim.log.levels.INFO)

  run_dotnet_command(cmd, directory, function(exit_code)
    if exit_code == 0 then
      local project_path = directory .. "/" .. project_name
      vim.notify("✅ Tạo project thành công: " .. project_name, vim.log.levels.INFO)

      -- Chuyển vào thư mục project
      vim.cmd("cd " .. vim.fn.fnameescape(project_path))

      -- Mở file chính
      local main_files = { "Program.cs", project_name .. ".csproj", "*.cs" }
      for _, pattern in ipairs(main_files) do
        local files = vim.fn.glob(project_path .. "/" .. pattern, false, true)
        if #files > 0 then
          vim.cmd("edit " .. files[1])
          break
        end
      end
    else
      vim.notify("❌ Lỗi tạo project: " .. project_name, vim.log.levels.ERROR)
    end
  end)
end

-- Hàm tạo file từ template
local function create_file_from_template(template_type, namespace, classname, file_path)
  local template_data = file_templates[template_type]
  if not template_data then
    vim.notify("Template không tồn tại: " .. template_type, vim.log.levels.ERROR)
    return false
  end

  -- Thay thế placeholder
  local content = string.gsub(template_data.template, "{namespace}", namespace)
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

-- UI để chọn thư mục
local function select_directory(prompt, default_dir, callback)
  vim.ui.input({
    prompt = prompt,
    default = default_dir,
    completion = "dir",
  }, function(directory)
    if directory then callback(directory) end
  end)
end

-- UI để chọn loại project
local function show_project_menu()
  local project_list = {}
  local project_keys = {}

  -- Tạo danh sách hiển thị
  for key, data in pairs(project_templates) do
    table.insert(project_list, data.name .. " - " .. data.description)
    table.insert(project_keys, key)
  end

  vim.ui.select(project_list, {
    prompt = "🚀 Chọn loại project:",
    format_item = function(item) return item end,
  }, function(choice, idx)
    if choice and idx then
      local project_type = project_keys[idx]
      create_project_ui(project_type)
    end
  end)
end

-- UI để tạo project
function create_project_ui(project_type)
  local template_info = project_templates[project_type]
  if not template_info then
    vim.notify("Project template không tồn tại!", vim.log.levels.ERROR)
    return
  end

  -- Input project name
  vim.ui.input({
    prompt = "📝 Tên project: ",
    default = "My" .. string.gsub(template_info.name, "[^%w]", ""),
  }, function(project_name)
    if not project_name or project_name == "" then
      vim.notify("Tên project không được để trống!", vim.log.levels.WARN)
      return
    end

    -- Validate project name
    if not string.match(project_name, "^[A-Za-z][A-Za-z0-9_.]*$") then
      vim.notify("Tên project không hợp lệ! Chỉ sử dụng chữ cái, số, . và _", vim.log.levels.ERROR)
      return
    end

    -- Select directory
    select_directory(
      "📁 Thư mục tạo project: ",
      vim.fn.getcwd(),
      function(directory) create_project_with_dotnet(project_type, project_name, directory) end
    )
  end)
end

-- UI để chọn loại file template
local function show_file_template_menu()
  local template_list = {}
  local template_keys = {}

  -- Tạo danh sách hiển thị
  for key, data in pairs(file_templates) do
    table.insert(template_list, data.description .. " (" .. key .. ")")
    table.insert(template_keys, key)
  end

  vim.ui.select(template_list, {
    prompt = "🎯 Chọn loại file C#:",
    format_item = function(item) return item end,
  }, function(choice, idx)
    if choice and idx then
      local template_type = template_keys[idx]
      create_file_ui(template_type)
    end
  end)
end

-- UI để tạo file
function create_file_ui(template_type)
  local template_data = file_templates[template_type]
  if not template_data then
    vim.notify("Template không tồn tại!", vim.log.levels.ERROR)
    return
  end

  -- Select directory first
  select_directory("📁 Thư mục tạo file: ", vim.fn.expand "%:p:h", function(directory)
    local namespace = get_namespace_from_path(directory)

    -- Input class name
    local prompt_text = "📝 Tên "
    if template_type:find "interface" then
      prompt_text = prompt_text .. "interface (không cần I): "
    else
      prompt_text = prompt_text .. template_data.description .. ": "
    end

    vim.ui.input({
      prompt = prompt_text,
      default = "",
    }, function(classname)
      if not classname or classname == "" then
        vim.notify("Tên không được để trống!", vim.log.levels.WARN)
        return
      end

      -- Validate class name
      if not string.match(classname, "^[A-Za-z][A-Za-z0-9_]*$") then
        vim.notify("Tên không hợp lệ! Chỉ sử dụng chữ cái, số và _", vim.log.levels.ERROR)
        return
      end

      -- Create file path
      local filename = classname .. ".cs"
      if template_type == "controller" then
        filename = classname .. "Controller.cs"
      elseif template_type == "test" then
        filename = classname .. "Tests.cs"
      end

      local file_path = directory .. "/" .. filename

      -- Check if file exists
      if vim.fn.filereadable(file_path) == 1 then
        vim.ui.select({ "Có", "Không" }, {
          prompt = "File đã tồn tại! Ghi đè?",
        }, function(choice)
          if choice == "Có" then
            if create_file_from_template(template_type, namespace, classname, file_path) then
              vim.cmd("edit " .. file_path)
              vim.notify(
                "✅ Tạo " .. template_data.description .. " thành công: " .. filename,
                vim.log.levels.INFO
              )
            end
          end
        end)
      else
        if create_file_from_template(template_type, namespace, classname, file_path) then
          vim.cmd("edit " .. file_path)
          vim.notify("✅ Tạo " .. template_data.description .. " thành công: " .. filename, vim.log.levels.INFO)
        end
      end
    end)
  end)
end

-- Hàm liệt kê templates có sẵn
local function list_dotnet_templates()
  vim.notify("🔍 Đang lấy danh sách templates...", vim.log.levels.INFO)

  run_dotnet_command({ "dotnet", "new", "--list" }, nil, function(exit_code)
    if exit_code == 0 then vim.notify("✅ Xem output để biết các templates có sẵn", vim.log.levels.INFO) end
  end)
end

-- Main menu
local function show_main_menu()
  local menu_options = {
    "🚀 Tạo Project mới",
    "📝 Tạo File C# mới",
    "⚙️  Development Workflow",
    "🔨 Build Commands",
    "🧪 Test Commands",
    "📋 Liệt kê dotnet templates",
    "ℹ️  Thông tin dotnet",
  }

  vim.ui.select(menu_options, {
    prompt = "🎯 dotnet-nvim Menu:",
    format_item = function(item) return item end,
  }, function(choice, idx)
    if not choice or not idx then return end

    if idx == 1 then
      show_project_menu()
    elseif idx == 2 then
      show_file_template_menu()
    elseif idx == 3 then
      show_workflow_menu()
    elseif idx == 4 then
      show_build_menu()
    elseif idx == 5 then
      show_test_menu()
    elseif idx == 6 then
      list_dotnet_templates()
    elseif idx == 7 then
      run_dotnet_command({ "dotnet", "--info" }, nil, nil)
    end
  end)
end

-- Build menu
local function show_build_menu()
  local build_options = {
    "🔨 Build (Debug)",
    "🚀 Build (Release)",
    "🔧 Build với Configuration",
    "🧹 Clean Project",
    "📦 Restore Packages",
  }

  vim.ui.select(build_options, {
    prompt = "🔨 Build Commands:",
  }, function(choice, idx)
    if not choice or not idx then return end

    if idx == 1 then
      execute_workflow_command "build"
    elseif idx == 2 then
      execute_workflow_command "build_release"
    elseif idx == 3 then
      build_with_config()
    elseif idx == 4 then
      execute_workflow_command "clean"
    elseif idx == 5 then
      execute_workflow_command "restore"
    end
  end)
end

-- Test menu
local function show_test_menu()
  local test_options = {
    "🧪 Run All Tests",
    "📝 Run Tests (Verbose)",
    "🔍 Run Tests with Filter",
    "📊 Test Coverage",
  }

  vim.ui.select(test_options, {
    prompt = "🧪 Test Commands:",
  }, function(choice, idx)
    if not choice or not idx then return end

    if idx == 1 then
      execute_workflow_command "test"
    elseif idx == 2 then
      execute_workflow_command "test_verbose"
    elseif idx == 3 then
      test_with_filter()
    elseif idx == 4 then
      execute_workflow_command("test", { "--collect-coverage" })
    end
  end)
end

-- Hàm setup plugin
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  -- Tạo commands
  vim.api.nvim_create_user_command(
    "DotNetMenu",
    function() show_main_menu() end,
    { desc = "Mở main menu dotnet-nvim" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreate",
    function() show_file_template_menu() end,
    { desc = "Mở menu tạo file C#" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateProject",
    function() show_project_menu() end,
    { desc = "Mở menu tạo project" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateClass",
    function() create_file_ui "class" end,
    { desc = "Tạo C# Class" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateInterface",
    function() create_file_ui "interface" end,
    { desc = "Tạo C# Interface" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateController",
    function() create_file_ui "controller" end,
    { desc = "Tạo ASP.NET Controller" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateModel",
    function() create_file_ui "model" end,
    { desc = "Tạo C# Model" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateService",
    function() create_file_ui "service" end,
    { desc = "Tạo Service" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateRepository",
    function() create_file_ui "repository" end,
    { desc = "Tạo Repository" }
  )

  vim.api.nvim_create_user_command(
    "DotNetBuild",
    function() execute_workflow_command "build" end,
    { desc = "Build project" }
  )

  vim.api.nvim_create_user_command(
    "DotNetBuildRelease",
    function() execute_workflow_command "build_release" end,
    { desc = "Build project (Release)" }
  )

  vim.api.nvim_create_user_command("DotNetRun", function() execute_workflow_command "run" end, { desc = "Run project" })

  vim.api.nvim_create_user_command(
    "DotNetWatch",
    function() execute_workflow_command "watch" end,
    { desc = "Run project with hot reload" }
  )

  vim.api.nvim_create_user_command("DotNetTest", function() execute_workflow_command "test" end, { desc = "Run tests" })

  vim.api.nvim_create_user_command(
    "DotNetClean",
    function() execute_workflow_command "clean" end,
    { desc = "Clean project" }
  )

  vim.api.nvim_create_user_command(
    "DotNetRestore",
    function() execute_workflow_command "restore" end,
    { desc = "Restore packages" }
  )

  vim.api.nvim_create_user_command(
    "DotNetPublish",
    function() execute_workflow_command "publish" end,
    { desc = "Publish project" }
  )

  vim.api.nvim_create_user_command(
    "DotNetWorkflow",
    function() show_workflow_menu() end,
    { desc = "Development workflow menu" }
  )

  vim.api.nvim_create_user_command(
    "DotNetBuildMenu",
    function() show_build_menu() end,
    { desc = "Build commands menu" }
  )

  vim.api.nvim_create_user_command("DotNetTestMenu", function() show_test_menu() end, { desc = "Test commands menu" })

  vim.api.nvim_create_user_command(
    "DotNetList",
    function() list_dotnet_templates() end,
    { desc = "Liệt kê dotnet templates" }
  )

  vim.api.nvim_create_user_command(
    "DotNetInfo",
    function() run_dotnet_command({ "dotnet", "--info" }, nil, nil) end,
    { desc = "Thông tin dotnet" }
  )

  -- Setup keymaps
  if config.keymaps then
    vim.keymap.set(
      "n",
      config.keymaps.create_menu,
      ":DotNetMenu<CR>",
      { desc = "Main menu dotnet-nvim", silent = true }
    )
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
    vim.keymap.set(
      "n",
      config.keymaps.create_service,
      ":DotNetCreateService<CR>",
      { desc = "Tạo Service", silent = true }
    )
    vim.keymap.set(
      "n",
      config.keymaps.create_repository,
      ":DotNetCreateRepository<CR>",
      { desc = "Tạo Repository", silent = true }
    )
    vim.keymap.set(
      "n",
      config.keymaps.create_project,
      ":DotNetCreateProject<CR>",
      { desc = "Tạo Project", silent = true }
    )

    -- Workflow keymaps
    vim.keymap.set("n", "<leader>db", ":DotNetBuild<CR>", { desc = "Build project", silent = true })
    vim.keymap.set("n", "<leader>dr", ":DotNetRun<CR>", { desc = "Run project", silent = true })
    vim.keymap.set("n", "<leader>dt", ":DotNetTest<CR>", { desc = "Run tests", silent = true })
    vim.keymap.set("n", "<leader>dw", ":DotNetWatch<CR>", { desc = "Watch & run", silent = true })
    vim.keymap.set("n", "<leader>dR", ":DotNetRestore<CR>", { desc = "Restore packages", silent = true })
    vim.keymap.set("n", "<leader>dC", ":DotNetClean<CR>", { desc = "Clean project", silent = true })
  end

  -- Kiểm tra dotnet CLI có sẵn không
  vim.fn.jobstart({ "dotnet", "--version" }, {
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify(
          "⚠️  dotnet CLI không được tìm thấy. Vui lòng cài đặt .NET SDK",
          vim.log.levels.WARN
        )
      else
        vim.notify("✅ dotnet-nvim plugin đã sẵn sàng!", vim.log.levels.INFO)
      end
    end,
  })
end

-- Export functions
M.show_menu = show_main_menu
M.create_project = show_project_menu
M.create_file = show_file_template_menu
M.workflow = show_workflow_menu
M.build = function() execute_workflow_command "build" end
M.run = function() execute_workflow_command "run" end
M.test = function() execute_workflow_command "test" end
M.watch = function() execute_workflow_command "watch" end
M.clean = function() execute_workflow_command "clean" end
M.restore = function() execute_workflow_command "restore" end
M.publish = function() execute_workflow_command "publish" end
M.create_class = function() create_file_ui "class" end
M.create_interface = function() create_file_ui "interface" end
M.create_controller = function() create_file_ui "controller" end
M.create_model = function() create_file_ui "model" end
M.create_service = function() create_file_ui "service" end
M.create_repository = function() create_file_ui "repository" end

return M
