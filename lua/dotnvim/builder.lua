local dotnvim_utils = require('dotnvim.utils')
local Job = require 'plenary.job'

local M = {}

function start_output_buffer(log_name)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')  -- Buffer does not have a file associated
    vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'hide')  -- Hide buffer rather than delete it when abandoned
    vim.api.nvim_buf_set_option(bufnr, 'swapfile', false)    -- No swap file for this buffer
    vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)   -- Allow modification
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'log')    -- Set the filetype to 'log' for syntax highlighting
    local date_formatted = os.date("%Y-%m-%d-%H-%M-%S")
    vim.api.nvim_buf_set_name(bufnr, date_formatted .. log_name)
    vim.api.nvim_set_current_buf(bufnr)
    return bufnr
end

-- HACK: The most disgusting hack i could think of
-- use pgrep and then concat all pids return at the same
-- time so the dotnet sanity checks dont fuck everything up
-- and restart the process leading to 
M.kill_dotnet_process = function()
    if not Dotnvim.last_used_csproj then
        print("No .csproj file was used recently.")
        return
    end

    -- Extract the project name from the .csproj path
    local project_name = Dotnvim.last_used_csproj:match("([^/]+)%.csproj$")
    if not project_name then
        print("Unable to extract project name from the .csproj path.")
        return
    end

    -- Use pgrep to find the PID of the running process
    Job:new({
        command = 'pgrep',
        args = { '-f', project_name },
        on_exit = function(j, return_val)
            if return_val == 0 then
                local pids = j:result()
                if #pids > 0 then
                    local kill_cmd = "kill -9 " .. table.concat(pids, " ")
                    local status = os.execute(kill_cmd)
                    if status == 0 then
                        print("Processes killed successfully.")
                    else
                        print("Failed to kill processes.")
                    end
                else
                    print("No valid PIDs found.")
                end
            else
                print("No process found for project: " .. project_name)
            end
        end,
    }):start()
end


function M.dotnet_build(csproj_path)
    -- Ensure the provided path is a .csproj file
    if not csproj_path or not csproj_path:match("%.csproj$") then
        print("Invalid .csproj path: " .. (csproj_path or "nil"))
        return
    end

    -- Start the log buffer 
    local bufnr = start_output_buffer("-build.log")

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

function M.start_dotnet_run(csproj_path)
    -- Ensure the provided path is a .csproj file
    if not csproj_path or not csproj_path:match("%.csproj$") then
        if not Dotnvim.last_used_csproj or not Dotnvim.last_used_csproj:match("%.csproj$") then
            print("Invalid .csproj path: " .. (csproj_path or "nil"))
            print("Invalid Dotnvim.last_used_csproj path: " .. (Dotnvim.last_used_csproj or "nil"))
            return
        end
    end

    local dotnet_args = { 'watch', '--project', csproj_path }
    if DotnvimConfig.builders.https_launch_setting_always then
        vim.tbl_extend(dotnet_args, { "-lp",  "https" })
    end
    vim.print(dotnet_args)

    local bufnr = start_output_buffer("-watch.log")

    -- Start the job to run dotnet build
    Dotnvim.running_watch = Job:new({
        command = 'dotnet',
        args = dotnet_args,
        on_stdout = vim.schedule_wrap(function(_, line)
            dotnvim_utils.append_to_buffer(bufnr, { line })
        end),
        on_stderr = vim.schedule_wrap(function(_, line)
            dotnvim_utils.append_to_buffer(bufnr, { line })
        end),
    })
    Dotnvim.last_used_csproj = csproj_path
    Dotnvim.running_watch:start()
end

function M.restart_dotnet_run()
    M.kill_dotnet_process()
    M.start_dotnet_run(Dotnvim.last_used_csproj)
end

return M
