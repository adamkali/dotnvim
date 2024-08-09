local OSharpRequest = {
    client   = nil,
    title    = "NOT INITIATED",
    builtin  = "null",
    osharpn  = "null",
    osharpr  = function(err, result, context, config) end,
    callback = function(locations, lsp_client) end,
    telscope = function(locations, lsp_client, config) end
}

function get_lsp_client()
    local clients = nil;
    if vim.lsp.get_clients ~= nil then
        clients = vim.lsp.get_clients({ buffer = 0 })
    else
        clients = vim.lsp.buf_get_clients(0)
    end

    for _, client in pairs(clients) do
        if client.name == "omnisharp" or client.name == "omnisharp_mono" then
            return client
        end
    end
end

function OSharpRequest:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function OSharpRequest:osharp_handler(err, result, ctx, config)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function OSharpRequest:cmd()
    local client = get_lsp_client
    if client then
        client.request(
            self.osharpn,
            function ()
               nil
            end,
            function (err, result, ctx, config)
                self:osharp_handler(err, result, ctx, config)
            end
        )
    end
end


return OSharpRequest
