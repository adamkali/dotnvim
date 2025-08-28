-- Legacy compatibility module - delegates to focused utility modules
local validation = require('dotnvim.utils.validation')
local project_scanner = require('dotnvim.utils.project_scanner')
local namespace_resolver = require('dotnvim.utils.namespace_resolver')
local ui_helpers = require('dotnvim.utils.ui_helpers')
local buffer_helpers = require('dotnvim.utils.buffer_helpers')

local M = {}

-- @param callback func(csproj): Function to call with selected csproj path
M.select_csproj = function(callback)
    return ui_helpers.select_csproj(callback)
end

-- Load a module with better error handling
-- @param module_name string: Name of the module to load
-- @param source string: Source context for error messages
-- @return table: Loaded module
M.load_module = function(module_name, source)
    validation.assert_string(module_name, "module_name", false)
    validation.assert_string(source, "source", false)
    
    local ok, module = pcall(require, module_name)
    if not ok then
        local error_msg = string.format("%s dependency error: %s not installed", source, module_name)
        error(validation.validation_error(error_msg, "load_module"))
    end
    return module
end

-- Get file information and namespace for a given path
-- @param path string: File path (optional, defaults to current file)
-- @return table: {namespace: string, path: string, file_name: string}
M.get_file_and_namespace = function(path)
    return namespace_resolver.get_file_and_namespace(path)
end

-- Get file information and namespace for the current buffer
-- @return table: {namespace: string, path: string, file_name: string}
M.get_curr_file_and_namespace = function()
    return namespace_resolver.get_current_file_and_namespace()
end

-- Convert file path to namespace based on project structure
-- @param path string: File path
-- @param directory string: Project directory
-- @return string: Calculated namespace
M.get_namespace_from_path = function(path, directory)
    return namespace_resolver.get_namespace_from_path(path, directory)
end

-- Split text by whitespace with special handling for multiple spaces
-- @param entry string: Text to split
-- @return table: Array of tokens
M.get_tokens_split_by_whitespace = function(entry)
    validation.assert_string(entry, "entry", false)
    
    -- Replace double spaces with placeholder, single spaces with underscore, restore spaces
    entry = string.gsub(entry, "  ", "~")
    entry = string.gsub(entry, " ", "_")
    entry = string.gsub(entry, "~", " ")

    local tokens = {}
    for v in string.gmatch(entry, "%S+") do
        v = string.match(v, "%S+")
        if v then
            v = string.gsub(v, "_", " ")
            v = string.gsub(v, '^%s*(.-)%s*$', '%1') -- Fix: was '%2' which is invalid
            v = string.gsub(v, '[ \t]+%f[\r\n%z]', '')
            table.insert(tokens, v)
        end
    end

    return tokens
end

-- Get all .csproj files in the current working directory
-- @return table: Array of {index: number, value: string} tables
M.get_all_csproj = function()
    return project_scanner.get_all_csproj()
end

-- Get DLL path from .csproj path
-- @param csproj_path string: Path to the .csproj file
-- @return string: Path to the compiled DLL
function M.get_dll_from_csproj(csproj_path)
    return project_scanner.get_dll_from_csproj(csproj_path)
end

-- Append lines to a buffer
-- @param bufnr number: Buffer number
-- @param lines table: Array of lines to append
-- @return boolean: Success status
M.append_to_buffer = function(bufnr, lines)
    return buffer_helpers.append_to_buffer(bufnr, lines)
end


return M
