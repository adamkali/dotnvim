-- DAP integration hooks for pre-debug task execution
local tasks = require('dotnvim.tasks')
local validation = require('dotnvim.utils.validation')
local ui_helpers = require('dotnvim.utils.ui_helpers')
local config_manager = require('dotnvim.config_manager')
local logger = require('dotnvim.utils.logger')

local M = {}

-- Hook state management
local hook_state = {
    enabled = true,
    pre_debug_tasks = nil, -- User-configured tasks
    last_execution_time = nil,
    last_execution_success = nil,
    block_debug_on_task_failure = true,
    timeout_seconds = 300, -- 5 minutes default timeout
}

-- Initialize DAP hooks
-- @param config table: Hook configuration (optional)
function M.setup(config)
    config = config or {}

    -- Update hook state with user configuration
    hook_state.enabled = config.enabled ~= false
    hook_state.pre_debug_tasks = config.pre_debug_tasks
    hook_state.block_debug_on_task_failure = config.block_debug_on_task_failure ~= false
    hook_state.timeout_seconds = config.timeout_seconds or 300

    -- Only setup hooks if enabled
    if hook_state.enabled then
        M.register_dap_hooks()
        ui_helpers.show_info("DAP task hooks enabled", "dap_hooks")
    end
end

-- Register hooks with nvim-dap
function M.register_dap_hooks()
    local dap_ok, dap = pcall(require, 'dap')
    if not dap_ok then
        ui_helpers.show_warning("nvim-dap not available, task hooks disabled", "dap_hooks")
        return false
    end

    -- Hook before debug launch
    dap.listeners.before.launch.dotnvim_tasks = function(session, body)
        return M.handle_pre_launch(session, body)
    end

    -- Hook before debug attach (optional)
    dap.listeners.before.attach.dotnvim_tasks = function(session, body)
        return M.handle_pre_attach(session, body)
    end
    
    -- Hook after debug session terminates to reset task state
    dap.listeners.after.event_terminated.dotnvim_tasks = function(session, body)
        M.handle_session_terminated(session, body)
    end
    
    -- Hook after debug session disconnects to reset task state
    dap.listeners.after.disconnect.dotnvim_tasks = function(session, body)
        M.handle_session_disconnected(session, body)
    end

    return true
end

-- Handle pre-launch hook
-- @param session table: DAP session
-- @param body table: Launch request body
-- @return boolean: True to continue launch, false to abort
function M.handle_pre_launch(session, body)
    logger.info("dap_hooks", "=== PRE-LAUNCH HOOK CALLED ===")
    logger.debug("dap_hooks", "Hook state: " .. vim.inspect(hook_state))
    logger.debug("dap_hooks", "Session: " .. vim.inspect(session))
    logger.debug("dap_hooks", "Body: " .. vim.inspect(body))
    
    if not hook_state.enabled then
        logger.info("dap_hooks", "Hook disabled, skipping pre-debug tasks")
        return true -- Allow debug to continue when hooks are disabled
    end

    logger.info("dap_hooks", "Starting pre-debug task execution")

    -- Create execution context
    local execution_context = {
        session = session,
        body = body,
        start_time = os.time(),
        timed_out = false,
        completed = false,
        success = false
    }

    logger.debug("dap_hooks", "Execution context created: " .. vim.inspect(execution_context))

    -- Run pre-debug tasks synchronously
    local success = M.run_pre_debug_tasks_sync(execution_context)
    logger.info("dap_hooks", "RETURNED FROM run_pre_debug_tasks_sync: " .. tostring(success))
    logger.info("dap_hooks", "Pre-debug tasks completed with result: " .. tostring(success))

    -- Update state
    local old_time = hook_state.last_execution_time
    local old_success = hook_state.last_execution_success
    hook_state.last_execution_time = os.time()
    hook_state.last_execution_success = success
    
    logger.log_state_change("dap_hooks", "last_execution_time", old_time, hook_state.last_execution_time)
    logger.log_state_change("dap_hooks", "last_execution_success", old_success, hook_state.last_execution_success)

    if not success and hook_state.block_debug_on_task_failure then
        logger.warn("dap_hooks", "Blocking debug session due to task failure")
        return false
    end

    if success then
        logger.info("dap_hooks", "Pre-debug tasks successful, allowing debug session to continue")
    else
        logger.warn("dap_hooks", "Pre-debug tasks failed but allowing debug session to continue")
    end

    logger.info("dap_hooks", "=== PRE-LAUNCH HOOK FINISHED ===")
    return true
