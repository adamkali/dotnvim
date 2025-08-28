-- Comprehensive logging utility for dotnvim debugging
local M = {}

-- Log levels
local LOG_LEVELS = {
  TRACE = 1,
  DEBUG = 2,
  INFO = 3,
  WARN = 4,
  ERROR = 5,
  FATAL = 6
}

-- Reverse mapping for level names
local LEVEL_NAMES = {
  [1] = "TRACE",
  [2] = "DEBUG", 
  [3] = "INFO",
  [4] = "WARN",
  [5] = "ERROR",
  [6] = "FATAL"
}

-- Logger state
local logger_state = {
  debug_mode = false,
  log_file_path = vim.fn.stdpath('data') .. '/dotnvim.log',
  min_level = LOG_LEVELS.INFO,
  max_file_size = 10 * 1024 * 1024, -- 10MB
  initialized = false
}

-- Initialize logger
function M.init(config)
  config = config or {}
  
  -- Update state from config
  logger_state.debug_mode = config.debug_mode or false
  logger_state.log_file_path = config.log_file_path or logger_state.log_file_path
  logger_state.min_level = config.debug_mode and LOG_LEVELS.DEBUG or LOG_LEVELS.INFO
  
  -- Ensure log directory exists
  local log_dir = vim.fn.fnamemodify(logger_state.log_file_path, ':h')
  vim.fn.mkdir(log_dir, 'p')
  
  -- Rotate log file if it's too large
  M.rotate_if_needed()
  
  logger_state.initialized = true
  
  -- Log initialization
  M.info("logger", "Logger initialized - Debug mode: " .. tostring(logger_state.debug_mode))
end

-- Check if logging is enabled for level
local function should_log(level)
  return logger_state.initialized and level >= logger_state.min_level
end

-- Format log entry
local function format_log_entry(level, component, message)
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local level_name = LEVEL_NAMES[level] or "UNKNOWN"
  return string.format("[%s] [%s] [%s] %s\n", timestamp, level_name, component, message)
end

-- Write to log file
local function write_to_file(entry)
  if not logger_state.initialized then
    return
  end
  
  local file = io.open(logger_state.log_file_path, 'a')
  if file then
    file:write(entry)
    file:close()
  end
end

-- Rotate log file if needed
function M.rotate_if_needed()
  local stat = vim.loop.fs_stat(logger_state.log_file_path)
  if stat and stat.size > logger_state.max_file_size then
    local backup_path = logger_state.log_file_path .. '.old'
    os.rename(logger_state.log_file_path, backup_path)
  end
end

-- Core logging function
local function log(level, component, message)
  if not should_log(level) then
    return
  end
  
  -- Handle table/complex objects
  if type(message) == "table" then
    message = vim.inspect(message)
  else
    message = tostring(message)
  end
  
  local entry = format_log_entry(level, component, message)
  write_to_file(entry)
  
  -- Also show in console for WARN and above (if debug mode)
  if logger_state.debug_mode and level >= LOG_LEVELS.WARN then
    local level_name = LEVEL_NAMES[level] or "LOG"
    vim.notify("[dotnvim:" .. component .. "] " .. message, 
               level >= LOG_LEVELS.ERROR and vim.log.levels.ERROR or vim.log.levels.WARN)
  end
end

-- Public logging functions
function M.trace(component, message)
  log(LOG_LEVELS.TRACE, component, message)
end

function M.debug(component, message)
  log(LOG_LEVELS.DEBUG, component, message)
end

function M.info(component, message)
  log(LOG_LEVELS.INFO, component, message)
end

function M.warn(component, message)
  log(LOG_LEVELS.WARN, component, message)
end

function M.error(component, message)
  log(LOG_LEVELS.ERROR, component, message)
end

function M.fatal(component, message)
  log(LOG_LEVELS.FATAL, component, message)
end

-- Log function call with arguments and return value
function M.log_function_call(component, func_name, args, result)
  if not should_log(LOG_LEVELS.DEBUG) then
    return
  end
  
  local args_str = args and vim.inspect(args) or "nil"
  local result_str = result and vim.inspect(result) or "nil"
  
  M.debug(component, string.format("CALL %s(%s) -> %s", func_name, args_str, result_str))
end

-- Log state changes
function M.log_state_change(component, state_name, old_value, new_value)
  if not should_log(LOG_LEVELS.DEBUG) then
    return
  end
  
  M.debug(component, string.format("STATE %s: %s -> %s", 
    state_name, 
    vim.inspect(old_value), 
    vim.inspect(new_value)))
end

-- Log with stack trace
function M.debug_with_trace(component, message)
  if not should_log(LOG_LEVELS.DEBUG) then
    return
  end
  
  local trace = debug.traceback("", 2)
  M.debug(component, message .. "\n" .. trace)
end

-- Get current logger config
function M.get_config()
  return {
    debug_mode = logger_state.debug_mode,
    log_file_path = logger_state.log_file_path,
    min_level = logger_state.min_level,
    initialized = logger_state.initialized
  }
end

-- Enable/disable debug mode
function M.set_debug_mode(enabled)
  local old_debug = logger_state.debug_mode
  logger_state.debug_mode = enabled
  logger_state.min_level = enabled and LOG_LEVELS.DEBUG or LOG_LEVELS.INFO
  
  M.info("logger", "Debug mode changed: " .. tostring(old_debug) .. " -> " .. tostring(enabled))
end

-- Clear log file
function M.clear_log()
  local file = io.open(logger_state.log_file_path, 'w')
  if file then
    file:close()
    M.info("logger", "Log file cleared")
  end
end

-- Get log file path
function M.get_log_file_path()
  return logger_state.log_file_path
end

return M