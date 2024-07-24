local M = {}

function M.check()
    require'dotnvim.health'.check()
end

function M.bootstrap()
    local commands = require'dotnvim.commands'

    commands.command_bootstrap()
end

function M.setup()
end

return M


