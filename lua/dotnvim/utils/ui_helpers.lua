-- UI helper utilities for project selection and user interaction
local telescope_utils = require('dotnvim.utils.telescope_utils')
local config_manager = require('dotnvim.config_manager')
local validation = require('dotnvim.utils.validation')

local M = {}

-- Select a .csproj file using available UI (Telescope or vim.ui.select)
-- @param callback function: Function to call with selected file path
-- @param options table: Optional configuration {prompt: string, allow_cancel: boolean}
function M.select_csproj(callback, options)
  validation.assert_function(callback, "callback", false)
  options = options or {}
  
  local project_scanner = require('dotnvim.utils.project_scanner')
  local selections = project_scanner.get_all_csproj()
  
  if #selections == 0 then
    vim.notify("No .csproj files found in current directory tree", vim.log.levels.WARN)
    return
  end
  
  -- Try Telescope first if available and not disabled
  local ui_config = config_manager.get_ui_config()
  if pcall(require, 'telescope') and not ui_config.no_pretty_uis then
    telescope_utils.telescope_select_csproj(selections, callback)
    return
  end
  
  -- Fallback to vim.ui.select
  local items = {}
  for _, file in ipairs(selections) do
    table.insert(items, file.value)
  end
  
  local prompt = options.prompt or 'Select a .csproj file:'
  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item)
      -- Show relative path from current directory for better readability
      local cwd = vim.fn.getcwd()
      local relative = vim.fn.fnamemodify(item, ':.' )
      return relative
    end
  }, function(choice)
    if choice then
      callback(choice)
    elseif not options.allow_cancel then
      vim.notify("No file selected", vim.log.levels.INFO)
    end
  end)
end

-- Display a simple text input prompt
-- @param prompt string: Prompt message
-- @param callback function: Function to call with input result
-- @param options table: Optional {default: string, completion: string}
function M.input_prompt(prompt, callback, options)
  validation.assert_string(prompt, "prompt", false)
  validation.assert_function(callback, "callback", false)
  options = options or {}
  
  vim.ui.input({
    prompt = prompt,
    default = options.default,
    completion = options.completion
  }, function(input)
    if input and input ~= "" then
      callback(input)
    else
      vim.notify("Input cancelled or empty", vim.log.levels.INFO)
    end
  end)
end

-- Show a confirmation dialog
-- @param message string: Message to display
-- @param callback function: Function to call with boolean result
-- @param options table: Optional {yes_text: string, no_text: string}
function M.confirm(message, callback, options)
  validation.assert_string(message, "message", false)
  validation.assert_function(callback, "callback", false)
  options = options or {}
  
  local yes_text = options.yes_text or "Yes"
  local no_text = options.no_text or "No"
  
  vim.ui.select({yes_text, no_text}, {
    prompt = message,
    format_item = function(item)
      return item
    end
  }, function(choice)
    callback(choice == yes_text)
  end)
end

-- Display error message with consistent formatting
-- @param message string: Error message
-- @param context string: Optional context for the error
function M.show_error(message, context)
  validation.assert_string(message, "message", false)
  
  local full_message = message
  if context then
    validation.assert_string(context, "context", false)
    full_message = string.format("[%s] %s", context, message)
  end
  
  vim.notify(full_message, vim.log.levels.ERROR)
end

-- Display warning message
-- @param message string: Warning message
-- @param context string: Optional context for the warning
function M.show_warning(message, context)
  validation.assert_string(message, "message", false)
  
  local full_message = message
  if context then
    validation.assert_string(context, "context", false)
    full_message = string.format("[%s] %s", context, message)
  end
  
  vim.notify(full_message, vim.log.levels.WARN)
end

-- Display info message
-- @param message string: Info message
-- @param context string: Optional context for the message
function M.show_info(message, context)
  validation.assert_string(message, "message", false)
  
  local full_message = message
  if context then
    validation.assert_string(context, "context", false)
    full_message = string.format("[%s] %s", context, message)
  end
  
  vim.notify(full_message, vim.log.levels.INFO)
end

-- Display success message
-- @param message string: Success message
-- @param context string: Optional context for the message
function M.show_success(message, context)
  validation.assert_string(message, "message", false)
  
  local full_message = message
  if context then
    validation.assert_string(context, "context", false)
    full_message = string.format("[%s] %s", context, message)
  end
  
  -- Use INFO level for success messages since there's no SUCCESS level
  vim.notify("✓ " .. full_message, vim.log.levels.INFO)
end

-- Create a progress indicator (simple implementation)
-- @param title string: Progress title
-- @return table: Progress object with update and finish methods
function M.create_progress(title)
  validation.assert_string(title, "title", false)
  
  local progress = {
    title = title,
    current = 0,
    total = 100
  }
  
  function progress:update(current, message)
    if validation.is_number(current) then
      self.current = current
    end
    
    local msg = string.format("[%s] %d%% %s", 
      self.title, 
      math.floor((self.current / self.total) * 100),
      message or ""
    )
    vim.notify(msg, vim.log.levels.INFO)
  end
  
  function progress:finish(success, final_message)
    local status = success and "✓" or "✗"
    local level = success and vim.log.levels.INFO or vim.log.levels.ERROR
    local msg = string.format("%s [%s] %s", status, self.title, final_message or "Complete")
    vim.notify(msg, level)
  end
  
  -- Initial message
  vim.notify(string.format("[%s] Starting...", title), vim.log.levels.INFO)
  
  return progress
end

-- Show a list selection with custom formatting
-- @param items table: Array of items to select from
-- @param options table: {prompt: string, format_item: function}
-- @param callback function: Function to call with selected item
function M.select_from_list(items, options, callback)
  validation.assert_table(items, "items", false)
  validation.assert_table(options, "options", false)
  validation.assert_function(callback, "callback", false)
  
  if #items == 0 then
    M.show_warning("No items available for selection")
    return
  end
  
  vim.ui.select(items, {
    prompt = options.prompt or "Select an item:",
    format_item = options.format_item or function(item)
      return tostring(item)
    end
  }, function(choice)
    if choice then
      callback(choice)
    else
      M.show_info("No item selected")
    end
  end)
end

return M