end

-- Handle pre-attach hook (similar to pre-launch)
-- @param session table: DAP session
-- @param body table: Attach request body
-- @return boolean: True to continue attach, false to abort
function M.handle_pre_attach(session, body)
    if not hook_state.enabled then
        return true
    end

    -- For attach, we might want different behavior
    -- For now, just run the same pre-debug tasks
    return M.handle_pre_launch(session, body)
end

-- Handle debug session termination
-- @param session table: DAP session
-- @param body table: Termination event body
function M.handle_session_terminated(session, body)
    logger.info("dap_hooks", "=== DEBUG SESSION TERMINATED ===")
    logger.debug("dap_hooks", "Session: " .. vim.inspect(session))
    logger.debug("dap_hooks", "Body: " .. vim.inspect(body))
    logger.debug("dap_hooks", "Hook state before reset: " .. vim.inspect(hook_state))
    
    if not hook_state.enabled then
        logger.info("dap_hooks", "Hook disabled, skipping termination handling")
        return
    end
    
    logger.info("dap_hooks", "Starting task state reset after debug termination")
    
    -- Force clear any running task state to ensure clean state for next debug session
    logger.debug("dap_hooks", "Calling tasks.cancel_execution()")
    local cancelled = tasks.cancel_execution()
    logger.debug("dap_hooks", "tasks.cancel_execution() returned: " .. tostring(cancelled))
    
    -- Force refresh task discovery cache to ensure we pick up any changes
    logger.debug("dap_hooks", "Calling tasks.reload_config()")
    tasks.reload_config()
    logger.debug("dap_hooks", "tasks.reload_config() completed")
    
    -- Reset our internal state
    local old_time = hook_state.last_execution_time
    local old_success = hook_state.last_execution_success
    hook_state.last_execution_time = nil
    hook_state.last_execution_success = nil
    
    logger.log_state_change("dap_hooks", "last_execution_time", old_time, hook_state.last_execution_time)
    logger.log_state_change("dap_hooks", "last_execution_success", old_success, hook_state.last_execution_success)
    
    logger.debug("dap_hooks", "Hook state after reset: " .. vim.inspect(hook_state))
    
    logger.info("dap_hooks", "=== DEBUG TERMINATION HANDLING COMPLETE ===")
end

-- Handle debug session disconnection
-- @param session table: DAP session  
-- @param body table: Disconnect event body
function M.handle_session_disconnected(session, body)
    if not hook_state.enabled then
        return
    end
    
    
    -- Force clear any running task state
    tasks.cancel_execution()
    
    -- Force refresh task discovery cache to ensure we pick up any changes
    tasks.reload_config()
    
    -- Reset our internal state
    hook_state.last_execution_time = nil
    hook_state.last_execution_success = nil
    
end

