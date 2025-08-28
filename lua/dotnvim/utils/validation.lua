-- Validation utilities for type checking and parameter validation
local M = {}

-- Type checking functions
function M.is_string(value)
  return type(value) == "string"
end

function M.is_number(value)
  return type(value) == "number"
end

function M.is_table(value)
  return type(value) == "table"
end

function M.is_function(value)
  return type(value) == "function"
end

function M.is_boolean(value)
  return type(value) == "boolean"
end

function M.is_nil(value)
  return value == nil
end

-- Enhanced validation with error messages
function M.validate_string(value, name, allow_nil)
  if allow_nil and M.is_nil(value) then
    return true, nil
  end
  if not M.is_string(value) then
    return false, string.format("%s must be a string, got %s", name or "value", type(value))
  end
  return true, nil
end

function M.validate_non_empty_string(value, name, allow_nil)
  if allow_nil and M.is_nil(value) then
    return true, nil
  end
  local valid, err = M.validate_string(value, name, false)
  if not valid then
    return false, err
  end
  if value == "" then
    return false, string.format("%s cannot be empty", name or "string")
  end
  return true, nil
end

function M.validate_number(value, name, allow_nil)
  if allow_nil and M.is_nil(value) then
    return true, nil
  end
  if not M.is_number(value) then
    return false, string.format("%s must be a number, got %s", name or "value", type(value))
  end
  return true, nil
end

function M.validate_function(value, name, allow_nil)
  if allow_nil and M.is_nil(value) then
    return true, nil
  end
  if not M.is_function(value) then
    return false, string.format("%s must be a function, got %s", name or "value", type(value))
  end
  return true, nil
end

function M.validate_table(value, name, allow_nil)
  if allow_nil and M.is_nil(value) then
    return true, nil
  end
  if not M.is_table(value) then
    return false, string.format("%s must be a table, got %s", name or "value", type(value))
  end
  return true, nil
end

function M.validate_boolean(value, name, allow_nil)
  if allow_nil and M.is_nil(value) then
    return true, nil
  end
  if not M.is_boolean(value) then
    return false, string.format("%s must be a boolean, got %s", name or "value", type(value))
  end
  return true, nil
end

-- File path validation
function M.validate_file_path(path, name, must_exist)
  local valid, err = M.validate_non_empty_string(path, name or "file path", false)
  if not valid then
    return false, err
  end
  
  if must_exist then
    local stat = vim.loop.fs_stat(path)
    if not stat then
      return false, string.format("%s does not exist: %s", name or "file", path)
    end
    if stat.type ~= "file" then
      return false, string.format("%s is not a file: %s", name or "path", path)
    end
  end
  
  return true, nil
end

-- Directory path validation
function M.validate_directory_path(path, name, must_exist)
  local valid, err = M.validate_non_empty_string(path, name or "directory path", false)
  if not valid then
    return false, err
  end
  
  if must_exist then
    local stat = vim.loop.fs_stat(path)
    if not stat then
      return false, string.format("%s does not exist: %s", name or "directory", path)
    end
    if stat.type ~= "directory" then
      return false, string.format("%s is not a directory: %s", name or "path", path)
    end
  end
  
  return true, nil
end

-- .csproj file validation
function M.validate_csproj_path(path, name)
  local valid, err = M.validate_file_path(path, name or "csproj file", false)
  if not valid then
    return false, err
  end
  
  if not path:match("%.csproj$") then
    return false, string.format("%s must be a .csproj file: %s", name or "file", path)
  end
  
  return true, nil
end

-- Buffer validation
function M.validate_buffer(bufnr, name)
  local valid, err = M.validate_number(bufnr, name or "buffer number", false)
  if not valid then
    return false, err
  end
  
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false, string.format("%s is not a valid buffer: %d", name or "buffer", bufnr)
  end
  
  return true, nil
end

-- Multiple parameter validation helper
function M.validate_params(validations)
  for _, validation in ipairs(validations) do
    local value, validator_fn, name, allow_nil = validation[1], validation[2], validation[3], validation[4]
    local valid, err = validator_fn(value, name, allow_nil)
    if not valid then
      return false, err
    end
  end
  return true, nil
end

-- Create a validation error
function M.validation_error(message, context)
  local full_message = message
  if context then
    full_message = string.format("[%s] %s", context, message)
  end
  return full_message
end

-- Assert-style validation that throws errors
function M.assert_string(value, name, allow_nil)
  local valid, err = M.validate_string(value, name, allow_nil)
  if not valid then
    error(M.validation_error(err, "parameter validation"))
  end
end

function M.assert_function(value, name, allow_nil)
  local valid, err = M.validate_function(value, name, allow_nil)
  if not valid then
    error(M.validation_error(err, "parameter validation"))
  end
end

function M.assert_table(value, name, allow_nil)
  local valid, err = M.validate_table(value, name, allow_nil)
  if not valid then
    error(M.validation_error(err, "parameter validation"))
  end
end

function M.assert_csproj_path(path, name)
  local valid, err = M.validate_csproj_path(path, name)
  if not valid then
    error(M.validation_error(err, "parameter validation"))
  end
end

return M