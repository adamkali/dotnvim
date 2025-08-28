-- Task execution engine
local Job = require('plenary.job')
local validation = require('dotnvim.utils.validation')
local buffer_helpers = require('dotnvim.utils.buffer_helpers')
local ui_helpers = require('dotnvim.utils.ui_helpers')
local config_manager = require('dotnvim.config_manager')

local M = {}

-- Task execution states
local TASK_STATES = {
  PENDING = "pending",
  RUNNING = "running", 
  SUCCESS = "success",
  FAILED = "failed",
  CANCELLED = "cancelled"
}

-- Active task tracking
local active_tasks = {}
local task_buffers = {}

-- Task execution context
local TaskContext = {}
TaskContext.__index = TaskContext

function TaskContext:new(task, project_root)
  local context = {
    task = task,
    project_root = project_root,
    state = TASK_STATES.PENDING,
    start_time = nil,
    end_time = nil,
    exit_code = nil,
    job = nil,
    buffer = nil,
    output_lines = {},
    error_lines = {}
  }
  setmetatable(context, TaskContext)
  return context
end

function TaskContext:get_working_directory()
  local cwd = self.task.cwd or "."
  if cwd == "." then
    return self.project_root
  elseif cwd:match("^/") then
    -- Absolute path
    return cwd
  else
    -- Relative to project root
    return self.project_root .. "/" .. cwd
  end
end

function TaskContext:get_environment()
  local env = {}
  
  -- Start with system environment
  for key, value in pairs(vim.fn.environ()) do
    env[key] = value
  end
  
  -- Add task-specific environment variables
  if self.task.env then
    for key, value in pairs(self.task.env) do
      env[key] = tostring(value)
    end
  end
  
  return env
end

function TaskContext:create_output_buffer()
  local buffer_name = "task-" .. (self.task.name or "unknown")
  
  -- Get task output window configuration
  local config = config_manager.get_config()
  local split_config = config.tasks.output_window or {
    mode = "new_buffer",
    size = nil,
    focus = false
  }
  
  self.buffer = buffer_helpers.create_log_buffer_split(buffer_name, split_config)
  
  if self.buffer then
    task_buffers[self.task.name] = self.buffer
    
    -- Add header to buffer
    local header = {
      "=== Task: " .. (self.task.name or "unknown") .. " ===",
      "Command: " .. (self.task.command or "unknown"),
      "Working Directory: " .. self:get_working_directory(),
      "Started: " .. os.date("%Y-%m-%d %H:%M:%S"),
      "",
    }
    
    buffer_helpers.write_to_buffer(self.buffer, header)
  end
  
  return self.buffer
end

function TaskContext:log_output(line, is_error)
  if not line or line == "" then return end
  
  -- Store in context
  if is_error then
    table.insert(self.error_lines, line)
  else
    table.insert(self.output_lines, line)
  end
  
  -- Write to buffer if available
  if self.buffer then
    local prefix = is_error and "[ERROR] " or ""
    buffer_helpers.append_to_buffer(self.buffer, {prefix .. line})
  end
end

function TaskContext:mark_completed(exit_code)
  self.end_time = os.time()
  self.exit_code = exit_code
  
  if exit_code == 0 then
    self.state = TASK_STATES.SUCCESS
  else
    self.state = TASK_STATES.FAILED
  end
  
  -- Add footer to buffer
  if self.buffer then
    local duration = self.end_time - (self.start_time or self.end_time)
    local footer = {
      "",
      "=== Task Completed ===",
      "Exit Code: " .. exit_code,
      "Duration: " .. duration .. "s",
      "Status: " .. self.state,
      "Finished: " .. os.date("%Y-%m-%d %H:%M:%S")
    }
    
    buffer_helpers.append_to_buffer(self.buffer, footer)
  end
  
  -- Remove from active tasks
  active_tasks[self.task.name] = nil
end

