-- Task manager and orchestration
local discovery = require('dotnvim.tasks.discovery')
local runner = require('dotnvim.tasks.runner')
local validation = require('dotnvim.utils.validation')
local ui_helpers = require('dotnvim.utils.ui_helpers')
local config_manager = require('dotnvim.config_manager')
local logger = require('dotnvim.utils.logger')

local M = {}

-- Task execution modes
local EXECUTION_MODES = {
  SEQUENTIAL = "sequential",  -- Run tasks one after another
  PARALLEL = "parallel",     -- Run independent tasks simultaneously (future enhancement)
  DEPENDENCY_AWARE = "dependency_aware"  -- Resolve dependencies and run in optimal order
}

-- Task manager state
local manager_state = {
  current_execution = nil,
  execution_history = {},
  default_mode = EXECUTION_MODES.DEPENDENCY_AWARE
}

-- Execute tasks by name with dependency resolution
-- @param task_names table: Array of task names to execute
-- @param options table: Execution options (optional)
-- @param callback function: Completion callback (optional)
-- @return boolean: True if execution started successfully
function M.execute_tasks(task_names, options, callback)
  logger.info("task_manager", "=== EXECUTE_TASKS CALLED ===")
  logger.debug("task_manager", "Task names: " .. vim.inspect(task_names))
  logger.debug("task_manager", "Options: " .. vim.inspect(options))
  logger.debug("task_manager", "Current manager state: " .. vim.inspect(manager_state))
  
  validation.assert_table(task_names, "task_names", false)
  options = options or {}
  
  if #task_names == 0 then
    logger.warn("task_manager", "No tasks specified for execution")
    ui_helpers.show_warning("No tasks specified for execution", "execute_tasks")
    if callback then callback(false, "No tasks specified") end
    return false
  end
  
  -- Check if tasks are already running
  if manager_state.current_execution then
    logger.warn("task_manager", "Tasks already running - blocking new execution")
    logger.debug("task_manager", "Current execution details: " .. vim.inspect(manager_state.current_execution))
    ui_helpers.show_warning("Tasks are already running. Cancel or wait for completion. Current execution: " .. vim.inspect(manager_state.current_execution), "execute_tasks")
    if callback then callback(false, "Tasks already running") end
    return false
  else
    logger.info("task_manager", "No current task execution detected, proceeding with task start")
    ui_helpers.show_info("No current task execution detected, proceeding with task start", "execute_tasks")
  end
  
  -- Load task configuration
  local config, config_err = discovery.load_task_config(options.project_root)
  if not config then
    ui_helpers.show_error(config_err or "Could not load task configuration", "execute_tasks")
    if callback then callback(false, config_err) end
    return false
  end
  
  -- Validate all requested tasks exist
  local task_map = {}
  for _, task in ipairs(config.tasks) do
    if task.name then
      task_map[task.name] = task
    end
  end
  
  local missing_tasks = {}
  for _, task_name in ipairs(task_names) do
    if not task_map[task_name] then
      table.insert(missing_tasks, task_name)
    end
  end
  
  if #missing_tasks > 0 then
    local error_msg = "Tasks not found: " .. table.concat(missing_tasks, ", ")
    ui_helpers.show_error(error_msg, "execute_tasks")
    if callback then callback(false, error_msg) end
    return false
  end
  
  -- Set up execution state
  local execution_id = "exec_" .. os.time() .. "_" .. math.random(1000, 9999)
  manager_state.current_execution = {
    id = execution_id,
    task_names = task_names,
    start_time = os.time(),
    project_root = config.project_root,
    mode = options.mode or manager_state.default_mode,
    contexts = {},
    callback = callback
  }
  
  ui_helpers.show_info("Starting task execution: " .. table.concat(task_names, ", "), "execute_tasks")
  
  -- Execute based on mode
  local execution_mode = manager_state.current_execution.mode
  
  if execution_mode == EXECUTION_MODES.DEPENDENCY_AWARE then
    return M._execute_with_dependencies(task_names, config.tasks, config.project_root, callback)
  elseif execution_mode == EXECUTION_MODES.SEQUENTIAL then
    return M._execute_sequential(task_names, task_map, config.project_root, callback)
  else
    ui_helpers.show_error("Unsupported execution mode: " .. execution_mode, "execute_tasks")
    manager_state.current_execution = nil
    if callback then callback(false, "Unsupported execution mode") end
    return false
  end
