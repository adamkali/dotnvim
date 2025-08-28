-- Project scanning utilities for .csproj, .sln files
local scandir = require('plenary.scandir')
local validation = require('dotnvim.utils.validation')

local M = {}

-- Scan for all .csproj files in the current working directory
-- @return table: Array of {index, value} tables where value is the file path
function M.get_all_csproj()
  local result = {}
  local path = vim.fn.getcwd()
  
  -- Validate current directory exists
  local valid, err = validation.validate_directory_path(path, "current working directory", true)
  if not valid then
    vim.notify(err, vim.log.levels.ERROR)
    return result
  end
  
  local cwd = string.gsub(path, "\\", "/")
  
  local ok, csproj_files = pcall(scandir.scan_dir, cwd, {
    hidden = false,              -- Include hidden files (those starting with .)
    only_dirs = false,           -- Include both files and directories
    depth = 5,                   -- Set the depth of search
    search_pattern = "%.csproj$" -- Lua pattern to match .csproj files
  })
  
  if not ok then
    vim.notify("Failed to scan directory for .csproj files: " .. (csproj_files or "unknown error"), vim.log.levels.ERROR)
    return result
  end
  
  for index, value in ipairs(csproj_files) do
    table.insert(result, {
      index = index,
      value = value
    })
  end
  
  return result
end

-- Find project files (.csproj, .sln, .slnx) starting from a given directory
-- @param start_directory string: Directory to start searching from
-- @return table: {csproj: {file, directory}, sln: {file, directory}, slnx: {file, directory}}
function M.find_project_files(start_directory)
  local valid, err = validation.validate_non_empty_string(start_directory, "start_directory", false)
  if not valid then
    error(validation.validation_error(err, "find_project_files"))
  end
  
  local directory = string.gsub(start_directory, "\\", "/")
  if not directory:match("/$") then
    directory = directory .. "/"
  end
  
  local result = {}
  local search_depth = 2
  
  -- Build parent directories list for traversal
  local parents = {}
  for dir in string.gmatch(directory, "[^/\\]+") do
    table.insert(parents, dir .. '/')
  end
  table.insert(parents, "")
  
  -- Search up the directory tree
  local curr_directory = directory
  for i = #parents, 2, -1 do
    local directory_to_remove = parents[i]
    curr_directory = string.gsub(curr_directory, directory_to_remove, "")
    
    local ok, foundFiles = pcall(scandir.scan_dir, curr_directory, { depth = search_depth })
    if ok then
      for _, file in pairs(foundFiles) do
        -- Look for .csproj files
        if result.csproj == nil and string.match(file, "%.csproj$") then
          result.csproj = { file = file, directory = curr_directory }
        end
        
        -- Look for solution files (prioritize .slnx over .sln)
        if result.sln == nil and result.slnx == nil then
          if string.match(file, "%.sln$") then
            result.sln = { file = file, directory = curr_directory }
          end
          if string.match(file, "%.slnx$") then
            result.slnx = { file = file, directory = curr_directory }
          end
        end
      end
    end
    
    -- Stop if we found everything we need
    if result.csproj and (result.sln or result.slnx) then
      break
    end
  end
  
  return result
end

-- Get DLL path from .csproj path
-- @param csproj_path string: Path to the .csproj file
-- @return string: Path to the compiled DLL
function M.get_dll_from_csproj(csproj_path)
  validation.assert_csproj_path(csproj_path, "csproj_path")
  
  local project_name_with_extension = csproj_path:match("([^/\\]+%.csproj)$")
  if not project_name_with_extension then
    error(validation.validation_error("Invalid .csproj path format: " .. csproj_path, "get_dll_from_csproj"))
  end
  
  local project_name = project_name_with_extension:gsub("%.csproj$", "")
  local dll_name = project_name .. ".dll"
  local search_directory = csproj_path:gsub(project_name_with_extension, "")
  
  -- Validate search directory exists
  local valid, err = validation.validate_directory_path(search_directory, "project directory", true)
  if not valid then
    error(validation.validation_error(err, "get_dll_from_csproj"))
  end
  
  -- Scan for the .dll file in the project directory
  local ok, dlls = pcall(scandir.scan_dir, search_directory, {
    hidden = false,               -- Include hidden files (those starting with .)
    only_dirs = false,            -- Include both files and directories
    depth = 5,                    -- Set the depth of search
    search_pattern = dll_name,    -- Lua pattern to match the .dll file
  })
  
  if not ok then
    error(validation.validation_error("Failed to scan for DLL files: " .. (dlls or "unknown error"), "get_dll_from_csproj"))
  end
  
  if #dlls > 0 then
    return dlls[1]
  else
    error(validation.validation_error(csproj_path .. " has not been built yet - no DLL found", "get_dll_from_csproj"))
  end
end

-- Check if a file exists and is readable
-- @param filepath string: Path to check
-- @return boolean: True if file exists and is readable
function M.file_exists(filepath)
  if not validation.is_string(filepath) or filepath == "" then
    return false
  end
  
  local stat = vim.loop.fs_stat(filepath)
  return stat ~= nil and stat.type == "file"
end

-- Get project root directory (where .sln or .slnx is located)
-- @param start_path string: Path to start searching from (optional, defaults to current file)
-- @return string|nil: Project root directory path, or nil if not found
function M.get_project_root(start_path)
  start_path = start_path or vim.fn.expand('%:p:h')
  
  local valid, err = validation.validate_non_empty_string(start_path, "start_path", false)
  if not valid then
    vim.notify(validation.validation_error(err, "get_project_root"), vim.log.levels.WARN)
    return nil
  end
  
  local project_files = M.find_project_files(start_path)
  
  if project_files.slnx then
    return project_files.slnx.directory
  elseif project_files.sln then
    return project_files.sln.directory
  elseif project_files.csproj then
    return project_files.csproj.directory
  end
  
  return nil
end

return M