-- Run pre-debug tasks synchronously
-- @param context table: Execution context
-- @return boolean: True if tasks completed successfully
function M.run_pre_debug_tasks_sync(context)
    logger.info("dap_hooks", ">>> STARTING SYNC TASK EXECUTION <<<")
    
    -- Initialize state variables
    local completed = false
    local success = false
    local error_message = nil
    logger.info("dap_hooks", "INITIAL STATE: completed=" .. tostring(completed) .. ", success=" .. tostring(success))

    -- Determine which tasks to run
    local task_options = {
        pre_debug_tasks = hook_state.pre_debug_tasks
    }
    logger.debug("dap_hooks", "Task options: " .. vim.inspect(task_options))

    -- Force refresh task discovery to ensure we have latest task configuration
    logger.debug("dap_hooks", "Calling tasks.reload_config() to refresh cache")
    tasks.reload_config()
    logger.debug("dap_hooks", "tasks.reload_config() completed")

    -- Reset our hook state to ensure fresh start
    local old_time = hook_state.last_execution_time
    local old_success = hook_state.last_execution_success
    hook_state.last_execution_time = nil
    hook_state.last_execution_success = nil
    logger.log_state_change("dap_hooks", "last_execution_time", old_time, nil)
    logger.log_state_change("dap_hooks", "last_execution_success", old_success, nil)
    
    logger.debug("dap_hooks", "Calling tasks.run_pre_debug_tasks() with callback")
    local task_started = tasks.run_pre_debug_tasks(task_options, function(task_success, message)
        local message_str = message
        if type(message) == "table" then
            message_str = vim.inspect(message)
        elseif message then
            message_str = tostring(message)
        else
            message_str = "no message provided"
        end
        logger.info("dap_hooks", "CALLBACK RECEIVED: success=" .. tostring(task_success) .. ", message=" .. message_str)
        logger.debug("dap_hooks", "CALLBACK TRIGGERED - success: " .. tostring(task_success) .. ", message: " .. message_str)
        
        -- Ensure we don't accidentally override a successful result
        if task_success == true then
            logger.info("dap_hooks", "Tasks completed SUCCESSFULLY - setting completed=true, success=true")
        else
            logger.warn("dap_hooks", "Tasks completed with FAILURE - setting completed=true, success=false")
        end
        
        completed = true
        success = task_success
        error_message = message_str
        
        logger.info("dap_hooks", "CALLBACK COMPLETE: completed=" .. tostring(completed) .. ", success=" .. tostring(success))
    end)
    
    logger.debug("dap_hooks", "tasks.run_pre_debug_tasks() returned: " .. tostring(task_started))
    
    -- Handle case when no tasks were started
    if not task_started then
        logger.warn("dap_hooks", "No pre-debug tasks to run - task_started = false")
        return true -- No tasks to run, allow debug to continue
    end
    
    logger.info("dap_hooks", "Tasks started, beginning wait loop")

    -- Wait for completion with timeout using vim.wait with condition function
    local timeout_ms = hook_state.timeout_seconds * 1000
    logger.debug("dap_hooks", "Starting vim.wait with timeout: " .. timeout_ms .. "ms")
    local wait_start_time = os.time()

    
    -- Force UI refresh before blocking
    vim.schedule(function()
        ui_helpers.show_info("Blocking debug session until pre-debug tasks complete...", "dap_hooks")
    end)
    vim.cmd('redraw')
    
    local wait_result = vim.wait(timeout_ms, function()
        logger.trace("dap_hooks", "Wait condition check - completed: " .. tostring(completed))
        return completed
    end, 100) -- Check every 100ms for better performance
    
    local wait_duration = os.time() - wait_start_time
    logger.debug("dap_hooks", "vim.wait completed after " .. wait_duration .. "s, result: " .. tostring(wait_result))
    
    -- Final safety check only after wait completes
    if not wait_result and not completed then
        -- Check if tasks are still running when we timed out
        local task_running = tasks.is_execution_running and tasks.is_execution_running() or false
        if not task_running then
            logger.warn("dap_hooks", "Tasks appear to have completed but callback was not triggered")
            -- Don't assume success or failure - let the timeout handling take over
        end
    end

    if not wait_result then
        -- Timeout occurred
        logger.error("dap_hooks", "TIMEOUT: Pre-debug tasks timed out after " .. hook_state.timeout_seconds .. "s")
        context.timed_out = true

        -- Cancel running tasks
        logger.debug("dap_hooks", "Cancelling tasks due to timeout")
        tasks.cancel_execution()
        return false
    end

    -- Double-check that tasks actually completed before proceeding
    if not completed then
        logger.error("dap_hooks", "CRITICAL: vim.wait returned true but completed=false - this should not happen")
        return false
    end
    
    logger.debug("dap_hooks", "SUCCESS STATE CHECK: success=" .. tostring(success) .. ", completed=" .. tostring(completed))
    
    logger.info("dap_hooks", "Tasks completed successfully within timeout")
    context.completed = true
    context.success = success
    
    logger.debug("dap_hooks", "Final context: " .. vim.inspect(context))
    logger.debug("dap_hooks", "Final success value being returned: " .. tostring(success))

    if not success and error_message then
        local error_str = type(error_message) == "table" and vim.inspect(error_message) or tostring(error_message)
        logger.error("dap_hooks", "Task execution failed: " .. error_str)
    else
        logger.info("dap_hooks", "Task execution completed successfully")
    end

    logger.info("dap_hooks", "<<< SYNC TASK EXECUTION FINISHED - Result: " .. tostring(success) .. " >>>")
    return success