end

-- Execute a specific pre-configured task chain (e.g., "pre-debug")
-- @param chain_name string: Name of the task chain
-- @param options table: Execution options (optional)
-- @param callback function: Completion callback (optional)
-- @return boolean: True if execution started successfully
function M.execute_task_chain(chain_name, options, callback)
  validation.assert_string(chain_name, "chain_name", false)
  options = options or {}
  
  -- Load task configuration
  local config, config_err = discovery.load_task_config(options.project_root)
  if not config then
    ui_helpers.show_error(config_err or "Could not load task configuration", "execute_task_chain")
    if callback then callback(false, config_err) end
    return false
  end
  
  -- Find the chain task
  local chain_task = nil
  for _, task in ipairs(config.tasks) do
    if task.name == chain_name then
      chain_task = task
      break
    end
  end
  
  if not chain_task then
    ui_helpers.show_error("Task chain not found: " .. chain_name, "execute_task_chain")
    if callback then callback(false, "Task chain not found") end
    return false
  end
  
  -- If it's a simple task, execute it directly
  if not chain_task.previous or #chain_task.previous == 0 then
    return M.execute_tasks({chain_name}, options, callback)
  end
  
  -- Get all dependencies plus the chain task itself
  local execution_order, dep_err = discovery.get_task_dependencies(chain_name, config.project_root)
  if not execution_order then
    ui_helpers.show_error(dep_err or "Could not resolve dependencies", "execute_task_chain")
    if callback then callback(false, dep_err) end
    return false
  end
  
  return M.execute_tasks(execution_order, options, callback)
end

-- Execute tasks with dependency resolution (internal)
function M._execute_with_dependencies(task_names, all_tasks, project_root, callback)
  local contexts = runner.execute_with_dependencies(
    task_names, 
    all_tasks, 
    project_root, 
    function(exec_contexts, success)
      M._on_execution_complete(exec_contexts, success, callback)
    end
  )
  
  if manager_state.current_execution then
    manager_state.current_execution.contexts = contexts
  end
  
  return true
end

-- Execute tasks sequentially (internal)
function M._execute_sequential(task_names, task_map, project_root, callback)
  local tasks_to_execute = {}
  
  for _, task_name in ipairs(task_names) do
    local task = task_map[task_name]
    if task then
      table.insert(tasks_to_execute, task)
    end
  end
  
  local contexts = runner.execute_tasks_sequence(
    tasks_to_execute,
    project_root,
    function(exec_contexts, success)
      M._on_execution_complete(exec_contexts, success, callback)
    end
  )
  
  if manager_state.current_execution then
    manager_state.current_execution.contexts = contexts
  end
  
  return true
end

-- Handle execution completion (internal)
function M._on_execution_complete(contexts, success, callback)
  local execution = manager_state.current_execution
  if not execution then
    return -- No active execution
  end
  
  -- Update execution state
  execution.end_time = os.time()
  execution.success = success
  execution.contexts = contexts
  
  -- Add to history
  table.insert(manager_state.execution_history, {
    id = execution.id,
    task_names = execution.task_names,
    start_time = execution.start_time,
    end_time = execution.end_time,
    success = success,
    context_count = #contexts
  })
  
  -- Limit history size
  local max_history = 10
  if #manager_state.execution_history > max_history then
    table.remove(manager_state.execution_history, 1)
  end
  
  -- Show completion message
  local duration = execution.end_time - execution.start_time
  if success then
    ui_helpers.show_success(
      "Task execution completed in " .. duration .. "s: " .. table.concat(execution.task_names, ", "), 
      "task_manager"
    )
  else
    ui_helpers.show_error(
      "Task execution failed after " .. duration .. "s: " .. table.concat(execution.task_names, ", "), 
      "task_manager"
    )
  end
  
  -- Clear current execution
  manager_state.current_execution = nil
  
  -- Call user callback
  if callback then
    callback(success, contexts)
  end
end

