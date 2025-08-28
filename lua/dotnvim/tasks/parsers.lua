-- Multi-format task configuration parsers
local validation = require('dotnvim.utils.validation')
local task_validation = require('dotnvim.tasks.validation')
local variables = require('dotnvim.utils.variables')

local M = {}

-- Parser registry for different formats
local parsers = {}

-- JSON Parser
parsers.json = {
  extensions = {'.json'},
  parse = function(content, file_path)
    local ok, result = pcall(vim.json.decode, content)
    if not ok then
      return nil, "JSON parse error: " .. result
    end
    return result, nil
  end
}

-- Basic TOML Parser (simplified implementation)
parsers.toml = {
  extensions = {'.toml'},
  parse = function(content, file_path)
    -- Try external TOML parser first if available
    local ok, toml_parser = pcall(require, 'toml')
    if ok and toml_parser.parse then
      local success, result = pcall(toml_parser.parse, content)
      if success then
        return result, nil
      end
    end
    
    -- Fallback to basic TOML parser for simple structures
    return M.parse_basic_toml(content)
  end
}

-- Basic YAML Parser (simplified implementation)
parsers.yaml = {
  extensions = {'.yaml', '.yml'},
  parse = function(content, file_path)
    -- Try external YAML parser first if available
    local ok, yaml_parser = pcall(require, 'yaml')
    if ok and yaml_parser.load then
      local success, result = pcall(yaml_parser.load, content)
      if success then
        return result, nil
      end
    end
    
    -- Try lyaml parser
    ok, yaml_parser = pcall(require, 'lyaml')
    if ok and yaml_parser.load then
      local success, result = pcall(yaml_parser.load, content)
      if success then
        return result, nil
      end
    end
    
    -- Fallback to basic YAML parser for simple structures
    return M.parse_basic_yaml(content)
  end
}

-- Detect format from file extension
-- @param file_path string: Path to the configuration file
-- @return string|nil: Format name or nil if unknown
function M.detect_format(file_path)
  validation.assert_string(file_path, "file_path", false)
  
  local lower_path = file_path:lower()
  
  for format_name, parser in pairs(parsers) do
    for _, ext in ipairs(parser.extensions) do
      if lower_path:match(ext .. "$") then
        return format_name
      end
    end
  end
  
  return nil
end

-- Parse task configuration file
-- @param file_path string: Path to the configuration file  
-- @return table|nil, string|nil: Parsed configuration or nil, error message
function M.parse_task_file(file_path)
  validation.assert_string(file_path, "file_path", false)
  
  -- Check if file exists
  local stat = vim.loop.fs_stat(file_path)
  if not stat or stat.type ~= "file" then
    return nil, "File does not exist: " .. file_path
  end
  
  -- Read file content
  local fd = vim.loop.fs_open(file_path, "r", 438)
  if not fd then
    return nil, "Could not open file: " .. file_path
  end
  
  local content = vim.loop.fs_read(fd, stat.size, 0)
  vim.loop.fs_close(fd)
  
  if not content then
    return nil, "Could not read file: " .. file_path
  end
  
  -- Detect format
  local format = M.detect_format(file_path)
  if not format then
    return nil, "Unknown file format: " .. file_path
  end
  
  -- Parse content
  local parser = parsers[format]
  if not parser then
    return nil, "No parser available for format: " .. format
  end
  
  local config, parse_err = parser.parse(content, file_path)
  if not config then
    return nil, parse_err or ("Failed to parse " .. format .. " file")
  end
  
  -- Normalize configuration
  local normalized = task_validation.normalize_config(config, format)
  
  -- Apply variable substitution using project root from file path
  local project_root = vim.fn.fnamemodify(file_path, ':h:h') -- Go up from .nvim/tasks.json to project root
  -- Handle .vscode case
  if vim.fn.fnamemodify(file_path, ':h:t') == '.vscode' then
    project_root = vim.fn.fnamemodify(file_path, ':h:h')
  elseif vim.fn.fnamemodify(file_path, ':h:t') == '.nvim' then
    project_root = vim.fn.fnamemodify(file_path, ':h:h')
  else
    -- Fallback to file directory if not in expected structure
    project_root = vim.fn.fnamemodify(file_path, ':h')
  end
  
  normalized = variables.substitute_task_variables(normalized, project_root)
  
  -- Validate configuration (after variable substitution)
  local valid, errors = task_validation.validate_config(normalized, file_path)
  
  if not valid then
    local error_strings = {}
    for i, error in ipairs(errors) do
      error_strings[i] = type(error) == "string" and error or vim.inspect(error)
    end
    return nil, "Validation errors:\\n" .. table.concat(error_strings, "\\n")
  end
  
  -- Validate dependencies
  local deps_valid, dep_errors = task_validation.validate_dependencies(normalized.tasks)
  if not deps_valid then
    local error_strings = {}
    for i, error in ipairs(dep_errors) do
      error_strings[i] = type(error) == "string" and error or vim.inspect(error)
    end
    return nil, "Dependency errors:\\n" .. table.concat(error_strings, "\\n")
  end
  
  return normalized, nil
