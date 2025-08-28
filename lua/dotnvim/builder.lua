local dotnvim_utils = require('dotnvim.utils')
local Job = require 'plenary.job'
local config_manager = require('dotnvim.config_manager')
local validation = require('dotnvim.utils.validation')
local buffer_helpers = require('dotnvim.utils.buffer_helpers')
local ui_helpers = require('dotnvim.utils.ui_helpers')

local M = {}

function start_output_buffer(log_name)
    validation.assert_string(log_name, "log_name", false)
    
    local bufnr = buffer_helpers.create_log_buffer(log_name)
    if not bufnr then
        ui_helpers.show_error("Failed to create log buffer", "start_output_buffer")
        return nil
    end
    return bufnr
end

-- HACK: The most disgusting hack i could think of
-- use pgrep and then concat all pids return at the same
-- time so the dotnet sanity checks dont fuck everything up
-- and restart the process leading to 
M.kill_dotnet_process = function()
    local last_csproj = config_manager.get_last_used_csproj()
    if not last_csproj then
        ui_helpers.show_warning("No .csproj file was used recently", "kill_dotnet_process")
        return false
    end

    -- Extract the project name from the .csproj path
    local project_name = last_csproj:match("([^/]+)%.csproj$")
    if not project_name then
        ui_helpers.show_error("Unable to extract project name from the .csproj path", "kill_dotnet_process")
        return false
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
                        ui_helpers.show_success("Processes killed successfully", "kill_dotnet_process")
                    else
                        ui_helpers.show_error("Failed to kill processes", "kill_dotnet_process")
                    end
                else
                    ui_helpers.show_warning("No valid PIDs found", "kill_dotnet_process")
                end
            else
                ui_helpers.show_info("No process found for project: " .. project_name, "kill_dotnet_process")
            end
        end,
    }):start()
    
    return true
end


function M.dotnet_build(csproj_path)
    local valid, err = validation.validate_csproj_path(csproj_path, "csproj_path")
    if not valid then
        ui_helpers.show_error(err, "dotnet_build")
        return false
    end

    -- Start the log buffer 
    local bufnr = start_output_buffer("build.log")
    if not bufnr then
        return false
    end

    -- Start the job to run dotnet build
    local job = Job:new({
        command = 'dotnet',
        args = { 'build', csproj_path },
        on_stdout = vim.schedule_wrap(function(_, line)
            buffer_helpers.append_to_buffer(bufnr, { line })
        end),
        on_stderr = vim.schedule_wrap(function(_, line)
            buffer_helpers.append_to_buffer(bufnr, { line })
        end),
        on_exit = function(j, return_val)
            vim.schedule(function()
                config_manager.set_last_used_csproj(csproj_path)
                if return_val == 0 then
                    ui_helpers.show_success("Build completed successfully", "dotnet_build")
                else
                    ui_helpers.show_error("Build failed with exit code " .. return_val, "dotnet_build")
                end
            end)
        end,
    })
    
    job:start()
    ui_helpers.show_info("Starting build for " .. vim.fn.fnamemodify(csproj_path, ":t"), "dotnet_build")
    return true
end

function M.dotnet_watch(csproj_path)
    local valid, err = validation.validate_csproj_path(csproj_path, "csproj_path")
    if not valid then
        ui_helpers.show_error(err, "dotnet_watch")
        return false
    end

    local dotnet_args = { 'watch', '--project', csproj_path }
    if config_manager.get_builders_config().https_launch_setting_always then
        vim.tbl_extend(dotnet_args, { "-lp",  "https" })
    end
    vim.print(dotnet_args)

    local bufnr = start_output_buffer("watch.log")
    if not bufnr then
        return false
    end

    -- Start the job to run dotnet watch
    local watch_job = Job:new({
        command = 'dotnet',
        args = dotnet_args,
        on_stdout = vim.schedule_wrap(function(_, line)
            buffer_helpers.append_to_buffer(bufnr, { line })
        end),
        on_stderr = vim.schedule_wrap(function(_, line)
            buffer_helpers.append_to_buffer(bufnr, { line })
        end),
    })
    config_manager.set_last_used_csproj(csproj_path)
    config_manager.set_running_watch(watch_job)
    watch_job:start()
    
    ui_helpers.show_info("Starting watch for " .. vim.fn.fnamemodify(csproj_path, ":t"), "dotnet_watch")
    return true
end

function M.restart_dotnet_watch()
    local last_csproj = config_manager.get_last_used_csproj()
    if not last_csproj then
        ui_helpers.show_error("No previous .csproj file to restart", "restart_dotnet_watch")
        return false
    end
    
    M.kill_dotnet_process()
    return M.dotnet_watch(last_csproj)
end

return M
