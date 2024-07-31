local dotnvim_util = require('dotnvim.utils')
local configurator = {}
local load_module = dotnvim_util.load_module

configurator.configurate_adapter = function()
    local dap = load_module("dap", "dotnvim.dap")

    dap.adapters.coreclr = {
        type = 'executable',
        command = 'netcoredbg',
        args = { '--interpreter=vscode' }
    }
end


configurator.configurate_builders = function(builders)
    if builders ~= nil then
        if builders.build_output_callback ~= nil then
            assert(type(builders.build_output_callback), type(function() end))
            DotnvimConfig.builders.build_output_callback = builders.build_output_callback
        end
        if builders.https_launch_setting_always ~= nil then
            assert(type(builders.https_launch_setting_always), type(true))
            DotnvimConfig.builders.https_launch_setting_always = builders.https_launch_setting_always
        end
    end
end

configurator.configurate_ui = function(ui)
    if ui ~= nil then
        if ui.no_pretty_uis ~= nil then
            assert(type(ui.no_pretty_uis), type(true))
            DotnvimConfig.ui.no_pretty_uis = ui.no_pretty_uis
        end
    end
end

-- aka the boulivard of broken dreams
configurator.configurate_dap = function(config_dap)
    local configurations = {
        {
            type = 'coreclr',
            name = 'Launch Last Built .csproj',
            request = 'launch',
            program = function()
                if Dotnvim.last_used_csproj == nil then
                    -- TODO: Please make intelligent lookup based on solution.
                    -- - [ ] find out how the editor that shall not be named specifies default projects.
                    -- - [ ] find out better async call for calling an io process in lua and not have it jump over return 
                    print("Please Build your project First")
                end
                return dotnvim_util.get_dll_from_csproj(Dotnvim.last_used_csproj)
            end
        }
    }

    if config_dap ~= nil then
        vim.tbl_extend(configurations, config_dap.configurations)
    end

    local dap = load_module("dap", "dotnvim.dap")
    configurator.configurate_adapter()
    dap.configurations.cs = {}

    for _, config in ipairs(configurations) do
        if config.type == "coreclr" then
            table.insert(dap.configurations.cs, config)
        end
    end
end

return configurator
