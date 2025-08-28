local M = {}

local bootstrappers = require('dotnvim.bootstrappers')
local telescope_utils = require('dotnvim.utils.telescope_utils')
local dotnvim_builders = require('dotnvim.builder')
local dotnvim_utils = require('dotnvim.utils')
local configurator = require('dotnvim.config')
local nuget_client = require('dotnvim.nuget')
local config_manager = require('dotnvim.config_manager')
local tasks = require('dotnvim.tasks')
local dap_hooks = require('dotnvim.dap_hooks')
local logger = require('dotnvim.utils.logger')
local ui = require('dotnvim.ui')

-- Ensure Neovim version is at least 0.9.0
if vim.fn.has("nvim-0.9.0") ~= 1 then
    vim.notify("dotnvim requires at least nvim-0.9.0.", vim.log.levels.ERROR)
    return
end

-- Setup logging functionality with plenary
local log_file_path = vim.fn.stdpath('data') .. '/dotnvim.log'
local log = require('plenary.log').new({
    plugin = 'dotnvim',
    level = 'debug',           -- Set log level (trace, debug, info, warn, error, fatal)
    use_console = false,       -- Optionally log to the console
    highlights = true,         -- Enable highlighting in the log
    use_file = true,           -- Enable file logging
    file_path = log_file_path, -- Specify the custom log file path
    file_level = 'debug',      -- Set the file log level
    float_precision = 0.01,    -- Floating point precision for numbers
})

-- Initialize config manager with defaults
config_manager.setup({})
config_manager.init_state(log)

M.default_params = {
    bootstrap_verbose = false,
    bootstrap_namespace = nil
}

-- Build the last used project or prompt for selection
function M.build(last)
    local last_csproj = config_manager.get_last_used_csproj()
    if last_csproj and last then
        return dotnvim_builders.dotnet_build(last_csproj)
    else
        dotnvim_utils.select_csproj(dotnvim_builders.dotnet_build)
        return true
    end
end

-- Watch the last used project or prompt for selection
function M.watch(last)
    local last_csproj = config_manager.get_last_used_csproj()
    if last_csproj and last then
        return dotnvim_builders.dotnet_watch(last_csproj)
    else
        dotnvim_utils.select_csproj(dotnvim_builders.dotnet_watch)
        return true
    end
end

-- Check the health of the plugin
function M.check()
    require('dotnvim.health').check()
end

-- Bootstrap configuration
function M.bootstrap()
    local selection = {}
    if pcall(require, 'telescope') then
        selection = telescope_utils.telescope_select_bootstrapper(bootstrappers.bootstrappers)
    end
    if not selection then
        -- TODO: vim.ui.select(bootstrappers.bootstrapers)
        return
    end
end

-- Query last used .csproj
function M.query_last_ran_csproj()
    print(config_manager.get_last_used_csproj())
end

-- Restart the watch process
function M.restart_watch()
    dotnvim_builders.restart_dotnet_watch()
end

-- Shutdown the watch process
function M.shutdown_watch()
    dotnvim_builders.kill_dotnet_process()
end

-- Select a .csproj and run the provided callback
function M.select_csproj(callback)
    if type(callback) == "function" then
        return dotnvim_utils.select_csproj(callback)
    end
    error("Callback passed to select_csproj is nil")
end

-- Setup the plugin with user-provided configuration
function M.setup(config)
    config = config or {}

    -- Setup centralized configuration
    if not config_manager.setup(config) then
        return false
    end
    
    -- Initialize logger with debug configuration
    local debug_config = config_manager.get_debug_config()
    logger.init({
        debug_mode = debug_config.enabled,
        log_file_path = debug_config.log_file_path
    })

    -- Apply DAP configuration
    configurator.configurate_dap(config_manager.get_dap_config())
    
    -- Setup task system
    local tasks_config = config_manager.get_tasks_config()
    if tasks_config.enabled then
        tasks.setup({
            execution_mode = tasks_config.execution_mode
        })
        
        -- Setup DAP integration
        if tasks_config.dap_integration.enabled then
            dap_hooks.setup({
                enabled = tasks_config.dap_integration.enabled,
                pre_debug_tasks = tasks_config.dap_integration.pre_debug_tasks,
                block_debug_on_task_failure = tasks_config.dap_integration.block_on_failure,
                timeout_seconds = tasks_config.dap_integration.timeout_seconds
            })
        end
    end
    
    return true
end

function M.nuget_auth()
    nuget_client.authenticate()
end

-- Task system functions
function M.run_task(task_name, options, callback)
    return tasks.run_task(task_name, options, callback)
end

function M.run_tasks(task_names, options, callback)
    return tasks.execute_tasks(task_names, options, callback)
end

function M.cancel_tasks()
    return tasks.cancel_execution()
end

function M.get_available_tasks()
    return tasks.get_available_tasks()
end

function M.task_status()
    return tasks.status()
end

function M.create_task_config(format)
    return tasks.create_example_config(format)
end

-- UI functions
function M.show_config()
    ui.show_config()
end

function M.show_config_section(section)
    ui.show_config_section(section)
end

return M