-- Cancel current task execution
-- @return boolean: True if execution was cancelled
function M.cancel_execution()
  local was_running = manager_state.current_execution ~= nil
  
  ui_helpers.show_info("Cancel execution called. Was running: " .. tostring(was_running), "cancel_execution")
  
  -- Always try to cancel tasks, even if we don't think anything is running
  local cancelled_count = runner.cancel_all_tasks()
  
  if was_running then
    ui_helpers.show_info("Cancelled task execution with " .. cancelled_count .. " tasks", "cancel_execution")
    
    -- Mark execution as cancelled
    if manager_state.current_execution then
      manager_state.current_execution.end_time = os.time()
      manager_state.current_execution.success = false
    end
  else
    ui_helpers.show_info("No execution was running, but cancelled " .. cancelled_count .. " tasks", "cancel_execution")
  end
  
  -- Always clear the execution state
  manager_state.current_execution = nil
  ui_helpers.show_info("Execution state cleared", "cancel_execution")
  
  return was_running or cancelled_count > 0
end

-- Get current execution status
-- @return table|nil: Current execution info or nil if none
function M.get_execution_status()
  if not manager_state.current_execution then
    return nil
  end
  
  local execution = manager_state.current_execution
  local active_tasks = runner.get_active_tasks()
  
  return {
    id = execution.id,
    task_names = execution.task_names,
    start_time = execution.start_time,
    running_time = os.time() - execution.start_time,
    mode = execution.mode,
    active_task_count = vim.tbl_count(active_tasks),
    active_tasks = vim.tbl_keys(active_tasks)
  }
end

-- Get execution history
-- @param limit number: Maximum number of entries to return (optional)
-- @return table: Array of execution history entries
function M.get_execution_history(limit)
  limit = limit or 10
  
  local history = manager_state.execution_history
  local start_index = math.max(1, #history - limit + 1)
  
  local result = {}
  for i = start_index, #history do
    table.insert(result, history[i])
  end
  
  return result
end

-- Check if tasks are currently running
-- @return boolean: True if any execution is active
function M.is_running()
  return manager_state.current_execution ~= nil
end

-- Get available tasks for the current project
-- @param project_root string: Project root directory (optional)
-- @return table, string|nil: Array of task names, error message if any
function M.get_available_tasks(project_root)
  return discovery.get_available_tasks(project_root)
end

-- Check if project has task support
-- @param project_root string: Project root directory (optional)
-- @return boolean, string: Has support, reason/file path
function M.has_task_support(project_root)
  return discovery.has_task_support(project_root)
end

-- Create example task configuration
-- @param format string: Configuration format (json, yaml, toml) (optional)
-- @param project_root string: Project root directory (optional)
-- @return boolean, string: Success status, file path or error message
function M.create_example_config(format, project_root)
  return discovery.create_example_config(project_root, format)
end

-- Reload task configuration (clear cache)
-- @param project_root string: Project root directory (optional)
function M.reload_config(project_root)
  -- bad idea, 
  -- discovery.clear_cache(project_root)
  ui_helpers.show_info("Task configuration reloaded", "task_manager")
end

-- Get task configuration summary
-- @param project_root string: Project root directory (optional)
-- @return table|nil: Configuration summary or nil if not available
function M.get_config_summary(project_root)
  local config, err = discovery.load_task_config(project_root)
  if not config then
    return nil, err
  end
  
  local task_names = {}
  local has_dependencies = false
  local env_var_count = 0
  
  for _, task in ipairs(config.tasks) do
    if task.name then
      table.insert(task_names, task.name)
    end
    
    if task.previous and #task.previous > 0 then
      has_dependencies = true
    end
    
    if task.env then
      env_var_count = env_var_count + vim.tbl_count(task.env)
    end
  end
  
  return {
    file_path = config.file_path,
    format = config.format,
    version = config.version,
    task_count = #config.tasks,
    task_names = task_names,
    has_dependencies = has_dependencies,
    env_var_count = env_var_count,
    project_root = config.project_root
  }
end

-- Set default execution mode
-- @param mode string: Execution mode (sequential, dependency_aware)
function M.set_execution_mode(mode)
  validation.assert_string(mode, "mode", false)
  
  if not vim.tbl_contains(vim.tbl_values(EXECUTION_MODES), mode) then
    error("Invalid execution mode: " .. mode)
  end
  
  manager_state.default_mode = mode
  ui_helpers.show_info("Default execution mode set to: " .. mode, "task_manager")
end

-- Get current execution mode
-- @return string: Current default execution mode
function M.get_execution_mode()
  return manager_state.default_mode
end

-- Export constants
M.EXECUTION_MODES = EXECUTION_MODES

return M
