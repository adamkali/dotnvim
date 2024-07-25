local dotnvim_utils = require('dotnvim.utils')
local Job = require 'plenary.job'
local M = {}


-- Function to build a .csproj file using dotnet build and display output in a new buffer
function M.dotnet_build(csproj_path)
    -- Ensure the provided path is a .csproj file
    if not csproj_path or not csproj_path:match("%.csproj$") then
        print("Invalid .csproj path: " .. (csproj_path or "nil"))
        return
    end

    -- Variables to store the output
    vim.g.dotnvim.build_output_lines = {}
    vim.g.dotnvim.build_error_lines = {}

    -- Start the job to run dotnet build
    Job:new({
        command = 'dotnet',
        args = { 'build', csproj_path },
        on_stdout = function(_, line)
            print(line)
            table.insert(vim.g.dotnvim.build_output_lines, line)
        end,
        on_stderr = function(_, line)
            print(line)
            table.insert(vim.g.dotnvim.build_error_lines, line)
        end,
        on_exit = function(j, return_val)
            -- Create a new buffer and display the output
            -- TODO: get nui or noice
            vim.schedule(function()
                local bufnr = vim.api.nvim_create_buf(false, true)  -- Create a new empty buffer
                print(return_val)
                if return_val == 0 then
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.g.dotnvim.build_output_lines)
                else
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.g.dotnvim.build_error_lines)
                end

                -- Open the new buffer in a new split
                vim.api.nvim_set_current_buf(bufnr)
                vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)  -- Make the buffer read-only
                vim.api.nvim_buf_set_option(bufnr, 'filetype', 'log')    -- Set the filetype to 'log' for syntax highlighting
            end)
        end,
    }):start()
end



return M
