-- Task configuration validation utilities
local base_validation = require('dotnvim.utils.validation')

local M = {}

-- Task configuration schema validation
local SUPPORTED_VERSIONS = {"0.1.0"}

-- Validate a single task configuration
-- @param task table: Task configuration
-- @param index number: Task index for error reporting
-- @return boolean, table: success status and list of errors
function M.validate_task(task, index)
  local errors = {}
  local task_prefix = "tasks[" .. (index or "?") .. "]"
  
  -- Validate required fields
  local valid, err = base_validation.validate_non_empty_string(task.name, task_prefix .. ".name", false)
  if not valid then
    table.insert(errors, err)
  end
  
  valid, err = base_validation.validate_non_empty_string(task.command, task_prefix .. ".command", false)
  if not valid then
    table.insert(errors, err)
  end
  
  -- Validate optional fields
  if task.cwd then
    valid, err = base_validation.validate_string(task.cwd, task_prefix .. ".cwd", true)
    if not valid then
      table.insert(errors, err)
    end
  end
  
  -- Validate previous dependencies (array of strings)
  if task.previous then
    valid, err = base_validation.validate_table(task.previous, task_prefix .. ".previous", true)
    if not valid then
      table.insert(errors, err)
    else
      -- Validate each dependency name
      for i, dep in ipairs(task.previous) do
        valid, err = base_validation.validate_non_empty_string(dep, task_prefix .. ".previous[" .. i .. "]", false)
        if not valid then
          table.insert(errors, err)
        end
      end
    end
  end
  
  -- Validate environment variables
  if task.env then
    valid, err = base_validation.validate_table(task.env, task_prefix .. ".env", true)
    if not valid then
      table.insert(errors, err)
    else
      -- Validate env vars are key-value pairs
      for key, value in pairs(task.env) do
        if not base_validation.is_string(key) then
          table.insert(errors, task_prefix .. ".env key must be string, got " .. type(key))
        end
        if not base_validation.is_string(value) then
          table.insert(errors, task_prefix .. ".env['" .. key .. "'] must be string, got " .. type(value))
        end
      end
    end
  end
  
  -- Validate optional parallel flag
  if task.parallel ~= nil then
    valid, err = base_validation.validate_boolean(task.parallel, task_prefix .. ".parallel", true)
    if not valid then
      table.insert(errors, err)
    end
  end
  
  return #errors == 0, errors
end

-- Validate entire task configuration
-- @param config table: Full task configuration
-- @param source_file string: Source file path for error context
-- @return boolean, table: success status and list of errors
function M.validate_config(config, source_file)
  local errors = {}
  local file_context = source_file and (" in " .. source_file) or ""
  
  -- Validate root structure
  local valid, err = base_validation.validate_table(config, "config" .. file_context, false)
  if not valid then
    return false, {err}
  end
  
  -- Validate version
  valid, err = base_validation.validate_string(config.version, "version" .. file_context, false)
  if not valid then
    table.insert(errors, err)
  elseif not vim.tbl_contains(SUPPORTED_VERSIONS, config.version) then
    table.insert(errors, "Unsupported version '" .. config.version .. "'" .. file_context .. 
                         ". Supported versions: " .. table.concat(SUPPORTED_VERSIONS, ", "))
  end
  
  -- Validate tasks array
  valid, err = base_validation.validate_table(config.tasks, "tasks" .. file_context, false)
  if not valid then
    table.insert(errors, err)
    return false, errors -- Can't continue without valid tasks array
  end
  
  if #config.tasks == 0 then
    table.insert(errors, "No tasks defined" .. file_context)
    return false, errors
  end
  
  -- Validate individual tasks
  local task_names = {}
  for i, task in ipairs(config.tasks) do
    local task_valid, task_errors = M.validate_task(task, i)
    if not task_valid then
      vim.list_extend(errors, task_errors)
    end
    
    -- Check for duplicate task names
    if task.name then
      if task_names[task.name] then
        table.insert(errors, "Duplicate task name '" .. task.name .. "'" .. file_context)
      else
        task_names[task.name] = true
      end
    end
  end
  
  return #errors == 0, errors
end

