local NugetClient = {}

NugetClient.authenticate = function()
    local Job = require('plenary.job')
    vim.print(vim.g.DotnvimConfig.nuget.authenticators)
    for _, authenticator in ipairs(vim.g.DotnvimConfig.nuget.authenticators) do
        vim.print(authenticator)
        Job:new({
            command = authenticator.cmd,
            args = authenticator.args,
            on_exit = function(j, return_val)
                local cmd = authenticator.cmd .. " " .. table.concat(authenticator.args, " ")
                if return_val == 0 then
                    vim.g.Dotnvim.log.info("Command executed successfully: " .. cmd)
                    print("Command executed successfully: " .. cmd)
                else
                    vim.g.Dotnvim.log.error("Command execution failed: " .. cmd)
                    vim.g.Dotnvim.log.error("Error: " .. table.concat(j:stderr_result(), "\n"))
                    print("Command execution failed: " .. cmd)
                end
            end,
            on_stderr = function(_, data)
                vim.g.Dotnvim.log.error("stderr: " .. data)
            end,
        }):start()
    end
end

return NugetClient
