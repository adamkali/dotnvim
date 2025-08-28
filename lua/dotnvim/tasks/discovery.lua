-- Task configuration discovery service
local project_scanner = require('dotnvim.utils.project_scanner')
local parsers = require('dotnvim.tasks.parsers')
local validation = require('dotnvim.utils.validation')
local ui_helpers = require('dotnvim.utils.ui_helpers')

local M = {}

-- Task file discovery configuration with priority order
local TASK_DISCOVERY_PATHS = {
  -- .nvim directory (highest priority)
  {
    dir = '.nvim',
    files = {'tasks.json', 'tasks.toml', 'tasks.yaml', 'tasks.yml'}
  },
  -- .vscode directory (fallback compatibility)
  {
    dir = '.vscode', 
    files = {'tasks.json', 'tasks.toml', 'tasks.yaml', 'tasks.yml'}
  }
}

-- Cache for discovered task configurations
local task_cache = {}
local cache_timestamps = {}

-- Discover task configuration files in project
-- @param project_root string: Root directory of the project (optional)
-- @return string|nil, string|nil: Task file path and format, or nil if not found
function M.discover_task_file(project_root)
  project_root = project_root or M.get_project_root()
  
  if not project_root then
    return nil, nil, "No project root found"
  end
  
  local valid, err = validation.validate_directory_path(project_root, "project_root", true)
  if not valid then
    return nil, nil, err
  end
  
  -- Search through discovery paths in priority order
  for _, location in ipairs(TASK_DISCOVERY_PATHS) do
    local search_dir = project_root .. '/' .. location.dir
    
    -- Check if directory exists
    local dir_stat = vim.loop.fs_stat(search_dir)
    if dir_stat and dir_stat.type == "directory" then
      
      -- Search for task files in priority order
      for _, filename in ipairs(location.files) do
        local full_path = search_dir .. '/' .. filename
        local file_stat = vim.loop.fs_stat(full_path)
        
        if file_stat and file_stat.type == "file" then
          local format = parsers.detect_format(full_path)
          if format then
            return full_path, format, nil
          end
        end
      end
    end
  end
  
  return nil, nil, "No task configuration file found"
end

-- Get project root directory
-- @param start_path string: Starting path for search (optional)
-- @return string|nil: Project root path or nil if not found
function M.get_project_root(start_path)
  start_path = start_path or vim.fn.expand('%:p:h')
  return project_scanner.get_project_root(start_path)
end

