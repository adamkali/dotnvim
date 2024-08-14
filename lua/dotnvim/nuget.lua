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

--- @param query string: provide to nuget what packages to add to the project
--- @param source string | nil: if source is nil, default to having nuget check in 'all', if the source is a .csproj in the current loaded cwd. This function will then return any packages installed with version.
--- @return table:  list of tables each containing the necissary data to install the package, update the package, or delet the project.
NugetClient.get_packages_from_source = function(query, source)
    local packages = {}
    local Job = require('plenary.job')

    local args = { 'list' }
    if source then table.insert(args, source) end
    if query then table.insert(args, query) end

    Job:new({
        command = 'dotnet',
        args = args,
        on_exit = function(j, return_val)
            if return_val == 0 then
                for _, line in ipairs(j:result()) do
                    local package_name, version = string.match(line, "(%S+)%s+%[(%S+)%]")
                    if package_name and version then
                        table.insert(packages, { name = package_name, version = version })
                    end
                end
            else
                vim.g.Dotnvim.log.error("Failed to retrieve packages from source: " .. source)
            end
        end,
    }):sync()

    return packages
end

--- @param package table: package is the same shape as what is returned from the NugetClient.get_packages_from_source function. It will use this table to determine what cli arguments to pass to nuget cli
--- @param version string | nil: specifies which version number dotnvim.NugetClient should install. If nil, dotnvim.NugetClient will default to latest compatable release for for currently installed .Net sdk,
--- @param projects table | nil | {}: a list of csproj paths to add the package to. If nil or an empty table, dotnvim.NugetClient will default the install to all.
NugetClient.install_package_to_project = function(package, version, projects)
end

--- @param package table: package is the same shape as what is returned from the NugetClient.get_packages_from_source function. It will use this table to determine what cli arguments to pass to nuget cli.  
--- @param version string | nil: specifies which version number dotnvim.NugetClient should upgrade to. If nil, dotnvim.NugetClient will default to latest compatable release for for currently installed .Net sdk. If version is less than current version, then dotnvim.NugetClient will try to 'update' to an older version.
--- 
--- NOTE: There is no projects table as parameters. This is because dotnet will error if versions on packages ar not matched... fact check me please.
NugetClient.update_package_to_project = function (package, version)
end

--- @param package table: package is the same shape as what is returned from the NugetClient.get_packages_from_source function. It will use this table to determine what cli arguments to pass to nuget cli when deleting.  
--- @param projects table | nil | {}: a list of csproj paths to add the package to. If nil or an empty table, dotnvim.NugetClient will default the deleting the package from every project in the .sln working dir.
NugetClient.delete_package_to_project = function(package, projects)
end


return NugetClient
