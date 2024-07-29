local dotnvim_util = require('dotnvim.utils')
local configurator = {}
local load_module = dotnvim_util.load_module

configurator.configurate_adaptor = function(config)
    local dap = load_module("dap", "dotnvim.dap")
    local args = { '--interpreter=vscode' }
    vim.list_extend(args, config.args)

    dap.adapters.coreclr = {
        type = "server",
        port = config.port,
        executable = {
            command = config.path,
            args = args,
            detached = config.detached,
            cwd = config.cwd,
        },
        options = {
            initiaize_timeout_sec = config.initiaize_timeout_sec,
        }
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
                local using_dll = ""
                local function set_dll(csproj)
                    return dotnvim_util.get_dll_from_csproj(csproj)
                end
                if Dotnvim.last_used_csproj ~= nil then
                    set_dll(Dotnvim.last_used_csproj)
                else
                    dotnvim_util.select_csproj(set_dll)
                end
                return using_dll
            end
        }

    }
    if config_dap ~= nil then
        vim.tbl_extend(configurations, config_dap.configurations)
        DotnvimConfig.dap.configurations = configurations
    end

    local dap = load_module("dap", "dotnvim.dap")
    configurator.configurate_adapter(config.adapter)

    for _, config in ipairs(DotnvimConfig.dap.configurations) do
        if config.type == "coreclr" then
            vim.print(config)
            table.insert(dap.configurations.cs, config)
        end
    end
end

return configurator
