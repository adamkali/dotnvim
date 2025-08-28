local config_manager = require('dotnvim.config_manager')

local NugetClient = {}

NugetClient.authenticate = function()
    local Job = require('plenary.job')
    local nuget_config = config_manager.get_nuget_config()
    vim.print(nuget_config.authenticators)
    for _, authenticator in ipairs(nuget_config.authenticators) do
        vim.print(authenticator)
        Job:new({
            command = authenticator.cmd,
            args = authenticator.args,
            on_exit = function(j, return_val)
                local cmd = authenticator.cmd .. " " .. table.concat(authenticator.args, " ")
                local logger = config_manager.get_logger()
                if return_val == 0 then
                    logger.info("Command executed successfully: " .. cmd)
                    print("Command executed successfully: " .. cmd)
                else
                    logger.error("Command execution failed: " .. cmd)
                    logger.error("Error: " .. table.concat(j:stderr_result(), "\n"))
                    print("Command execution failed: " .. cmd)
                end
            end,
            on_stderr = function(_, data)
                config_manager.get_logger().error("stderr: " .. data)
            end,
        }):start()
    end
end

return NugetClient
