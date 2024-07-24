local M = {}

-- [[
--      Credit to [MoaidHathot](https://github.com/MoaidHathot/dotnet.nvim) on github for the utils that i am stealing here
-- ]]
local dotnet_utils = require 'dotnvim.utils'
local dotnvim_templates = require'dotnvim.utils.templates'

function M.bootstrap_model(name, namespace)
    local path = ''
    if namespace == nil then
        local n = dotnet_utils.get_curr_file_and_namespace()
        path = n.path
        namespace = n.namespace
    else
        -- for now wory about lin and wsl
        path = string.gsub(namespace, '.', '/')
    end
    local working_filename = path .. name .. ".cs"
    print(working_filename)
end

function M.bootstrap_api_controller(name, namespace)
    local path = ''
    if namespace == nil then
        local n = dotnet_utils.get_curr_file_and_namespace()
        path = n.path
        namespace = n.namespace
    else
        -- for now wory about lin and wsl
        path = string.gsub(namespace, '.', '/')
    end
    return {
        filename = path .. name .. ".cs",
        filepath = path,
        buffer = dotnvim_templates.dotnvim_api_controller_template(name, namespace)
    }
end

function M.bootstrap_api_controller_rw(name, namespace)
    local path = ''
    if namespace == nil then
        local n = dotnet_utils.get_curr_file_and_namespace()
        path = n.path
        namespace = n.namespace
    else
        -- for now wory about lin and wsl
        path = string.gsub(namespace, '.', '/')
    end
    return {
        filename = path .. name .. ".cs",
        filepath = path,
        buffer = dotnvim_templates.dotnvim_api_mvc_controller_template(name, namespace)
    }
end

function M.bootstrap_razor_component(name, namespace)
    local path = ''
    if namespace == nil then
        local n = dotnet_utils.get_curr_file_and_namespace()
        path = n.path
        namespace = n.namespace
    else
        -- for now wory about lin and wsl
        path = string.gsub(namespace, '.', '/')
    end
    return {
        filename = path .. name .. ".cs",
        filepath = path,
        buffer = dotnvim_templates.dotnvim_razor_component_template(name, namespace)
    }
end


M.bootstrappers = {
    {
        search = "c_sharp_model",
        name = "C# Model",
        callback = function (name, namespace)
            return dotnvim_templates.dotnvim_api_model_template(name, namespace)
        end,
        func = function (name, namespace)
            return M.bootstrap_api_model(name, namespace)
        end,
    },
    {
        search = "asp_net_api_controller_blank",
        name = "ASP.NET API Controller",
        callback = function (name, namespace)
            return dotnvim_templates.dotnvim_api_controller_template(name, namespace)
        end,
        func = function (name, namespace)
            return M.bootstrap_api_controller(name, namespace)
        end,
    },
    {
        search = "asp_net_api_controller_read_write",
        name = "ASP.NET API Controller With Read Write",
        callback= function(name, namespace)
            return dotnvim_templates.dotnvim_api_controller_template(name, namespace)
        end,
        func = function (name, namespace)
            return M.bootstrap_api_controller(name, namespace)
        end,
    },
    {
        search = "razor_component",
        name = ".NET Razor Component",
        callback= function(name, namespace)
            return dotnvim_templates.dotnvim_razor_component_template(name, namespace)
        end,
        func = function (name, namespace)
            return M.bootstrap_razor_component(name, namespace)
        end,
    }
}

return M

--require("luasnip.loaders.from_lua").load({paths = "~/.config/nvim/LuaSnip/"})
