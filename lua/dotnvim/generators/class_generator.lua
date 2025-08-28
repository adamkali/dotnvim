local M = {}

local model = function (name, namespace, public)
    return [[
using System;

namespace ]] .. namespace .. [[ 
{
    ]] .. public ..[[class ]] .. name .. [[ 
    {
    }
}
]]
end


--- @param name string Class name of the generatedFile
--- @param namespace string Namespace of the generated file
--- @param opts table a table to be used when generating the file specifed
--- @return string
M.generate = function (name, namespace, opts) 
    if opts.model then
        return model(name, namespace, opts.public)
    elseif opts.controller then
        return ""
    else
        return ""
    end
end


