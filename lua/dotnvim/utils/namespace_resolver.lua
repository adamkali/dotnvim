-- Namespace resolution utilities for .NET projects
local project_scanner = require('dotnvim.utils.project_scanner')
local path_utils = require('dotnvim.utils.path_utils')
local validation = require('dotnvim.utils.validation')

local M = {}

-- Convert file path to namespace based on project structure
-- @param file_path string: Full path to the file
-- @param project_directory string: Root directory of the project
-- @return string: Calculated namespace
function M.get_namespace_from_path(file_path, project_directory)
  validation.assert_string(file_path, "file_path", false)
  validation.assert_string(project_directory, "project_directory", false)
  
  local namespace = string.gsub(file_path, project_directory, "")
  
  -- Convert path separators to dots
  namespace = string.gsub(namespace, "/", ".")
  namespace = string.gsub(namespace, "\\", ".")
  
  -- Clean up the namespace
  namespace = string.gsub(namespace, "^%.", "")  -- Remove leading dot
  namespace = string.gsub(namespace, "%.$", "") -- Remove trailing dot
  
  return namespace
end

-- Get file information and calculated namespace for a given path
-- @param file_path string: Path to analyze (optional, defaults to current file)
-- @return table: {namespace: string, path: string, file_name: string} or nil on error
function M.get_file_and_namespace(file_path)
  file_path = file_path or vim.fn.expand('%:p')
  
  local valid, err = validation.validate_non_empty_string(file_path, "file_path", false)
  if not valid then
    vim.notify(validation.validation_error(err, "get_file_and_namespace"), vim.log.levels.ERROR)
    return nil
  end
  
  -- Normalize path separators
  file_path = string.gsub(file_path, "\\", "/")
  
  -- Extract directory and file information
  local directory = string.match(file_path, "(.+/)[^/\\]+%..+$")
  local file_name = string.match(file_path, "[^/\\]+%..+$")
  
  if not directory or not file_name then
    vim.notify("Invalid file path format: " .. file_path, vim.log.levels.ERROR)
    return nil
  end
  
  local file_base_name = path_utils.get_last_path_part(file_name)
  if not file_base_name then
    vim.notify("Could not extract base name from: " .. file_name, vim.log.levels.ERROR)
    return nil
  end
  
  file_base_name = string.match(file_base_name, "[^%.]+")
  if not file_base_name then
    vim.notify("Could not extract file base name from: " .. file_name, vim.log.levels.ERROR)
    return nil
  end
  
  -- Find project files
  local project_files = project_scanner.find_project_files(directory)
  
  -- Calculate namespace based on project structure
  local namespace = ''
  if project_files.slnx then
    namespace = M.get_namespace_from_path(file_path, project_files.slnx.directory)
  elseif project_files.sln then
    namespace = M.get_namespace_from_path(file_path, project_files.sln.directory)
  elseif project_files.csproj then
    namespace = M.get_namespace_from_path(file_path, project_files.csproj.directory)
  end
  
  -- Clean up namespace - remove file name and extensions
  namespace = string.gsub(namespace, "%." .. file_base_name .. "%..*$", "")
  namespace = string.gsub(namespace, "^%.", "")
  namespace = string.gsub(namespace, "%.$", "")
  
  return {
    namespace = namespace,
    path = file_path,
    file_name = file_base_name,
    project_files = project_files
  }
end

-- Get file information and namespace for the current buffer
-- @return table: {namespace: string, path: string, file_name: string} or nil on error
function M.get_current_file_and_namespace()
  local current_path = vim.fn.expand('%:p')
  
  if current_path == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return nil
  end
  
  return M.get_file_and_namespace(current_path)
end

-- Validate namespace string
-- @param namespace string: Namespace to validate
-- @return boolean, string: True if valid, error message if invalid
function M.validate_namespace(namespace)
  local valid, err = validation.validate_string(namespace, "namespace", false)
  if not valid then
    return false, err
  end
  
  if namespace == "" then
    return false, "Namespace cannot be empty"
  end
  
  -- Check for valid C# namespace format (simplified)
  if not namespace:match("^[%w%.]+$") then
    return false, "Namespace contains invalid characters - only letters, numbers, and dots allowed"
  end
  
  if namespace:match("^%.") or namespace:match("%.$") then
    return false, "Namespace cannot start or end with a dot"
  end
  
  if namespace:match("%.%.") then
    return false, "Namespace cannot contain consecutive dots"
  end
  
  return true, nil
end

-- Create a namespace from components
-- @param components table: Array of namespace components
-- @return string: Joined namespace
function M.create_namespace(components)
  validation.assert_table(components, "components", false)
  
  local valid_components = {}
  for _, component in ipairs(components) do
    if validation.is_string(component) and component ~= "" then
      table.insert(valid_components, component)
    end
  end
  
  return table.concat(valid_components, ".")
end

-- Split namespace into components
-- @param namespace string: Namespace to split
-- @return table: Array of namespace components
function M.split_namespace(namespace)
  validation.assert_string(namespace, "namespace", false)
  
  if namespace == "" then
    return {}
  end
  
  local components = {}
  for component in string.gmatch(namespace, "[^%.]+") do
    table.insert(components, component)
  end
  
  return components
end

return M