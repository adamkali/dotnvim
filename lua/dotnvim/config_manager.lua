local M = {}

-- Default configuration
local default_config = {
  builders = {
    build_output_callback = nil,
    https_launch_setting_always = true,
  },
  ui = {
    no_pretty_uis = false,
  },
  dap = {
    adapter = {
      type = 'executable',
      command = "netcoredbg",
      args = { '--interpreter=vscode' },
    },
    configurations = {},
  },
  nuget = {
    sources = {},
    authenticators = {},
  },
  tasks = {
    enabled = true,
    execution_mode = "dependency_aware",  -- "sequential", "dependency_aware"
    output_window = {
      mode = "new_buffer",  -- "horizontal_split", "vertical_split", "new_buffer"
      size = nil,  -- Size of split (nil = auto, number = lines/columns)
      focus = false,  -- Whether to focus the task output window
    },
    dap_integration = {
      enabled = true,
      pre_debug_tasks = nil,  -- Auto-discover or specify: {"pre-debug", "build"}
      block_on_failure = true,
      timeout_seconds = 300,
    }
  },
  debug = {
    enabled = false,  -- Enable debug logging
    log_file_path = nil,  -- Custom log file path (nil uses default)
  }
}

-- Runtime state (separate from config)
local state = {
  last_used_csproj = nil,
  running_job = nil,
  running_watch = nil,
  log = nil, -- Will be initialized with actual logger
}

-- Configuration validation schema
local function validate_config(config)
  if type(config) ~= "table" then
    return false, "Config must be a table"
  end

  -- Validate builders section
  if config.builders then
    if type(config.builders) ~= "table" then
      return false, "builders must be a table"
    end
    if config.builders.https_launch_setting_always ~= nil and type(config.builders.https_launch_setting_always) ~= "boolean" then
      return false, "builders.https_launch_setting_always must be a boolean"
    end
  end

  -- Validate UI section
  if config.ui then
    if type(config.ui) ~= "table" then
      return false, "ui must be a table"
    end
    if config.ui.no_pretty_uis ~= nil and type(config.ui.no_pretty_uis) ~= "boolean" then
      return false, "ui.no_pretty_uis must be a boolean"
    end
  end

  -- Validate DAP section
  if config.dap then
    if type(config.dap) ~= "table" then
      return false, "dap must be a table"
    end
    if config.dap.adapter then
      if type(config.dap.adapter) ~= "table" then
        return false, "dap.adapter must be a table"
      end
      if config.dap.adapter.type and type(config.dap.adapter.type) ~= "string" then
        return false, "dap.adapter.type must be a string"
      end
      if config.dap.adapter.command and type(config.dap.adapter.command) ~= "string" then
        return false, "dap.adapter.command must be a string"
      end
      if config.dap.adapter.args and type(config.dap.adapter.args) ~= "table" then
        return false, "dap.adapter.args must be a table"
      end
    end
    if config.dap.configurations and type(config.dap.configurations) ~= "table" then
      return false, "dap.configurations must be a table"
    end
  end

  -- Validate NuGet section
  if config.nuget then
    if type(config.nuget) ~= "table" then
      return false, "nuget must be a table"
    end
    if config.nuget.sources and type(config.nuget.sources) ~= "table" then
      return false, "nuget.sources must be a table"
    end
    if config.nuget.authenticators then
      if type(config.nuget.authenticators) ~= "table" then
        return false, "nuget.authenticators must be a table"
      end
      for i, auth in ipairs(config.nuget.authenticators) do
        if type(auth) ~= "table" then
          return false, "nuget.authenticators[" .. i .. "] must be a table"
        end
        if auth.cmd and type(auth.cmd) ~= "string" then
          return false, "nuget.authenticators[" .. i .. "].cmd must be a string"
        end
        if auth.args and type(auth.args) ~= "table" then
          return false, "nuget.authenticators[" .. i .. "].args must be a table"
        end
      end
    end
  end

  return true, nil
end

-- Internal config storage
local current_config = vim.deepcopy(default_config)

-- Setup function to merge user config with defaults
function M.setup(user_config)
  user_config = user_config or {}

  -- Validate user config
  local valid, error_msg = validate_config(user_config)
  if not valid then
    vim.notify("dotnvim config error: " .. error_msg, vim.log.levels.ERROR)
    return false
  end

  -- Deep merge user config with defaults
  current_config = vim.tbl_deep_extend("force", current_config, user_config)
  
  vim.notify("dotnvim configuration loaded successfully", vim.log.levels.INFO)
  return true
end

-- Getter functions for config sections
function M.get_config()
  return vim.deepcopy(current_config)
end

function M.get_builders_config()
  return current_config.builders
end

function M.get_ui_config()
  return current_config.ui
end

function M.get_dap_config()
  return current_config.dap
end

function M.get_nuget_config()
  return current_config.nuget
end

function M.get_tasks_config()
  return current_config.tasks
end

function M.get_debug_config()
  return current_config.debug
end

-- State management functions
function M.init_state(logger)
  state.log = {
    debug = function(message) logger.debug(message) end,
    info  = function(message) logger.info(message) end,
    warn  = function(message) logger.warn(message) end,
    error = function(message) logger.error(message) end,
  }
end

function M.get_state()
  return state
end

function M.set_last_used_csproj(path)
  state.last_used_csproj = path
end

function M.get_last_used_csproj()
  return state.last_used_csproj
end

function M.set_running_watch(job)
  state.running_watch = job
end

function M.get_running_watch()
  return state.running_watch
end

function M.get_logger()
  return state.log
end

-- Helper function to check if config is initialized
function M.is_initialized()
  return state.log ~= nil
end

-- Reset to defaults (useful for testing)
function M.reset_to_defaults()
  current_config = vim.deepcopy(default_config)
  state = {
    last_used_csproj = nil,
    running_job = nil,
    running_watch = nil,
    log = nil,
  }
end

return M