end

-- Basic TOML parser for simple task configurations
-- @param content string: TOML content
-- @return table|nil, string|nil: Parsed content or nil, error message
function M.parse_basic_toml(content)
  local config = {tasks = {}}
  local current_task = nil
  local in_env_section = false
  
  for line in content:gmatch("[^\\r\\n]+") do
    line = line:match("^%s*(.-)%s*$") -- Trim whitespace
    
    if line == "" or line:match("^#") then
      -- Skip empty lines and comments
    elseif line:match("^version%s*=") then
      config.version = line:match('version%s*=%s*["\']([^"\']+)["\']')
    elseif line:match("^%[%[tasks%]%]") then
      -- New task section
      current_task = {}
      table.insert(config.tasks, current_task)
      in_env_section = false
    elseif line:match("^%[tasks%.env%]") then
      -- Environment section for current task
      in_env_section = true
      if current_task then
        current_task.env = current_task.env or {}
      end
    elseif current_task and not in_env_section then
      -- Task property
      local key, value = line:match("^(%w+)%s*=%s*(.+)")
      if key and value then
        if key == "previous" then
          -- Handle array format: previous = ["dep1", "dep2"]
          local array_content = value:match("%[(.*)%]")
          if array_content then
            current_task.previous = {}
            for item in array_content:gmatch('["\']([^"\']+)["\']') do
              table.insert(current_task.previous, item)
            end
          end
        else
          -- Remove quotes from string values
          current_task[key] = value:match('["\']([^"\']+)["\']') or value
        end
      end
    elseif current_task and in_env_section then
      -- Environment variable
      local key, value = line:match("^(%w+)%s*=%s*(.+)")
      if key and value then
        current_task.env[key] = value:match('["\']([^"\']+)["\']') or value
      end
    end
  end
  
  if not config.version then
    return nil, "Missing version in TOML configuration"
  end
  
  return config, nil
end

-- Basic YAML parser for simple task configurations
-- @param content string: YAML content  
-- @return table|nil, string|nil: Parsed content or nil, error message
function M.parse_basic_yaml(content)
  local config = {}
  local lines = vim.split(content, "\\n")
  local current_task = nil
  local indent_stack = {}
  
  for _, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    
    if trimmed == "" or trimmed:match("^#") then
      -- Skip empty lines and comments
    else
      local indent = #line - #line:match("^%s*(.*)"):match("^(%S.*)")
      local key, value = trimmed:match("^([^:]+):%s*(.*)")
      
      if key then
        key = key:match("^%s*(.-)%s*$") -- Trim key
        value = value:match("^%s*(.-)%s*$") -- Trim value
        
        if key == "version" then
          config.version = value:match('["\']([^"\']+)["\']') or value
        elseif key == "tasks" then
          config.tasks = {}
        elseif trimmed:match("^-%s*name:") then
          -- New task item
          current_task = {}
          table.insert(config.tasks, current_task)
          current_task.name = value:match('["\']([^"\']+)["\']') or value
        elseif current_task then
          if key == "previous" then
            -- Handle array format
            if value:match("^%[.*%]$") then
              -- Inline array: [item1, item2]
              current_task.previous = {}
              for item in value:gmatch('["\']?([^",\'%]]+)["\']?') do
                item = item:match("^%s*(.-)%s*$")
                if item ~= "" then
                  table.insert(current_task.previous, item)
                end
              end
            end
          elseif key == "env" then
            current_task.env = {}
          else
            -- Regular property
            current_task[key] = value:match('["\']([^"\']+)["\']') or value
          end
        end
      elseif current_task and current_task.env and trimmed:match("^%w+:") then
        -- Environment variable
        local env_key, env_value = trimmed:match("^(%w+):%s*(.*)")
        if env_key and env_value then
          current_task.env[env_key] = env_value:match('["\']([^"\']+)["\']') or env_value
        end
      end
    end
  end
  
  if not config.version then
    return nil, "Missing version in YAML configuration"
  end
  
  return config, nil
end

-- Get all supported file extensions
-- @return table: Array of supported extensions
function M.get_supported_extensions()
  local extensions = {}
  for _, parser in pairs(parsers) do
    vim.list_extend(extensions, parser.extensions)
  end
  return extensions
end

-- Get supported formats
-- @return table: Array of format names
function M.get_supported_formats()
  return vim.tbl_keys(parsers)
end

-- Register a custom parser
-- @param format_name string: Name of the format
-- @param parser table: Parser configuration {extensions, parse function}
function M.register_parser(format_name, parser)
  validation.assert_string(format_name, "format_name", false)
  validation.assert_table(parser, "parser", false)
  validation.assert_table(parser.extensions, "parser.extensions", false)
  validation.assert_function(parser.parse, "parser.parse", false)
  
  parsers[format_name] = parser
end

-- Test if content is valid for a given format
-- @param content string: File content
-- @param format string: Format to test
-- @return boolean: True if content can be parsed
function M.test_parse(content, format)
  local parser = parsers[format]
  if not parser then
    return false
  end
  
  local result, err = parser.parse(content, "test")
  return result ~= nil
end

return M