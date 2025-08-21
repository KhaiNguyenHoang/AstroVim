-- dotnet-nvim/init.lua
-- Plugin để tạo mọi loại file C#/.NET trong Neovim

local M = {}

-- Cấu hình mặc định
local config = {
  default_namespace = "MyProject",
  templates_dir = vim.fn.stdpath "data" .. "/dotnet-nvim/templates",
  keymaps = {
    create_menu = "<leader>dn",
    create_class = "<leader>dc",
    create_interface = "<leader>di",
    create_controller = "<leader>dr",
    create_model = "<leader>dm",
    create_service = "<leader>ds",
    create_repository = "<leader>dp",
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

-- Template cho tất cả các loại file C#
local templates = {
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

  static_class = {
    template = [[using System;

namespace {namespace}
{
    public static class {classname}
    {
        public static void DoSomething()
        {
            // Static method implementation
        }
    }
}]],
    description = "Static Class",
  },

  sealed_class = {
    template = [[using System;

namespace {namespace}
{
    public sealed class {classname}
    {
        public {classname}()
        {
            
        }
    }
}]],
    description = "Sealed Class",
  },

  partial_class = {
    template = [[using System;

namespace {namespace}
{
    public partial class {classname}
    {
        // This is part 1 of the partial class
        public void Method1()
        {
            
        }
    }
}]],
    description = "Partial Class",
  },

  -- 🔌 Interfaces
  interface = {
    template = [[using System;

namespace {namespace}
{
    public interface I{classname}
    {
        void DoSomething();
        Task<T> GetAsync<T>(int id);
    }
}]],
    description = "Interface",
  },

  generic_interface = {
    template = [[using System;

namespace {namespace}
{
    public interface I{classname}<T> where T : class
    {
        T Get(int id);
        Task<IEnumerable<T>> GetAllAsync();
        Task<T> CreateAsync(T entity);
        Task<T> UpdateAsync(T entity);
        Task DeleteAsync(int id);
    }
}]],
    description = "Generic Interface",
  },

  -- 🏗️ Structures
  struct = {
    template = [[using System;

namespace {namespace}
{
    public struct {classname}
    {
        public int Id { get; set; }
        public string Name { get; set; }
        
        public {classname}(int id, string name)
        {
            Id = id;
            Name = name;
        }
    }
}]],
    description = "Struct",
  },

  record = {
    template = [[using System;

namespace {namespace}
{
    public record {classname}(int Id, string Name, DateTime CreatedAt);
}]],
    description = "Record Class",
  },

  -- 📊 Enums
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

  enum_flags = {
    template = [[using System;

namespace {namespace}
{
    [Flags]
    public enum {classname}
    {
        None = 0,
        Read = 1,
        Write = 2,
        Execute = 4,
        All = Read | Write | Execute
    }
}]],
    description = "Flags Enum",
  },

  -- 🌐 Web Development
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
            return Ok();
        }

        [HttpGet("{id}")]
        public IActionResult Get(int id)
        {
            return Ok();
        }

        [HttpPost]
        public IActionResult Post([FromBody] object model)
        {
            return CreatedAtAction(nameof(Get), new { id = 1 }, model);
        }

        [HttpPut("{id}")]
        public IActionResult Put(int id, [FromBody] object model)
        {
            return Ok();
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

  mvc_controller = {
    template = [[using Microsoft.AspNetCore.Mvc;

namespace {namespace}.Controllers
{
    public class {classname}Controller : Controller
    {
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Details(int id)
        {
            return View();
        }

        [HttpGet]
        public IActionResult Create()
        {
            return View();
        }

        [HttpPost]
        public IActionResult Create(object model)
        {
            if (ModelState.IsValid)
            {
                return RedirectToAction(nameof(Index));
            }
            return View(model);
        }
    }
}]],
    description = "MVC Controller",
  },

  middleware = {
    template = [[using Microsoft.AspNetCore.Http;
using System.Threading.Tasks;

namespace {namespace}.Middleware
{
    public class {classname}Middleware
    {
        private readonly RequestDelegate _next;

        public {classname}Middleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // Do something before
            
            await _next(context);
            
            // Do something after
        }
    }
}]],
    description = "ASP.NET Middleware",
  },

  -- 📦 Data Models
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

  entity = {
    template = [[using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace {namespace}.Entities
{
    [Table("{classname}s")]
    public class {classname}
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }
        
        [Required]
        [Column(TypeName = "nvarchar(100)")]
        public string Name { get; set; } = string.Empty;
        
        [Column(TypeName = "datetime2")]
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        
        [Column(TypeName = "datetime2")]
        public DateTime? UpdatedAt { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
}]],
    description = "Entity Framework Entity",
  },

  dto = {
    template = [[using System;

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
        public string Name { get; set; } = string.Empty;
    }

    public class Update{classname}Dto
    {
        public string Name { get; set; } = string.Empty;
    }
}]],
    description = "Data Transfer Objects",
  },

  -- 🏪 Services & Repositories
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
            throw new NotImplementedException();
        }

        public async Task<IEnumerable<T>> GetAllAsync<T>()
        {
            // Implementation here
            throw new NotImplementedException();
        }

        public async Task<T> CreateAsync<T>(T entity)
        {
            // Implementation here
            throw new NotImplementedException();
        }

        public async Task<T> UpdateAsync<T>(T entity)
        {
            // Implementation here
            throw new NotImplementedException();
        }

        public async Task DeleteAsync(int id)
        {
            // Implementation here
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
        Task<T> GetByIdAsync(int id);
        Task<IEnumerable<T>> GetAllAsync();
        Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
        Task<T> AddAsync(T entity);
        Task<T> UpdateAsync(T entity);
        Task DeleteAsync(int id);
        Task<bool> ExistsAsync(int id);
    }

    public class {classname}Repository<T> : I{classname}Repository<T> where T : class
    {
        public async Task<T> GetByIdAsync(int id)
        {
            // Implementation here
            throw new NotImplementedException();
        }

        public async Task<IEnumerable<T>> GetAllAsync()
        {
            // Implementation here  
            throw new NotImplementedException();
        }

        public async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate)
        {
            // Implementation here
            throw new NotImplementedException();
        }

        public async Task<T> AddAsync(T entity)
        {
            // Implementation here
            throw new NotImplementedException();
        }

        public async Task<T> UpdateAsync(T entity)
        {
            // Implementation here
            throw new NotImplementedException();
        }

        public async Task DeleteAsync(int id)
        {
            // Implementation here
            throw new NotImplementedException();
        }

        public async Task<bool> ExistsAsync(int id)
        {
            // Implementation here
            throw new NotImplementedException();
        }
    }
}]],
    description = "Generic Repository",
  },

  -- 🧪 Testing
  unit_test = {
    template = [[using Xunit;
using FluentAssertions;

namespace {namespace}.Tests
{
    public class {classname}Tests
    {
        [Fact]
        public void Should_Return_True_When_Condition_Is_Met()
        {
            // Arrange
            var sut = new {classname}();
            
            // Act
            var result = sut.DoSomething();
            
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
            var result = sut.Process(input);
            
            // Assert
            result.Should().Be(expected);
        }
    }
}]],
    description = "xUnit Test Class",
  },

  -- ⚙️ Configuration
  startup = {
    template = [[using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace {namespace}
{
    public class {classname}
    {
        public {classname}(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();
            services.AddSwaggerGen();
            
            // Add your services here
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();
            app.UseRouting();
            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}]],
    description = "Startup Class",
  },

  program = {
    template = [[using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

namespace {namespace}
{
    public class {classname}
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}]],
    description = "Program Class",
  },

  -- 🔧 Extensions
  extension = {
    template = [[using System;

namespace {namespace}.Extensions
{
    public static class {classname}Extensions
    {
        public static T DoSomething<T>(this T source) where T : class
        {
            // Extension method implementation
            return source;
        }

        public static bool IsNotNull<T>(this T source) where T : class
        {
            return source != null;
        }
    }
}]],
    description = "Extension Methods",
  },

  -- 🚨 Exception
  exception = {
    template = [[using System;

namespace {namespace}.Exceptions
{
    public class {classname}Exception : Exception
    {
        public {classname}Exception()
        {
        }

        public {classname}Exception(string message) : base(message)
        {
        }

        public {classname}Exception(string message, Exception innerException) : base(message, innerException)
        {
        }
    }
}]],
    description = "Custom Exception",
  },
}

-- Hàm tạo file từ template
local function create_file_from_template(template_type, namespace, classname, file_path)
  local template_data = templates[template_type]
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

-- UI để chọn loại template
local function show_template_menu()
  local template_list = {}
  local template_keys = {}

  -- Tạo danh sách hiển thị
  for key, data in pairs(templates) do
    table.insert(template_list, data.description .. " (" .. key .. ")")
    table.insert(template_keys, key)
  end

  vim.ui.select(template_list, {
    prompt = "🎯 Chọn loại file C#:",
    format_item = function(item) return item end,
  }, function(choice, idx)
    if choice and idx then
      local template_type = template_keys[idx]
      create_class_ui(template_type)
    end
  end)
end

-- UI để nhập thông tin
function create_class_ui(template_type)
  local current_dir = vim.fn.expand "%:p:h"
  local namespace = get_namespace_from_path(current_dir)
  local template_data = templates[template_type]

  if not template_data then
    vim.notify("Template không tồn tại!", vim.log.levels.ERROR)
    return
  end

  -- Input directory
  vim.ui.input({
    prompt = "📁 Thư mục (Enter = current): ",
    default = current_dir,
    completion = "dir",
  }, function(directory)
    if not directory then return end

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
      local file_extension = ".cs"
      local filename = classname .. file_extension
      if template_type:find "test" then
        filename = classname .. "Tests.cs"
      elseif template_type == "controller" then
        filename = classname .. "Controller.cs"
      elseif template_type == "exception" then
        filename = classname .. "Exception.cs"
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
      project_dir .. "/Repositories",
      project_dir .. "/DTOs",
      project_dir .. "/Entities",
      project_dir .. "/Data",
      project_dir .. "/Middleware",
      project_dir .. "/Extensions",
      project_dir .. "/Exceptions",
      project_dir .. "/Views",
      project_dir .. "/wwwroot",
      project_dir .. "/Tests",
    }

    for _, dir in ipairs(dirs) do
      ensure_dir(dir)
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
    "DotNetCreate",
    function() show_template_menu() end,
    { desc = "Mở menu tạo file C#" }
  )

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
    "DotNetCreateService",
    function() create_class_ui "service" end,
    { desc = "Tạo Service" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateRepository",
    function() create_class_ui "repository" end,
    { desc = "Tạo Repository" }
  )

  vim.api.nvim_create_user_command(
    "DotNetCreateProject",
    function() create_project_structure() end,
    { desc = "Tạo .NET Project Structure" }
  )

  -- Setup keymaps
  if config.keymaps then
    vim.keymap.set("n", config.keymaps.create_menu, ":DotNetCreate<CR>", { desc = "Menu tạo file C#", silent = true })
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
  end
end

-- Export functions
M.create_menu = show_template_menu
M.create_class = function() create_class_ui "class" end
M.create_interface = function() create_class_ui "interface" end
M.create_controller = function() create_class_ui "controller" end
M.create_model = function() create_class_ui "model" end
M.create_service = function() create_class_ui "service" end
M.create_repository = function() create_class_ui "repository" end
M.create_project = create_project_structure

return M