-- Execute a single task
-- @param task table: Task configuration
-- @param project_root string: Project root directory
-- @param callback function: Completion callback (context, success)
-- @return TaskContext: Task execution context
function M.execute_task(task, project_root, callback)
  validation.assert_table(task, "task", false)
  validation.assert_string(project_root, "project_root", false)
  validation.assert_function(callback, "callback", true)
  
  local context = TaskContext:new(task, project_root)
  
  -- Validate task has required fields
  if not task.name or not task.command then
    context.state = TASK_STATES.FAILED
    if callback then
      callback(context, false)
    end
    return context
  end
  
  -- Check if task is already running
  if active_tasks[task.name] then
    ui_helpers.show_warning("Task '" .. task.name .. "' is already running", "execute_task")
    if callback then
      callback(context, false)
    end
    return context
  end
  
  -- Mark as active
  active_tasks[task.name] = context
  context.state = TASK_STATES.RUNNING
  context.start_time = os.time()
  
  -- Create output buffer
  context:create_output_buffer()
  
  -- Parse command and arguments
  local cmd_parts = vim.split(task.command, " ", {plain = false, trimempty = true})
  local command = cmd_parts[1]
  local args = {}
  for i = 2, #cmd_parts do
    table.insert(args, cmd_parts[i])
  end
  
  -- Get working directory and environment
  local working_dir = context:get_working_directory()
  local env = context:get_environment()
  
  ui_helpers.show_info("Starting task: " .. task.name, "execute_task")
  
  -- Create and start job
  context.job = Job:new({
    command = command,
    args = args,
    cwd = working_dir,
    env = env,
    on_stdout = vim.schedule_wrap(function(_, line)
      context:log_output(line, false)
    end),
    on_stderr = vim.schedule_wrap(function(_, line)
      context:log_output(line, true)
    end),
    on_exit = vim.schedule_wrap(function(_, exit_code)
      context:mark_completed(exit_code)
      
      if exit_code == 0 then
        ui_helpers.show_success("Task completed: " .. task.name, "execute_task")
      else
        ui_helpers.show_error("Task failed: " .. task.name .. " (exit code: " .. exit_code .. ")", "execute_task")
      end
      
      if callback then
        callback(context, exit_code == 0)
      end
    end)
  })
  
  -- Start the job
  context.job:start()
  
  return context
end

-- Execute multiple tasks in sequence
-- @param tasks table: Array of task configurations
-- @param project_root string: Project root directory  
-- @param callback function: Completion callback (all_contexts, all_success)
-- @return table: Array of TaskContext objects
function M.execute_tasks_sequence(tasks, project_root, callback)
  validation.assert_table(tasks, "tasks", false)
  validation.assert_string(project_root, "project_root", false)
  validation.assert_function(callback, "callback", true)
  
  local contexts = {}
  local current_index = 1
  local all_success = true
  
  local function execute_next()
    if current_index > #tasks then
      -- All tasks completed
      if callback then
        callback(contexts, all_success)
      end
      return
    end
    
    local task = tasks[current_index]
    current_index = current_index + 1
    
    local context = M.execute_task(task, project_root, function(ctx, success)
      table.insert(contexts, ctx)
      
      if not success then
        all_success = false
        -- Stop execution on failure
        if callback then
          callback(contexts, all_success)
        end
        return
      end
      
      -- Continue with next task
      execute_next()
    end)
    
    -- If task failed to start, mark as failure and continue
    if context.state == TASK_STATES.FAILED then
      table.insert(contexts, context)
      all_success = false
      if callback then
        callback(contexts, all_success)
      end
    end
  end
  
  execute_next()
  return contexts
end

