-- Check if the minimum required Neovim version is met
if vim.fn.has("nvim-0.9.0") ~= 1 then
    vim.notify("dotnvim requires at least nvim-0.9.0.", vim.log.levels.ERROR)
    return
end

-- Configuration is now managed by config_manager.lua

local log_file_path = vim.fn.stdpath('data') .. '/dotnvim.log'

-- Create a user command to view the log
vim.api.nvim_create_user_command('DotnvimLog', function()
    vim.cmd("edit " .. log_file_path)
end, { nargs = 0 })

-- NuGet authentication command
vim.api.nvim_create_user_command('DotnvimNugetAuth', function()
    require('dotnvim').nuget_auth()
end, { nargs = 0 })

-- Task system commands
vim.api.nvim_create_user_command('DotnvimTaskRun', function(opts)
    local task_name = opts.args
    if task_name == "" then
        local available_tasks = require('dotnvim').get_available_tasks()
        if #available_tasks > 0 then
            vim.ui.select(available_tasks, {
                prompt = 'Select task to run:',
            }, function(choice)
                if choice then
                    require('dotnvim').run_task(choice)
                end
            end)
        else
            vim.notify("No tasks available", vim.log.levels.WARN)
        end
    else
        require('dotnvim').run_task(task_name)
    end
end, { 
    nargs = '?',
    desc = 'Run a task',
    complete = function()
        local tasks = require('dotnvim').get_available_tasks()
        return tasks or {}
    end
})

vim.api.nvim_create_user_command('DotnvimTaskCancel', function()
    local cancelled = require('dotnvim').cancel_tasks()
    if cancelled then
        vim.notify("Task execution cancelled", vim.log.levels.INFO)
    else
        vim.notify("No tasks running", vim.log.levels.INFO)
    end
end, { nargs = 0 })

vim.api.nvim_create_user_command('DotnvimTaskStatus', function()
    local status = require('dotnvim').task_status()
    
    local lines = {"=== Task System Status ==="}
    table.insert(lines, "Has config: " .. tostring(status.has_config))
    
    if status.config_reason then
        table.insert(lines, "Config: " .. status.config_reason)
    end
    
    table.insert(lines, "Running: " .. tostring(status.running))
    
    if #status.available_tasks > 0 then
        table.insert(lines, "Available tasks: " .. table.concat(status.available_tasks, ", "))
    end
    
    if status.execution_history_count > 0 then
        table.insert(lines, "Execution history: " .. status.execution_history_count .. " entries")
    end
    
    if status.current_execution then
        table.insert(lines, "Currently running: " .. table.concat(status.current_execution.active_tasks, ", "))
    end
    
    -- Create a temporary buffer to display status
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].filetype = 'text'
    vim.api.nvim_buf_set_name(buf, "DotnvimTaskStatus")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_current_buf(buf)
end, { nargs = 0 })

vim.api.nvim_create_user_command('DotnvimTaskInit', function(opts)
    local format = opts.args ~= "" and opts.args or "json"
    local success, message = require('dotnvim').create_task_config(format)
    
    if success then
        vim.notify("Task configuration created: " .. message, vim.log.levels.INFO)
    else
        vim.notify("Failed to create task configuration: " .. message, vim.log.levels.ERROR)
    end
end, {
    nargs = '?',
    desc = 'Initialize task configuration',
    complete = function()
        return {"json", "yaml", "toml"}
    end
})

