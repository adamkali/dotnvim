-- Buffer manipulation utilities
local validation = require('dotnvim.utils.validation')

local M = {}

-- Append lines to a buffer with validation
-- @param bufnr number: Buffer number
-- @param lines table: Array of lines to append
-- @return boolean: Success status
function M.append_to_buffer(bufnr, lines)
  local valid, err = validation.validate_buffer(bufnr, "buffer number")
  if not valid then
    vim.notify(validation.validation_error(err, "append_to_buffer"), vim.log.levels.ERROR)
    return false
  end
  
  local lines_valid, lines_err = validation.validate_table(lines, "lines", false)
  if not lines_valid then
    vim.notify(validation.validation_error(lines_err, "append_to_buffer"), vim.log.levels.ERROR)
    return false
  end
  
  -- Validate that lines is an array of strings
  for i, line in ipairs(lines) do
    if not validation.is_string(line) then
      vim.notify(validation.validation_error("lines[" .. i .. "] must be a string, got " .. type(line), "append_to_buffer"), vim.log.levels.ERROR)
      return false
    end
  end
  
  local ok, line_count = pcall(vim.api.nvim_buf_line_count, bufnr)
  if not ok then
    vim.notify(validation.validation_error("Failed to get buffer line count: " .. line_count, "append_to_buffer"), vim.log.levels.ERROR)
    return false
  end
  
  -- Insert lines at the end of the buffer
  ok, err = pcall(vim.api.nvim_buf_set_lines, bufnr, line_count, line_count, false, lines)
  if not ok then
    vim.notify(validation.validation_error("Failed to append lines to buffer: " .. err, "append_to_buffer"), vim.log.levels.ERROR)
    return false
  end
  
  -- Auto-scroll to end if buffer is visible
  M.scroll_to_end(bufnr)
  
  return true
end

-- Scroll buffer to end if it's visible in any window
-- @param bufnr number: Buffer number
function M.scroll_to_end(bufnr)
  local valid, err = validation.validate_buffer(bufnr, "buffer number")
  if not valid then
    return
  end
  
  local windows = vim.fn.win_findbuf(bufnr)
  if #windows > 0 then
    local win = windows[1]
    
    -- Move cursor to the end of the buffer safely
    local ok, last_line = pcall(vim.api.nvim_buf_line_count, bufnr)
    if ok and last_line > 0 then
      pcall(vim.api.nvim_win_set_cursor, win, { last_line, 0 })
    end
  end
end

-- Create a new scratch buffer with specified options
-- @param name string: Buffer name
-- @param options table: Buffer options {filetype: string, modifiable: boolean, buftype: string}
-- @return number|nil: Buffer number or nil on error
function M.create_scratch_buffer(name, options)
  local name_valid, name_err = validation.validate_non_empty_string(name, "buffer name", false)
  if not name_valid then
    vim.notify(validation.validation_error(name_err, "create_scratch_buffer"), vim.log.levels.ERROR)
    return nil
  end
  
  options = options or {}
  
  local ok, bufnr = pcall(vim.api.nvim_create_buf, false, true)
  if not ok then
    vim.notify(validation.validation_error("Failed to create buffer: " .. bufnr, "create_scratch_buffer"), vim.log.levels.ERROR)
    return nil
  end
  
  -- Set buffer name
  local timestamp = os.date("%Y-%m-%d-%H-%M-%S")
  local full_name = timestamp .. "-" .. name
  
  ok, err = pcall(vim.api.nvim_buf_set_name, bufnr, full_name)
  if not ok then
    vim.notify(validation.validation_error("Failed to set buffer name: " .. err, "create_scratch_buffer"), vim.log.levels.WARN)
  end
  
  -- Set buffer options
  local buffer_options = {
    buftype = options.buftype or 'nofile',
    bufhidden = options.bufhidden or 'hide',
    swapfile = options.swapfile or false,
    modifiable = options.modifiable or true,
    filetype = options.filetype or 'text'
  }
  
  for opt, value in pairs(buffer_options) do
    vim.bo[bufnr][opt] = value
  end
  
  return bufnr
end

-- Create a log buffer in a split window based on configuration
-- @param log_name string: Name of the log (e.g., "build", "watch")
-- @param split_config table: Split configuration {mode, size, focus}
-- @return number|nil: Buffer number or nil on error
function M.create_log_buffer_split(log_name, split_config)
  local valid, err = validation.validate_non_empty_string(log_name, "log_name", false)
  if not valid then
    vim.notify(validation.validation_error(err, "create_log_buffer_split"), vim.log.levels.ERROR)
    return nil
  end
  
  split_config = split_config or {}
  local mode = split_config.mode or "new_buffer"
  local size = split_config.size
  local focus = split_config.focus ~= false -- Default to true if not specified
  
  -- Create the buffer first
  local bufnr = M.create_scratch_buffer(log_name .. ".log", {
    filetype = 'log',
    modifiable = true,
    buftype = 'nofile',
    bufhidden = 'hide'
  })
  
  if not bufnr then
    return nil
  end
  
  -- Handle different window modes
  if mode == "horizontal_split" then
    -- Create horizontal split
    if size then
      vim.cmd(size .. "split")
    else
      vim.cmd("split")
    end
    vim.api.nvim_win_set_buf(0, bufnr)
  elseif mode == "vertical_split" then
    -- Create vertical split  
    if size then
      vim.cmd(size .. "vsplit")
    else
      vim.cmd("vsplit")
    end
    vim.api.nvim_win_set_buf(0, bufnr)
  elseif mode == "new_buffer" then
    -- Switch to buffer in current window (original behavior)
    vim.api.nvim_set_current_buf(bufnr)
  else
    vim.notify("Invalid split mode: " .. mode .. ". Using new_buffer mode.", vim.log.levels.WARN)
    vim.api.nvim_set_current_buf(bufnr)
  end
  
  -- Handle focus setting
  if not focus then
    -- Switch back to the previous window if we don't want focus
    vim.cmd("wincmd p")
  end
  
  return bufnr
