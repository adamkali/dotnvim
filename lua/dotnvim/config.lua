local dotnvim_util = require('dotnvim.utils')
local config_manager = require('dotnvim.config_manager')
local configurator = {}
local load_module = dotnvim_util.load_module

configurator.configurate_adapter = function()
    local dap = load_module("dap", "dotnvim.dap")
    local dap_config = config_manager.get_dap_config()
    dap.adapters.coreclr = dap_config.adapter
    dap.adapters.netcoredbg = dap_config.adapter
end

-- aka the boulivard of broken dreams
configurator.configurate_dap = function(config_dap)
    local configurations = {}

    if config_dap ~= nil then
        table.insert(configurations, config_dap.configurations)
    end

    local dap = load_module("dap", "dotnvim.dap")
    configurator.configurate_adapter()
    dap.configurations.cs = {}

    for _, config in ipairs(configurations) do
        if config.type == "netcoredbg"  then
            print(config.name)
            table.insert(dap.configurations.cs, config)
        end
    end
end

return configurator
