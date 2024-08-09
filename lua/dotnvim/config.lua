local dotnvim_util = require('dotnvim.utils')
local configurator = {}
local load_module = dotnvim_util.load_module

configurator.configurate_adapter = function()
    local dap = load_module("dap", "dotnvim.dap")
    dap.adapters.coreclr = vim.g.DotnvimConfig.dap.adapter
    dap.adapters.netcoredbg = vim.g.DotnvimConfig.dap.adapter
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
