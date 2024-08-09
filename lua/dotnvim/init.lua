local M = {}

local bootstrappers = require('dotnvim.bootstrappers')
local telescope_utils = require('dotnvim.utils.telescope_utils')
local dotnvim_builders = require('dotnvim.builder')
local dotnvim_utils = require('dotnvim.utils')
local configurator = require('dotnvim.config')
local nuget_client = require('dotnvim.nuget')

-- Ensure Neovim version is at least 0.9.0
if vim.fn.has("nvim-0.9.0") ~= 1 then
    vim.api.nvim_err_writeln("dotnvim requires at least nvim-0.9.0.")
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

-- Dotnvim plugin setup
vim.g.Dotnvim = {
    last_used_csproj = nil,
    running_job = nil,
    running_watch = nil,
    log = {
        debug = function(message) log.debug(message) end,
        info  = function(message) log.info(message) end,
        warn  = function(message) log.warn(message) end,
        error = function(message) log.error(message) end,
    }
}

-- Configuration settings for Dotnvim
vim.g.DotnvimConfig = {
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
        }
    },
    nuget = {
        sources = {},
        authenticators = {
            {
                cmd = "",
                args = {}
            }
        }
    }
}

M.default_params = {
    bootstrap_verbose = false,
    bootstrap_namespace = nil
}

-- Build the last used project or prompt for selection
function M.build(last)
    if vim.g.Dotnvim.last_used_csproj and last then
        dotnvim_builders.dotnet_build(vim.g.Dotnvim.last_used_csproj)
    else
        dotnvim_utils.select_csproj(dotnvim_builders.dotnet_build)
    end
end

-- Watch the last used project or prompt for selection
function M.watch(last)
    if vim.g.Dotnvim.last_used_csproj and last then
        dotnvim_builders.dotnet_watch(vim.g.Dotnvim.last_used_csproj)
    else
        dotnvim_utils.select_csproj(dotnvim_builders.dotnet_watch)
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
    print(vim.g.Dotnvim.last_used_csproj)
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

    -- Merge the incoming configuration with the defaults
    vim.g.DotnvimConfig = vim.tbl_deep_extend("force", vim.g.DotnvimConfig, {
        builders = config.builders or {},
        dap = config.dap or {},
        nuget = config.nuget or {},
        ui = config.ui or {}
    })

    -- Apply the merged configuration
    configurator.configurate_dap(vim.g.DotnvimConfig.dap)
end

function M.nuget_auth()
    nuget_client.authenticate()
end

return M

