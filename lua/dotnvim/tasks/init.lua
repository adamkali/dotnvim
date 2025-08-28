-- Task system entry point and public API
local manager = require('dotnvim.tasks.manager')
local discovery = require('dotnvim.tasks.discovery')
local runner = require('dotnvim.tasks.runner')
local validation = require('dotnvim.utils.validation')

local M = {}

-- Re-export main functionality for convenient access
M.execute_tasks = manager.execute_tasks
M.execute_task_chain = manager.execute_task_chain
M.cancel_execution = manager.cancel_execution
M.is_running = manager.is_running
M.get_execution_status = manager.get_execution_status
M.get_execution_history = manager.get_execution_history
M.get_available_tasks = manager.get_available_tasks
M.has_task_support = manager.has_task_support
M.create_example_config = manager.create_example_config
M.reload_config = manager.reload_config
M.get_config_summary = manager.get_config_summary
M.set_execution_mode = manager.set_execution_mode
M.get_execution_mode = manager.get_execution_mode

-- Direct access to specific modules for advanced usage
M.manager = manager
M.discovery = discovery
M.runner = runner

-- Constants
M.EXECUTION_MODES = manager.EXECUTION_MODES
M.TASK_STATES = runner.TASK_STATES

-- Convenience functions

-- Execute a single task by name
-- @param task_name string: Name of the task to execute
-- @param options table: Execution options (optional)
-- @param callback function: Completion callback (optional)
-- @return boolean: True if execution started successfully
function M.run_task(task_name, options, callback)
  validation.assert_string(task_name, "task_name", false)
  return M.execute_tasks({task_name}, options, callback)
end

-- Execute pre-debug tasks if configured
-- @param options table: Execution options (optional)  
-- @param callback function: Completion callback (optional)
-- @return boolean: True if execution started successfully or no pre-debug tasks
function M.run_pre_debug_tasks(options, callback)
  options = options or {}
  
  -- Look for common pre-debug task names
  local pre_debug_candidates = {"pre-debug", "debug-prep", "prepare-debug", "before-debug"}
  
  local available_tasks, err = M.get_available_tasks(options.project_root)
  if not available_tasks then
    if callback then callback(true, "No task configuration available") end
    return true -- Not an error, just no tasks available
  end
  
  -- Find the first available pre-debug task
  local pre_debug_task = nil
  for _, candidate in ipairs(pre_debug_candidates) do
    if vim.tbl_contains(available_tasks, candidate) then
      pre_debug_task = candidate
      break
    end
  end
  
  if not pre_debug_task then
    -- Check for user-configured pre-debug tasks in options
    if options.pre_debug_tasks then
      validation.assert_table(options.pre_debug_tasks, "options.pre_debug_tasks", false)
      return M.execute_tasks(options.pre_debug_tasks, options, callback)
    end
    
    if callback then callback(true, "No pre-debug tasks configured") end
    return true -- Not an error, just no pre-debug tasks
  end
  
  return M.execute_task_chain(pre_debug_task, options, callback)
end

-- Quick status check
-- @return table: Quick status summary
function M.status()
  local status = {
    running = M.is_running(),
    has_config = false,
    available_tasks = {},
    execution_history_count = 0
  }
  
  -- Check if config exists
  local has_support, reason = M.has_task_support()
  status.has_config = has_support
  status.config_reason = reason
  
  if has_support then
    local tasks, err = M.get_available_tasks()
    if tasks then
      status.available_tasks = tasks
    end
  end
  
  -- Get execution history count
  local history = M.get_execution_history(1)
  status.execution_history_count = #M.get_execution_history(100) -- Get full count
  
  if M.is_running() then
    status.current_execution = M.get_execution_status()
  end
  
  return status
end

-- Initialize task system for a project
-- @param project_root string: Project root directory (optional)
-- @param format string: Format for example config (optional)
-- @return boolean, string: Success status, message
function M.init(project_root, format)
  local has_support, reason = M.has_task_support(project_root)
  
  if has_support then
    return true, "Task system already initialized: " .. reason
  end
  
  -- Create example configuration
  format = format or "json"
  local success, file_path_or_error = M.create_example_config(format, project_root)
  
  if success then
    return true, "Task configuration created: " .. file_path_or_error
  else
    return false, "Failed to create task configuration: " .. file_path_or_error
  end
end

-- Setup function for integration with main plugin
-- @param config table: Task system configuration (optional)
function M.setup(config)
  config = config or {}
  
  -- Set execution mode if specified
  if config.execution_mode then
    M.set_execution_mode(config.execution_mode)
  end
  
  -- Any other task-specific setup can go here
end

return M