end

-- Create a log buffer for build/watch output
-- @param log_name string: Name of the log (e.g., "build", "watch")
-- @return number|nil: Buffer number or nil on error
function M.create_log_buffer(log_name)
  local valid, err = validation.validate_non_empty_string(log_name, "log_name", false)
  if not valid then
    vim.notify(validation.validation_error(err, "create_log_buffer"), vim.log.levels.ERROR)
    return nil
  end
  
  local bufnr = M.create_scratch_buffer(log_name .. ".log", {
    filetype = 'log',
    modifiable = true,
    buftype = 'nofile',
    bufhidden = 'hide'
  })
  
  if bufnr then
    -- Switch to the log buffer to show it
    vim.api.nvim_set_current_buf(bufnr)
  end
  
  return bufnr
end

-- Clear buffer contents
-- @param bufnr number: Buffer number
-- @return boolean: Success status
function M.clear_buffer(bufnr)
  local valid, err = validation.validate_buffer(bufnr, "buffer number")
  if not valid then
    vim.notify(validation.validation_error(err, "clear_buffer"), vim.log.levels.ERROR)
    return false
  end
  
  local ok, err_msg = pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, {})
  if not ok then
    vim.notify(validation.validation_error("Failed to clear buffer: " .. err_msg, "clear_buffer"), vim.log.levels.ERROR)
    return false
  end
  
  return true
end

-- Write content to buffer, replacing existing content
-- @param bufnr number: Buffer number
-- @param lines table: Array of lines to write
-- @return boolean: Success status
function M.write_to_buffer(bufnr, lines)
  local valid, err = validation.validate_buffer(bufnr, "buffer number")
  if not valid then
    vim.notify(validation.validation_error(err, "write_to_buffer"), vim.log.levels.ERROR)
    return false
  end
  
  local lines_valid, lines_err = validation.validate_table(lines, "lines", false)
  if not lines_valid then
    vim.notify(validation.validation_error(lines_err, "write_to_buffer"), vim.log.levels.ERROR)
    return false
  end
  
  -- Clear buffer first
  if not M.clear_buffer(bufnr) then
    return false
  end
  
  -- Write new content
  return M.append_to_buffer(bufnr, lines)
end

-- Get buffer content as array of lines
-- @param bufnr number: Buffer number
-- @return table|nil: Array of lines or nil on error
function M.get_buffer_lines(bufnr)
  local valid, err = validation.validate_buffer(bufnr, "buffer number")
  if not valid then
    vim.notify(validation.validation_error(err, "get_buffer_lines"), vim.log.levels.ERROR)
    return nil
  end
  
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
  if not ok then
    vim.notify(validation.validation_error("Failed to get buffer lines: " .. lines, "get_buffer_lines"), vim.log.levels.ERROR)
    return nil
  end
  
  return lines
end

-- Check if buffer is visible in any window
-- @param bufnr number: Buffer number
-- @return boolean: True if buffer is visible
function M.is_buffer_visible(bufnr)
  local valid, err = validation.validate_buffer(bufnr, "buffer number")
  if not valid then
    return false
  end
  
  local windows = vim.fn.win_findbuf(bufnr)
  return #windows > 0
end

-- Focus on buffer if it's visible, otherwise open it in current window
-- @param bufnr number: Buffer number
-- @return boolean: Success status
function M.focus_buffer(bufnr)
  local valid, err = validation.validate_buffer(bufnr, "buffer number")
  if not valid then
    vim.notify(validation.validation_error(err, "focus_buffer"), vim.log.levels.ERROR)
    return false
  end
  
  local windows = vim.fn.win_findbuf(bufnr)
  if #windows > 0 then
    -- Buffer is visible, focus on first window showing it
    local ok, err_msg = pcall(vim.api.nvim_set_current_win, windows[1])
    if not ok then
      vim.notify(validation.validation_error("Failed to focus window: " .. err_msg, "focus_buffer"), vim.log.levels.ERROR)
      return false
    end
  else
    -- Buffer not visible, open in current window
    local ok, err_msg = pcall(vim.api.nvim_set_current_buf, bufnr)
    if not ok then
      vim.notify(validation.validation_error("Failed to switch to buffer: " .. err_msg, "focus_buffer"), vim.log.levels.ERROR)
      return false
    end
  end
  
  return true
end

return M