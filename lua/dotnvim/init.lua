local M = {}

local bootstrappers = require 'dotnvim.bootstrappers'
local telescope_utils = require 'dotnvim.utils.telescope_utils'
local dotnvim_utils = require('dotnvim.utils')
local dotnvim_build = require('dotnvim.builder')
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
        dotnvim_build.dotnet_build(Dotnvim.last_used_csproj)
    else
        --local selection = {}
        local selections = dotnvim_utils.get_all_csproj()
        if pcall(require, 'telescope') and DotnvimConfig.ui.no_pretty_uis ~= true then
            telescope_utils.telescope_select_csproj(selections, dotnvim_build.dotnet_build)
        else
            --selection = vim.ui.select(selections)
        end
    end
end

function M.watch(last)
    if Dotnvim.last_used_csproj ~= nil and last == true then
        dotnvim_build.dotnet_watch(Dotnvim.last_used_csproj)
    else
        local selections = dotnvim_utils.get_all_csproj()
        if pcall(require, 'telescope') and DotnvimConfig.ui.no_pretty_uis ~= true then
            telescope_utils.telescope_select_csproj(selections, dotnvim_build.start_dotnet_run)
        else
            --selection = vim.ui.select(selections)
        end
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

function M.last_ran_csproj()
    -- add pretty ui
    return print(Dotnvim.last_used_csproj)
end

local CTRL_C = string.char(3)
local CTRL_R = string.char(18)

function M.restart_watch()
    dotnvim_build.restart_dotnet_run()
end

M.shutdown_watch = function()
    dotnvim_build.kill_dotnet_process()
end

function M.setup(config)
    if config.builders ~= nil then
        if config.builders.build_output_callback ~= nil then
            assert(type(config.builders.build_output_callback), type(function() end))
            DotnvimConfig.builders.build_output_callback = config.builders.build_output_callback
        end
        if config.builders.https_launch_setting_always ~= nil then
            assert(type(config.builders.https_launch_setting_always), type(true))
            DotnvimConfig.builders.https_launch_setting_always = config.builders.https_launch_setting_always
        end
    end
    if config.ui ~= nil then
        if config.ui.no_pretty_uis ~= nil then
            assert(type(config.ui.no_pretty_uis), type(true))
            DotnvimConfig.ui.no_pretty_uis = config.ui.no_pretty_uis
        end
    end
end

return M
