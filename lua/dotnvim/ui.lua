local M = {}

local config_manager = require('dotnvim.config_manager')

-- Create a floating window with configuration details
local function create_config_window(content, title)
  -- Calculate window size
  local width = math.max(80, vim.o.columns - 20)
  local height = math.max(20, vim.o.lines - 10)
  
  -- Calculate position to center the window
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'lua')
  
  -- Window options
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. title .. ' ',
    title_pos = 'center',
  }
  
  -- Create window
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  
  -- Set window options
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  
  -- Set keybindings
  local function close_window()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  -- Key mappings to close the window
  local close_keys = {'q', '<Esc>', '<C-c>'}
  for _, key in ipairs(close_keys) do
    vim.keymap.set('n', key, close_window, { buffer = buf, nowait = true })
  end
  
  return buf, win
end

-- Convert a table to a formatted string representation
local function table_to_string(tbl, indent, max_depth, current_depth)
  indent = indent or 0
  max_depth = max_depth or 10
  current_depth = current_depth or 0
  
  if current_depth >= max_depth then
    return "{ ... }"
  end
  
  if type(tbl) ~= 'table' then
    if type(tbl) == 'string' then
      return '"' .. tbl .. '"'
    elseif type(tbl) == 'function' then
      return '<function>'
    elseif tbl == nil then
      return 'nil'
    else
      return tostring(tbl)
    end
  end
  
  local result = {}
  local spacing = string.rep('  ', indent)
  
  -- Check if it's an array
  local is_array = true
  local array_length = 0
  for k, _ in pairs(tbl) do
    if type(k) ~= 'number' then
      is_array = false
      break
    end
    array_length = math.max(array_length, k)
  end
  
  if is_array and #tbl == array_length then
    table.insert(result, '{')
    for i, v in ipairs(tbl) do
      local value_str = table_to_string(v, indent + 1, max_depth, current_depth + 1)
      if i == #tbl then
        table.insert(result, spacing .. '  ' .. value_str)
      else
        table.insert(result, spacing .. '  ' .. value_str .. ',')
      end
    end
    table.insert(result, spacing .. '}')
  else
    table.insert(result, '{')
    local keys = {}
    for k, _ in pairs(tbl) do
      table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
      if type(a) == type(b) then
        return tostring(a) < tostring(b)
      else
        return type(a) < type(b)
      end
    end)
    
    for i, k in ipairs(keys) do
      local v = tbl[k]
      local key_str = type(k) == 'string' and k or '[' .. tostring(k) .. ']'
      local value_str = table_to_string(v, indent + 1, max_depth, current_depth + 1)
      if i == #keys then
        table.insert(result, spacing .. '  ' .. key_str .. ' = ' .. value_str)
      else
        table.insert(result, spacing .. '  ' .. key_str .. ' = ' .. value_str .. ',')
      end
    end
    table.insert(result, spacing .. '}')
  end
  
  return table.concat(result, '\n')
end

