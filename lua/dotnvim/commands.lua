local bootstrappers = require'dotnvim.bootstrappers'
local telescope_utils = require'dotnvim.utils.telescope_utils'
--local Job = require('plenary.job')

local M = {}

M.default_params = {
    bootstrap_verbose = false,
    bootstrap_namespace = nil
}

function M.command_bootstrap()
    local selection = { }
    if pcall(require, 'telescope') then
         selection = telescope_utils.telescope_select_bootstrapper(bootstrappers.bootstrappers)
    end
    if selection == nil then
        return
    end
    local func = ""
    for _, value in ipairs(bootstrappers.bootstrappers) do
        if value.search == selection.search then
            func =  value.func
        end
    end
    return M[func]("Test", nil)
end

return M
