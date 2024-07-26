local M = {}

local bootstrappers = require 'dotnvim.bootstrappers'
local telescope_utils = require 'dotnvim.utils.telescope_utils'
local dotnvim_utils = require('dotnvim.utils')
local dotnvim_build = require('dotnvim.builder')
--local Job = require('plenary.job')

M.default_params = {
    bootstrap_verbose = false,
    bootstrap_namespace = nil
}

-- @param last bool
function M.build(last)
    -- also do one that asks if not passed in?
    if Dotnvim.last_used_csproj ~= nil and last == true then
        dotnvim_build.dotnet_build(Dotnvim.last_used_csproj)
    elseif Dotnvim.last_used_csproj == nil and last == true then
        error("Dotnvim.last_used_csproj is nil.\nMost likely you have not built anything during this session.")
        return
    else
        --local selection = {}
        local selections = dotnvim_utils.get_all_csproj()
        if pcall(require, 'telescope') then
            telescope_utils.telescope_select_csproj(selections, dotnvim_build.dotnet_build)
        else
            --selection = vim.ui.select(selections)
        end
    end
end

function M.watch(last)
    if Dotnvim.last_used_csproj ~= nil and last == true then
        dotnvim_build.dotnet_build(Dotnvim.last_used_csproj)
    elseif Dotnvim.last_used_csproj == nil and last == true then
        error("Dotnvim.last_used_csproj is nil.\nMost likely you have not built anything during this session.")
        return
    else
        --local selection = {}
        local selections = dotnvim_utils.get_all_csproj()
        if pcall(require, 'telescope') then
            telescope_utils.telescope_select_csproj(selections, dotnvim_build.dotnet_watch)
        else
            --selection = vim.ui.select(selections)
        end
    end
end

function M.check()
    require'dotnvim.health'.check()
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


function M.setup()
end

return M


