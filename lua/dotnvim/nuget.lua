local Job = require('plenary.job')
local curl = require('plenary.curl')
local NugetClient = {}

NugetClient.authenticate = function()
    for _, authenticator in ipairs(vim.g.DotnvimConfig.nuget.authenticators) do
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


local function nuget_service_index(source)
    local search_service_url = nil
    local response = curl.get(source)
    if response.staus ~= nil and response.staus ~= 200 then
        error("Failed")
        return
    end

    local json_response = vim.fn.json_decode(response.body)["resources"]

    for _, resource in ipairs(json_response) do
        if resource["@type"]:match("SearchQueryService") then
            search_service_url = resource["@id"]
            break
        end
    end

    if not search_service_url then
        error("SearchQueryService URL not found")
    end
    return search_service_url
end

NugetClient.search_package_by_source = function(query, source, param_config)
    if source == nil then
        source = "https://api.nuget.org/v3/index.json"
    end
    local search_service_url = nuget_service_index(source)
    print(search_service_url)

    local params = vim.tbl_deep_extend("force", { q = query }, param_config)
    local response = curl.get(search_service_url, { query = params })
    local status = response["status"]

    ---- Make the HTTP GET request
    --
    if status ~= 200 then
        error("Failed to search for packages: " .. string.format(status))
    end

    -- Parse and return the JSON response
    local json_response = vim.json.decode(response["body"])
    json_response = json_response["data"]
    return json_response
end

return NugetClient