end

-- Configure pre-debug tasks
-- @param task_list table: Array of task names to run before debugging
function M.set_pre_debug_tasks(task_list)
    validation.assert_table(task_list, "task_list", true)

    hook_state.pre_debug_tasks = task_list

end

-- Enable or disable hooks
-- @param enabled boolean: True to enable hooks
function M.set_enabled(enabled)
    validation.assert_boolean(enabled, "enabled", false)

    hook_state.enabled = enabled

    if enabled then
        M.register_dap_hooks()
    else
        ui_helpers.show_info("DAP task hooks disabled", "dap_hooks")
    end
end

-- Set whether to block debugging on task failure
-- @param block boolean: True to block debugging if tasks fail
function M.set_block_on_failure(block)
    validation.assert_boolean(block, "block", false)

    hook_state.block_debug_on_task_failure = block

    if block then
        ui_helpers.show_info("Debug sessions will be blocked if pre-debug tasks fail", "dap_hooks")
    else
        ui_helpers.show_info("Debug sessions will continue even if pre-debug tasks fail", "dap_hooks")
    end
end

-- Set task execution timeout
-- @param timeout_seconds number: Timeout in seconds
function M.set_timeout(timeout_seconds)
    validation.assert_number(timeout_seconds, "timeout_seconds", false)

    if timeout_seconds <= 0 then
        error("Timeout must be greater than 0")
    end

    hook_state.timeout_seconds = timeout_seconds
end

-- Get current hook configuration
-- @return table: Current hook configuration
function M.get_config()
    return vim.deepcopy(hook_state)
end

-- Get hook status
-- @return table: Status information
function M.get_status()
    local dap_available = pcall(require, 'dap')

    return {
        enabled = hook_state.enabled,
        dap_available = dap_available,
        pre_debug_tasks = hook_state.pre_debug_tasks,
        block_on_failure = hook_state.block_debug_on_task_failure,
        timeout_seconds = hook_state.timeout_seconds,
        last_execution_time = hook_state.last_execution_time,
        last_execution_success = hook_state.last_execution_success,
        has_task_config = tasks.has_task_support()
    }
end

-- Test pre-debug task execution (without starting debug session)
-- @param callback function: Completion callback (optional)
-- @return boolean: True if test started successfully
function M.test_pre_debug_tasks(callback)

    local task_options = {
        pre_debug_tasks = hook_state.pre_debug_tasks
    }

    return tasks.run_pre_debug_tasks(task_options, function(success, message)
        if success then
        else
            local error_str = message and (type(message) == "table" and vim.inspect(message) or tostring(message)) or "unknown error"
        end

        if callback then
            callback(success, message)
        end
    end)
end

-- Clear hook registration (for cleanup)
function M.unregister_dap_hooks()
    local dap_ok, dap = pcall(require, 'dap')
    if dap_ok then
        dap.listeners.before.launch.dotnvim_tasks = nil
        dap.listeners.before.attach.dotnvim_tasks = nil
        dap.listeners.after.event_terminated.dotnvim_tasks = nil
        dap.listeners.after.disconnect.dotnvim_tasks = nil
    end
end

-- Reset hook state to defaults
function M.reset()
    hook_state = {
        enabled = true,
        pre_debug_tasks = nil,
        last_execution_time = nil,
        last_execution_success = nil,
        block_debug_on_task_failure = true,
        timeout_seconds = 300,
    }

end

-- Integration helper for main plugin setup
-- @param dap_config table: DAP configuration from main config
function M.integrate_with_dap_config(dap_config)
    if not dap_config then
        return
    end

    local hook_config = {}

    -- Extract task-related configuration
    if dap_config.pre_debug_tasks then
        hook_config.pre_debug_tasks = dap_config.pre_debug_tasks
    end

    if dap_config.block_debug_on_task_failure ~= nil then
        hook_config.block_debug_on_task_failure = dap_config.block_debug_on_task_failure
    end

    if dap_config.task_timeout then
        hook_config.timeout_seconds = dap_config.task_timeout
    end

    if dap_config.enable_task_hooks ~= nil then
        hook_config.enabled = dap_config.enable_task_hooks
    end

    M.setup(hook_config)
end

return M