-- Load task configuration from discovered file
-- @param project_root string: Project root directory (optional)
-- @param force_refresh boolean: Force cache refresh (optional)
-- @return table|nil, string|nil: Task configuration or nil, error message
function M.load_task_config(project_root, force_refresh)
  project_root = project_root or M.get_project_root()
  
  if not project_root then
    return nil, "No project root found"
  end
  
  -- Check cache first (unless force refresh)
  local cache_key = project_root
  if not force_refresh and task_cache[cache_key] then
    local cached_config = task_cache[cache_key]
    local cache_time = cache_timestamps[cache_key]
    
    -- Check if cache is still valid (file hasn't changed)
    if cached_config.file_path then
      local stat = vim.loop.fs_stat(cached_config.file_path)
      if stat and cache_time and stat.mtime.sec <= cache_time then
        return cached_config, nil
      end
    end
  end
  
  -- Discover task file
  local task_file, format, discovery_err = M.discover_task_file(project_root)
  if not task_file then
    return nil, discovery_err or "No task configuration found"
  end
  
  -- Parse task configuration
  local config, parse_err = parsers.parse_task_file(task_file)
  if not config then
    return nil, parse_err or "Failed to parse task configuration"
  end
  
  -- Enhance config with metadata
  config.file_path = task_file
  config.format = format
  config.project_root = project_root
  config.discovery_time = os.time()
  
  -- Cache the configuration
  task_cache[cache_key] = config
  cache_timestamps[cache_key] = os.time()
  
  return config, nil
end

-- Get all available task names from configuration
-- @param project_root string: Project root directory (optional)
-- @return table, string|nil: Array of task names, error message if any
function M.get_available_tasks(project_root)
  local config, err = M.load_task_config(project_root)
  if not config then
    return {}, err
  end
  
  local task_names = {}
  for _, task in ipairs(config.tasks or {}) do
    if task.name then
      table.insert(task_names, task.name)
    end
  end
  
  return task_names, nil
end

-- Find task by name in configuration
-- @param task_name string: Name of the task to find
-- @param project_root string: Project root directory (optional)
-- @return table|nil, string|nil: Task configuration or nil, error message
function M.find_task(task_name, project_root)
  validation.assert_string(task_name, "task_name", false)
  
  local config, err = M.load_task_config(project_root)
  if not config then
    return nil, err
  end
  
  for _, task in ipairs(config.tasks or {}) do
    if task.name == task_name then
      return task, nil
    end
  end
  
  return nil, "Task '" .. task_name .. "' not found"
end

-- Get task dependencies recursively
-- @param task_name string: Name of the task
-- @param project_root string: Project root directory (optional)
-- @return table, string|nil: Array of dependency names in execution order, error message
function M.get_task_dependencies(task_name, project_root)
  validation.assert_string(task_name, "task_name", false)
  
  local config, err = M.load_task_config(project_root)
  if not config then
    return {}, err
  end
  
  -- Build task map
  local task_map = {}
  for _, task in ipairs(config.tasks or {}) do
    if task.name then
      task_map[task.name] = task
    end
  end
  
  -- Recursive dependency resolution
  local resolved = {}
  local visiting = {}
  
  local function resolve_deps(name)
    if resolved[name] then
      return -- Already resolved
    end
    
    if visiting[name] then
      return {"Circular dependency detected involving task: " .. name}
    end
    
    local task = task_map[name]
    if not task then
      return {"Task not found: " .. name}
    end
    
    visiting[name] = true
    
    -- Resolve dependencies first
    if task.previous then
      for _, dep_name in ipairs(task.previous) do
        local dep_errors = resolve_deps(dep_name)
        if dep_errors then
          return dep_errors
        end
      end
    end
    
    visiting[name] = nil
    resolved[name] = true
    
    return nil
  end
  
  -- Resolve dependencies for the requested task
  local errors = resolve_deps(task_name)
  if errors then
    return {}, table.concat(errors, "; ")
  end
  
  -- Build execution order list
  local execution_order = {}
  local function build_order(name)
    local task = task_map[name]
    if task and task.previous then
      for _, dep_name in ipairs(task.previous) do
        if not vim.tbl_contains(execution_order, dep_name) then
          build_order(dep_name)
        end
      end
    end
    
    if not vim.tbl_contains(execution_order, name) then
      table.insert(execution_order, name)
    end
  end
  
  build_order(task_name)
  
  return execution_order, nil
end

-- Clear task configuration cache
-- @param project_root string: Project root to clear (optional, clears all if nil)
function M.clear_cache(project_root)
  if project_root then
    task_cache[project_root] = nil
    cache_timestamps[project_root] = nil
  else
    task_cache = {}
    cache_timestamps = {}
  end
end

-- Get cache statistics
-- @return table: Cache information
function M.get_cache_stats()
  local stats = {
    cached_projects = 0,
    total_tasks = 0,
    oldest_cache = nil,
    newest_cache = nil
  }
  
  for project_root, config in pairs(task_cache) do
    stats.cached_projects = stats.cached_projects + 1
    
    if config.tasks then
      stats.total_tasks = stats.total_tasks + #config.tasks
    end
    
    local cache_time = cache_timestamps[project_root]
    if cache_time then
      if not stats.oldest_cache or cache_time < stats.oldest_cache then
        stats.oldest_cache = cache_time
      end
      if not stats.newest_cache or cache_time > stats.newest_cache then
        stats.newest_cache = cache_time
      end
    end
  end
  
  return stats
end

-- Validate project has task support
-- @param project_root string: Project root directory (optional)
-- @return boolean, string: Has task support, reason if not
function M.has_task_support(project_root)
  project_root = project_root or M.get_project_root()
  
  if not project_root then
    return false, "No .NET project found"
  end
  
  local task_file, format, err = M.discover_task_file(project_root)
  if not task_file then
    return false, "No task configuration file found"
  end
  
  return true, "Task configuration available at " .. task_file
end

-- Create example task configuration file
-- @param project_root string: Project root directory (optional)
-- @param format string: Format to create (json, toml, yaml) (optional, defaults to json)
-- @return boolean, string: Success status, file path or error message
function M.create_example_config(project_root, format)
  project_root = project_root or M.get_project_root()
  format = format or "json"
  
  if not project_root then
    return false, "No .NET project found"
  end
  
  local nvim_dir = project_root .. '/.nvim'
  
  -- Create .nvim directory if it doesn't exist
  local dir_stat = vim.loop.fs_stat(nvim_dir)
  if not dir_stat then
    local success = vim.loop.fs_mkdir(nvim_dir, 493) -- 0755 permissions
    if not success then
      return false, "Could not create .nvim directory"
    end
  end
  
  -- Create example configuration
  local filename = "tasks." .. format
  local file_path = nvim_dir .. '/' .. filename
  
  local example_content
  if format == "json" then
    example_content = [[{
  "version": "0.1.0",
  "tasks": [
    {
      "name": "restore",
      "command": "dotnet restore ${workspaceFolder}",
      "cwd": "${workspaceFolder}",
      "env": {
        "DOTNET_NOLOGO": "true"
      }
    },
    {
      "name": "build",
      "previous": ["restore"],
      "command": "dotnet build ${workspaceFolder} --no-restore",
      "cwd": "${workspaceFolder}",
      "env": {
        "DOTNET_NOLOGO": "true",
        "PROJECT_ROOT": "${workspaceFolder}"
      }
    },
    {
      "name": "test",
      "previous": ["build"],
      "command": "dotnet test ${workspaceFolder} --no-build",
      "cwd": "${workspaceFolder}",
      "env": {
        "DOTNET_NOLOGO": "true",
        "ASPNETCORE_ENVIRONMENT": "Test",
        "TEST_OUTPUT": "${workspaceFolder}/TestResults"
      }
    },
    {
      "name": "pre-debug",
      "previous": ["build"],
      "command": "echo 'Ready for debugging ${workspaceFolderBasename}'",
      "cwd": "${workspaceFolder}"
    }
  ]
}]]
  elseif format == "yaml" then
    example_content = [[version: "0.1.0"
tasks:
  - name: restore
    command: dotnet restore ${workspaceFolder}
    cwd: ${workspaceFolder}
    env:
      DOTNET_NOLOGO: "true"

  - name: build
    previous: [restore]
    command: dotnet build ${workspaceFolder} --no-restore
    cwd: ${workspaceFolder}
    env:
      DOTNET_NOLOGO: "true"
      PROJECT_ROOT: ${workspaceFolder}

  - name: test
    previous: [build]
    command: dotnet test ${workspaceFolder} --no-build
    cwd: ${workspaceFolder}
    env:
      DOTNET_NOLOGO: "true"
      ASPNETCORE_ENVIRONMENT: Test
      TEST_OUTPUT: ${workspaceFolder}/TestResults

  - name: pre-debug
    previous: [build]
    command: echo 'Ready for debugging ${workspaceFolderBasename}'
    cwd: ${workspaceFolder}
]]
  elseif format == "toml" then
    example_content = [=[version = "0.1.0"

[[tasks]]
name = "restore"
command = "dotnet restore ${workspaceFolder}"
cwd = "${workspaceFolder}"

[tasks.env]
DOTNET_NOLOGO = "true"

[[tasks]]
name = "build"
previous = ["restore"]
command = "dotnet build ${workspaceFolder} --no-restore"
cwd = "${workspaceFolder}"

[tasks.env]
DOTNET_NOLOGO = "true"
PROJECT_ROOT = "${workspaceFolder}"

[[tasks]]
name = "test"
previous = ["build"]
command = "dotnet test ${workspaceFolder} --no-build"
cwd = "${workspaceFolder}"

[tasks.env]
DOTNET_NOLOGO = "true"
ASPNETCORE_ENVIRONMENT = "Test"
TEST_OUTPUT = "${workspaceFolder}/TestResults"

[[tasks]]
name = "pre-debug"
previous = ["build"]
command = "echo 'Ready for debugging ${workspaceFolderBasename}'"
cwd = "${workspaceFolder}"
]=]
  else
    return false, "Unsupported format: " .. format
  end
  
  -- Write example file
  local fd = vim.loop.fs_open(file_path, "w", 438) -- 0666 permissions
  if not fd then
    return false, "Could not create example file: " .. file_path
  end
  
  local write_success = vim.loop.fs_write(fd, example_content, 0)
  vim.loop.fs_close(fd)
  
  if not write_success then
    return false, "Could not write to example file: " .. file_path
  end
  
  return true, file_path
end

return M