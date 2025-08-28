local M = {}

-- [[
--      Credit to [MoaidHathot](https://github.com/MoaidHathot/dotnet.nvim) on github for the utils that i am stealing here
-- ]]
local namespace_resolver = require('dotnvim.utils.namespace_resolver')
local dotnvim_templates = require('dotnvim.utils.templates')
local validation = require('dotnvim.utils.validation')
local ui_helpers = require('dotnvim.utils.ui_helpers')

function M.bootstrap_model(name, namespace)
    validation.assert_string(name, "name", false)
    
    local path = ''
    if namespace == nil then
        local n = namespace_resolver.get_current_file_and_namespace()
        if not n then
            ui_helpers.show_error("Could not determine namespace from current file", "bootstrap_model")
            return nil
        end
        path = n.path
        namespace = n.namespace
    else
        validation.assert_string(namespace, "namespace", false)
        path = string.gsub(namespace, '.', '/')
    end
    
    local working_filename = path .. name .. ".cs"
    ui_helpers.show_info("Creating model: " .. working_filename, "bootstrap_model")
    
    return {
        filename = working_filename,
        filepath = path,
        buffer = dotnvim_templates.dotnvim_api_model_template(name, namespace)
    }
end

function M.bootstrap_api_controller(name, namespace)
    validation.assert_string(name, "name", false)
    
    local path = ''
    if namespace == nil then
        local n = namespace_resolver.get_current_file_and_namespace()
        if not n then
            ui_helpers.show_error("Could not determine namespace from current file", "bootstrap_api_controller")
            return nil
        end
        path = n.path
        namespace = n.namespace
    else
        validation.assert_string(namespace, "namespace", false)
        path = string.gsub(namespace, '.', '/')
    end
    
    return {
        filename = path .. name .. ".cs",
        filepath = path,
        buffer = dotnvim_templates.dotnvim_api_controller_template(name, namespace)
    }
end

function M.bootstrap_api_controller_rw(name, namespace)
    validation.assert_string(name, "name", false)
    
    local path = ''
    if namespace == nil then
        local n = namespace_resolver.get_current_file_and_namespace()
        if not n then
            ui_helpers.show_error("Could not determine namespace from current file", "bootstrap_api_controller_rw")
            return nil
        end
        path = n.path
        namespace = n.namespace
    else
        validation.assert_string(namespace, "namespace", false)
        path = string.gsub(namespace, '.', '/')
    end
    
    return {
        filename = path .. name .. ".cs",
        filepath = path,
        buffer = dotnvim_templates.dotnvim_api_mvc_controller_template(name, namespace)
    }
end

function M.bootstrap_razor_component(name, namespace)
    validation.assert_string(name, "name", false)
    
    local path = ''
    if namespace == nil then
        local n = namespace_resolver.get_current_file_and_namespace()
        if not n then
            ui_helpers.show_error("Could not determine namespace from current file", "bootstrap_razor_component")
            return nil
        end
        path = n.path
        namespace = n.namespace
    else
        validation.assert_string(namespace, "namespace", false)
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
