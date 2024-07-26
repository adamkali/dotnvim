local dotnvim_utils = require('dotnvim.utils')
local Job = require 'plenary.job'

local M = {}

function M.dotnet_build(csproj_path)
    -- Ensure the provided path is a .csproj file
    if not csproj_path or not csproj_path:match("%.csproj$") then
        print("Invalid .csproj path: " .. (csproj_path or "nil"))
        return
    end

    -- Variables to store the output
    local bufnr = vim.api.nvim_create_buf(false, true)     -- Create a new empty buffer
    vim.api.nvim_buf_set_option(bufnr, 'modifiable', true) -- Make the buffer read-only
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'log')  -- Set the filetype to 'log' for syntax highlighting
    vim.cmd('vsplit')                                      -- Open in a vertical split
    vim.api.nvim_set_current_buf(bufnr)

    -- Start the job to run dotnet build
    local job = Job:new({
        command = 'dotnet',
        args = { 'build', csproj_path },
        on_stdout = vim.schedule_wrap(function(_, line)
            dotnvim_utils.append_to_buffer(bufnr, { line })
        end),
        on_stderr = vim.schedule_wrap(function(_, line)
            dotnvim_utils.append_to_buffer(bufnr, { line })
        end),
        on_exit = function(j, return_val)
            vim.schedule(function()
                Dotnvim.last_used_csproj = csproj_path
            end)
        end,
    })

    job:start()
end

return M