-- Validate task dependencies exist and detect cycles
-- @param tasks table: Array of task configurations
-- @return boolean, table: success status and list of errors
function M.validate_dependencies(tasks)
  local errors = {}
  local task_map = {}
  
  -- Build task name map
  for _, task in ipairs(tasks) do
    if task.name then
      task_map[task.name] = task
    end
  end
  
  -- Validate dependencies exist
  for _, task in ipairs(tasks) do
    if task.previous then
      for _, dep_name in ipairs(task.previous) do
        if not task_map[dep_name] then
          table.insert(errors, "Task '" .. (task.name or "unknown") .. 
                              "' depends on unknown task '" .. dep_name .. "'")
        end
      end
    end
  end
  
  -- Detect circular dependencies using topological sort
  local cycle_errors = M.detect_cycles(tasks)
  vim.list_extend(errors, cycle_errors)
  
  return #errors == 0, errors
end

-- Detect circular dependencies in task graph
-- @param tasks table: Array of task configurations  
-- @return table: List of cycle error messages
function M.detect_cycles(tasks)
  local errors = {}
  local WHITE, GRAY, BLACK = 0, 1, 2
  local color = {}
  local task_map = {}
  
  -- Initialize
  for _, task in ipairs(tasks) do
    if task.name then
      color[task.name] = WHITE
      task_map[task.name] = task
    end
  end
  
  -- DFS to detect cycles
  local function dfs(task_name, path)
    if color[task_name] == GRAY then
      -- Found a cycle
      local cycle_start = nil
      for i, name in ipairs(path) do
        if name == task_name then
          cycle_start = i
          break
        end
      end
      
      local cycle_path = {}
      for i = cycle_start, #path do
        table.insert(cycle_path, path[i])
      end
      table.insert(cycle_path, task_name) -- Complete the cycle
      
      table.insert(errors, "Circular dependency detected: " .. table.concat(cycle_path, " → "))
      return
    end
    
    if color[task_name] == BLACK then
      return -- Already processed
    end
    
    color[task_name] = GRAY
    table.insert(path, task_name)
    
    local task = task_map[task_name]
    if task and task.previous then
      for _, dep_name in ipairs(task.previous) do
        if task_map[dep_name] then -- Only follow existing dependencies
          dfs(dep_name, path)
        end
      end
    end
    
    table.remove(path) -- Remove from current path
    color[task_name] = BLACK
  end
  
  -- Check each task
  for _, task in ipairs(tasks) do
    if task.name and color[task.name] == WHITE then
      dfs(task.name, {})
    end
  end
  
  return errors
end

-- Normalize task configuration from different formats
-- @param config table: Raw configuration from parser
-- @param source_format string: Source format (json, toml, yaml)
-- @return table: Normalized configuration
function M.normalize_config(config, source_format)
  local normalized = vim.deepcopy(config)
  
  if source_format == 'toml' then
    normalized = M.normalize_toml_config(normalized)
  elseif source_format == 'yaml' then
    normalized = M.normalize_yaml_config(normalized)
  end
  
  -- Ensure all tasks have required defaults
  if normalized.tasks then
    for _, task in ipairs(normalized.tasks) do
      -- Default working directory
      task.cwd = task.cwd or "."
      
      -- Ensure previous is always an array (even if originally a string)
      if task.previous and type(task.previous) == "string" then
        task.previous = {task.previous}
      end
      
      -- Ensure env is a table
      task.env = task.env or {}
    end
  end
  
  return normalized
end

-- Normalize TOML-specific quirks
-- @param config table: TOML configuration
-- @return table: Normalized configuration
function M.normalize_toml_config(config)
  -- TOML might represent arrays differently
  -- Handle any TOML-specific normalization here
  return config
end

-- Normalize YAML-specific quirks  
-- @param config table: YAML configuration
-- @return table: Normalized configuration
function M.normalize_yaml_config(config)
  -- YAML might have type conversion issues (strings vs numbers)
  -- Handle any YAML-specific normalization here
  return config
end

-- Create a validation summary for UI display
-- @param success boolean: Validation success
-- @param errors table: List of error messages
-- @param source_file string: Source file path
-- @return table: Formatted validation summary
function M.create_validation_summary(success, errors, source_file)
  return {
    success = success,
    error_count = #errors,
    errors = errors,
    source_file = source_file,
    summary = success and "✓ Configuration valid" or ("✗ " .. #errors .. " validation errors")
  }
end

return M