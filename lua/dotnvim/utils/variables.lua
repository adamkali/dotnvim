-- Variable substitution utility for task configurations
-- Supports VSCode-style variables like ${workspaceFolder}
local validation = require('dotnvim.utils.validation')

local M = {}

-- Standard VSCode variables we support
local SUPPORTED_VARIABLES = {
  'workspaceFolder',
  'workspaceFolderBasename', 
  'file',
  'relativeFile',
  'relativeFileDirname',
  'fileBasename',
  'fileBasenameNoExtension',
  'fileDirname',
  'fileExtname',
  'cwd',
  'lineNumber',
  'selectedText',
  'execPath',
  'pathSeparator'
}

-- Get the current workspace folder (project root)
-- @return string: Workspace folder path
local function get_workspace_folder()
  -- Try to find git root first
  local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
  if vim.v.shell_error == 0 and git_root ~= '' then
    return git_root
  end
  
  -- Fall back to current working directory
  return vim.fn.getcwd()
end

-- Get current file information
-- @return table: File information for variable substitution
local function get_file_info()
  local current_file = vim.api.nvim_buf_get_name(0)
  local workspace_folder = get_workspace_folder()
  
  if current_file == '' then
    -- No file open, use workspace folder
    current_file = workspace_folder
  end
  
  local file_dir = vim.fn.fnamemodify(current_file, ':h')
  local file_basename = vim.fn.fnamemodify(current_file, ':t')
  local file_basename_no_ext = vim.fn.fnamemodify(current_file, ':t:r')
  local file_ext = vim.fn.fnamemodify(current_file, ':e')
  
  -- Calculate relative paths
  local relative_file = vim.fn.fnamemodify(current_file, ':.' )
  local relative_file_dir = vim.fn.fnamemodify(file_dir, ':.')
  
  return {
    file = current_file,
    file_dirname = file_dir,
    file_basename = file_basename,
    file_basename_no_extension = file_basename_no_ext,
    file_extension = file_ext,
    relative_file = relative_file,
    relative_file_dirname = relative_file_dir,
    workspace_folder = workspace_folder,
    workspace_folder_basename = vim.fn.fnamemodify(workspace_folder, ':t'),
  }
end

-- Build variable substitution map
-- @param project_root string: Project root directory (optional)
-- @return table: Map of variable names to values
function M.build_variable_map(project_root)
  local workspace_folder = project_root or get_workspace_folder()
  local file_info = get_file_info()
  
  -- Override workspace folder if provided
  if project_root then
    file_info.workspace_folder = project_root
    file_info.workspace_folder_basename = vim.fn.fnamemodify(project_root, ':t')
  end
  
  local variables = {
    -- Workspace variables
    workspaceFolder = file_info.workspace_folder,
    workspaceFolderBasename = file_info.workspace_folder_basename,
    
    -- File variables
    file = file_info.file,
    relativeFile = file_info.relative_file,
    relativeFileDirname = file_info.relative_file_dirname,
    fileBasename = file_info.file_basename,
    fileBasenameNoExtension = file_info.file_basename_no_extension,
    fileDirname = file_info.file_dirname,
    fileExtname = file_info.file_extension,
    
    -- System variables
    cwd = vim.fn.getcwd(),
    pathSeparator = vim.loop.os_uname().sysname == 'Windows_NT' and '\\' or '/',
    
    -- Editor variables (may not always be available)
    lineNumber = tostring(vim.api.nvim_win_get_cursor(0)[1]),
    selectedText = '', -- TODO: Could implement if needed
    execPath = vim.v.progpath,
  }
  
  return variables
end

-- Substitute variables in a string
-- @param text string: Text containing variables like ${workspaceFolder}
-- @param variable_map table: Map of variable names to values
-- @return string: Text with variables substituted
function M.substitute_variables(text, variable_map)
  validation.assert_string(text, "text", false)
  validation.assert_table(variable_map, "variable_map", false)
  
  if not text:find('%${') then
    -- No variables to substitute
    return text
  end
  
  -- Replace ${variableName} with actual values
  local result = text:gsub('%${([^}]+)}', function(var_name)
    local value = variable_map[var_name]
    if value ~= nil then
      return tostring(value)
    else
      -- Variable not found, leave as-is and warn
      vim.notify("Unknown variable: ${" .. var_name .. "}", vim.log.levels.WARN)
      return "${" .. var_name .. "}"
    end
  end)
  
  return result
end

-- Substitute variables in a table recursively
-- @param data table: Table that may contain variable strings
-- @param variable_map table: Map of variable names to values
-- @return table: Table with variables substituted
function M.substitute_variables_in_table(data, variable_map)
  validation.assert_table(data, "data", false)
  validation.assert_table(variable_map, "variable_map", false)
  
  local function substitute_recursive(obj)
    if type(obj) == "string" then
      return M.substitute_variables(obj, variable_map)
    elseif type(obj) == "table" then
      local result = {}
      for k, v in pairs(obj) do
        local new_key = type(k) == "string" and M.substitute_variables(k, variable_map) or k
        result[new_key] = substitute_recursive(v)
      end
      return result
    else
      return obj
    end
  end
  
  return substitute_recursive(data)
end

-- Substitute variables in task configuration
-- @param task_config table: Task configuration
-- @param project_root string: Project root directory (optional)
-- @return table: Task configuration with variables substituted
function M.substitute_task_variables(task_config, project_root)
  validation.assert_table(task_config, "task_config", false)
  
  local variable_map = M.build_variable_map(project_root)
  return M.substitute_variables_in_table(task_config, variable_map)
end

-- Get list of supported variables for documentation/completion
-- @return table: List of supported variable names
function M.get_supported_variables()
  return vim.deepcopy(SUPPORTED_VARIABLES)
end

-- Validate that all variables in text are supported
-- @param text string: Text to validate
-- @return boolean, table: Valid status and list of unsupported variables
function M.validate_variables(text)
  validation.assert_string(text, "text", false)
  
  local unsupported = {}
  
  text:gsub('%${([^}]+)}', function(var_name)
    if not vim.tbl_contains(SUPPORTED_VARIABLES, var_name) then
      table.insert(unsupported, var_name)
    end
  end)
  
  return #unsupported == 0, unsupported
end

-- Create example with variables for documentation
-- @return string: Example task configuration showing variable usage
function M.create_variable_example()
  return [[{
  "version": "0.1.0",
  "tasks": [
    {
      "name": "build",
      "command": "dotnet build ${workspaceFolder}/MyProject.csproj",
      "cwd": "${workspaceFolder}",
      "env": {
        "PROJECT_ROOT": "${workspaceFolder}",
        "OUTPUT_PATH": "${workspaceFolder}/bin/Debug"
      }
    },
    {
      "name": "test", 
      "command": "dotnet test ${workspaceFolder}/Tests/${fileBasenameNoExtension}.Tests.csproj",
      "cwd": "${fileDirname}",
      "env": {
        "TEST_FILE": "${file}"
      }
    }
  ]
}]]
end

return M