-- Generate configuration overview content
local function generate_config_content()
  local content = {}
  
  -- Header
  table.insert(content, '-- DotNvim Configuration Overview')
  table.insert(content, '-- Press q, <Esc>, or <C-c> to close this window')
  table.insert(content, '')
  
  -- Check if config is initialized
  if not config_manager.is_initialized() then
    table.insert(content, '⚠️  Configuration not initialized!')
    table.insert(content, 'Run :lua require("dotnvim").setup() first')
    return content
  end
  
  -- Get current configuration
  local config = config_manager.get_config()
  local state = config_manager.get_state()
  
  -- Status section
  table.insert(content, '📊 Status:')
  table.insert(content, '  ✅ Configuration initialized: ' .. (config_manager.is_initialized() and 'Yes' or 'No'))
  table.insert(content, '  📁 Last used project: ' .. (state.last_used_csproj or 'None'))
  table.insert(content, '  🔧 Running watch: ' .. (state.running_watch and 'Yes' or 'No'))
  table.insert(content, '')
  
  -- Builders configuration
  table.insert(content, '🔨 Builders Configuration:')
  local builders_str = table_to_string(config.builders, 0, 5)
  for line in builders_str:gmatch('[^\n]+') do
    table.insert(content, '  ' .. line)
  end
  table.insert(content, '')
  
  -- UI configuration
  table.insert(content, '🎨 UI Configuration:')
  local ui_str = table_to_string(config.ui, 0, 5)
  for line in ui_str:gmatch('[^\n]+') do
    table.insert(content, '  ' .. line)
  end
  table.insert(content, '')
  
  -- DAP configuration
  table.insert(content, '🐛 Debug Adapter Protocol (DAP) Configuration:')
  local dap_str = table_to_string(config.dap, 0, 5)
  for line in dap_str:gmatch('[^\n]+') do
    table.insert(content, '  ' .. line)
  end
  table.insert(content, '')
  
  -- NuGet configuration
  table.insert(content, '📦 NuGet Configuration:')
  local nuget_str = table_to_string(config.nuget, 0, 5)
  for line in nuget_str:gmatch('[^\n]+') do
    table.insert(content, '  ' .. line)
  end
  table.insert(content, '')
  
  -- Tasks configuration
  table.insert(content, '⚡ Tasks Configuration:')
  local tasks_str = table_to_string(config.tasks, 0, 5)
  for line in tasks_str:gmatch('[^\n]+') do
    table.insert(content, '  ' .. line)
  end
  table.insert(content, '')
  
  -- Debug configuration
  table.insert(content, '🔍 Debug Configuration:')
  local debug_str = table_to_string(config.debug, 0, 5)
  for line in debug_str:gmatch('[^\n]+') do
    table.insert(content, '  ' .. line)
  end
  table.insert(content, '')
  
  -- Footer with helpful information
  table.insert(content, '💡 Configuration Tips:')
  table.insert(content, '  • Use require("dotnvim").setup({...}) to customize settings')
  table.insert(content, '  • Check :help dotnvim for detailed documentation')
  table.insert(content, '  • Log file location: ' .. (vim.fn.stdpath('data') .. '/dotnvim.log'))
  
  return content
end

-- Show configuration in a floating window
function M.show_config()
  local content = generate_config_content()
  create_config_window(content, 'DotNvim Configuration')
end

-- Show a specific configuration section
function M.show_config_section(section)
  local content = {}
  
  if not config_manager.is_initialized() then
    table.insert(content, '⚠️  Configuration not initialized!')
    table.insert(content, 'Run :lua require("dotnvim").setup() first')
    create_config_window(content, 'DotNvim - Configuration Error')
    return
  end
  
  local config_func = config_manager['get_' .. section .. '_config']
  if not config_func then
    table.insert(content, '❌ Unknown configuration section: ' .. section)
    table.insert(content, 'Available sections: builders, ui, dap, nuget, tasks, debug')
    create_config_window(content, 'DotNvim - Section Error')
    return
  end
  
  local section_config = config_func()
  
  table.insert(content, '-- DotNvim ' .. section:gsub("^%l", string.upper) .. ' Configuration')
  table.insert(content, '-- Press q, <Esc>, or <C-c> to close this window')
  table.insert(content, '')
  
  local config_str = table_to_string(section_config, 0, 8)
  for line in config_str:gmatch('[^\n]+') do
    table.insert(content, line)
  end
  
  create_config_window(content, 'DotNvim - ' .. section:gsub("^%l", string.upper) .. ' Config')
end

-- Create user commands for easy access
local function setup_commands()
  vim.api.nvim_create_user_command('DotNvimConfig', function()
    M.show_config()
  end, { desc = 'Show DotNvim configuration overview' })
  
  vim.api.nvim_create_user_command('DotNvimConfigSection', function(opts)
    if opts.args == '' then
      vim.notify('Please specify a section: builders, ui, dap, nuget, tasks, debug', vim.log.levels.WARN)
      return
    end
    M.show_config_section(opts.args)
  end, {
    desc = 'Show specific DotNvim configuration section',
    nargs = 1,
    complete = function()
      return { 'builders', 'ui', 'dap', 'nuget', 'tasks', 'debug' }
    end
  })
end

-- Initialize commands when module is loaded
setup_commands()

return M