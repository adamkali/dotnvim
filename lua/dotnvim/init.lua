local M = {}

local bootstrappers = require('dotnvim.bootstrappers')
local telescope_utils = require('dotnvim.utils.telescope_utils')
local dotnvim_builders = require('dotnvim.builder')
local dotnvim_utils = require('dotnvim.utils')
local configurator = require('dotnvim.config')
local Job = require 'plenary.job'

M.default_params = {
    bootstrap_verbose = false,
    bootstrap_namespace = nil
}

-- @param last_used_csproj string
-- @param running_watch plenary.Job
Dotnvim = {
    last_used_csproj = nil,
    running_job = nil,
    running_watch = nil
}

-- @param last bool
function M.build(last)
    -- also do one that asks if not passed in?
    if Dotnvim.last_used_csproj ~= nil and last == true then
        dotnvim_builders.dotnet_build(Dotnvim.last_used_csproj)
    else
        dotnvim_utils.select_csproj(dotnvim_builders.dotnet_build)
    end
end

function M.watch(last)
    if Dotnvim.last_used_csproj ~= nil and last == true then
        dotnvim_builders.dotnet_watch(Dotnvim.last_used_csproj)
    else
        dotnvim_utils.select_csproj(dotnvim_builders.dotnet_watch)
    end
end

function M.check()
    require 'dotnvim.health'.check()
end

function M.bootstrap()
    local selection = {}
    if pcall(require, 'telescope') then
        selection = telescope_utils.telescope_select_bootstrapper(bootstrappers.bootstrappers)
    end
    if selection == nil then
        -- TODO: vim.ui.select(bootstrappers.bootstrapers)
        return
    end
end

function M.query_last_ran_csproj()
    return print(Dotnvim.last_used_csproj)
end

function M.restart_watch()
    dotnvim_builders.restart_dotnet_watch()
end

M.shutdown_watch = function()
    dotnvim_builders.kill_dotnet_process()
end

function M.select_csproj(callback)
    if type(callback) == "function" then
        return dotnvim_utils.select_csproj(callback)
    end
    error("Callback passed to select_csproj is nil")
end

function M.setup(config)
    config = config or {}
    print("setup")

    configurator.configurate_builders(config.builders)
    configurator.configurate_ui(config.ui)
    configurator.configurate_dap(config.dap)
end

return M