-- Execute tasks with dependency resolution
-- @param task_names table: Array of task names to execute
-- @param all_tasks table: All available tasks
-- @param project_root string: Project root directory
-- @param callback function: Completion callback (contexts, success)
-- @return table: Array of TaskContext objects
function M.execute_with_dependencies(task_names, all_tasks, project_root, callback)
  validation.assert_table(task_names, "task_names", false)
  validation.assert_table(all_tasks, "all_tasks", false)
  validation.assert_string(project_root, "project_root", false)
  validation.assert_function(callback, "callback", true)
  
  -- Build task map
  local task_map = {}
  for _, task in ipairs(all_tasks) do
    if task.name then
      task_map[task.name] = task
    end
  end
  
  -- Resolve execution order
  local execution_order = {}
  local resolved = {}
  local resolving = {}
  
  local function resolve_deps(task_name)
    if resolved[task_name] then
      return true
    end
    
    if resolving[task_name] then
      ui_helpers.show_error("Circular dependency detected: " .. task_name, "execute_with_dependencies")
      return false
    end
    
    local task = task_map[task_name]
    if not task then
      ui_helpers.show_error("Task not found: " .. task_name, "execute_with_dependencies")
      return false
    end
    
    resolving[task_name] = true
    
    -- Resolve dependencies first
    if task.previous then
      for _, dep_name in ipairs(task.previous) do
        if not resolve_deps(dep_name) then
          return false
        end
      end
    end
    
    resolving[task_name] = nil
    resolved[task_name] = true
    
    if not vim.tbl_contains(execution_order, task_name) then
      table.insert(execution_order, task_name)
    end
    
    return true
  end
  
  -- Resolve all requested tasks
  for _, task_name in ipairs(task_names) do
    if not resolve_deps(task_name) then
      if callback then
        callback({}, false)
      end
      return {}
    end
  end
  
  -- Build execution list
  local tasks_to_execute = {}
  for _, task_name in ipairs(execution_order) do
    local task = task_map[task_name]
    if task then
      table.insert(tasks_to_execute, task)
    end
  end
  
  ui_helpers.show_info("Executing " .. #tasks_to_execute .. " tasks in order: " .. table.concat(execution_order, " → "), "execute_with_dependencies")
  
  return M.execute_tasks_sequence(tasks_to_execute, project_root, callback)
end

-- Cancel a running task
-- @param task_name string: Name of the task to cancel
-- @return boolean: True if task was cancelled
function M.cancel_task(task_name)
  validation.assert_string(task_name, "task_name", false)
  
  local context = active_tasks[task_name]
  if not context then
    return false
  end
  
  if context.job then
    context.job:shutdown()
    context.state = TASK_STATES.CANCELLED
    context.end_time = os.time()
    
    ui_helpers.show_warning("Task cancelled: " .. task_name, "cancel_task")
    
    -- Log cancellation to buffer
    if context.buffer then
      buffer_helpers.append_to_buffer(context.buffer, {"", "=== Task Cancelled ==="})
    end
    
    active_tasks[task_name] = nil
    return true
  end
  
  return false
end

-- Cancel all running tasks
-- @return number: Number of tasks cancelled
function M.cancel_all_tasks()
  local cancelled = 0
  local task_names = vim.tbl_keys(active_tasks)
  
  for _, task_name in ipairs(task_names) do
    if M.cancel_task(task_name) then
      cancelled = cancelled + 1
    end
  end
  
  if cancelled > 0 then
    ui_helpers.show_info("Cancelled " .. cancelled .. " running tasks", "cancel_all_tasks")
  end
  
  return cancelled
end

-- Get status of running tasks
-- @return table: Map of task_name -> TaskContext for active tasks
function M.get_active_tasks()
  return vim.deepcopy(active_tasks)
end

-- Get task execution history for a task
-- @param task_name string: Name of the task
-- @return table|nil: TaskContext for the task or nil if not found
function M.get_task_history(task_name)
  validation.assert_string(task_name, "task_name", false)
  
  -- For now, we only track active tasks
  -- Could be extended to maintain execution history
  return active_tasks[task_name]
end

-- Check if any tasks are currently running
-- @return boolean: True if any tasks are running
function M.has_running_tasks()
  return next(active_tasks) ~= nil
end

-- Get task output buffer
-- @param task_name string: Name of the task
-- @return number|nil: Buffer number or nil if not found
function M.get_task_buffer(task_name)
  validation.assert_string(task_name, "task_name", false)
  return task_buffers[task_name]
end

-- Clean up completed task buffers
-- @param keep_recent number: Number of recent buffers to keep (optional, defaults to 5)
function M.cleanup_task_buffers(keep_recent)
  keep_recent = keep_recent or 5
  
  -- For now, just clear all non-active task buffers
  for task_name, buffer in pairs(task_buffers) do
    if not active_tasks[task_name] then
      if vim.api.nvim_buf_is_valid(buffer) then
        vim.api.nvim_buf_delete(buffer, {force = true})
      end
      task_buffers[task_name] = nil
    end
  end
end

-- Export task states for external use
M.TASK_STATES = TASK_STATES

return M