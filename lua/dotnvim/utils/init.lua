local scandir = require('plenary.scandir')
local path_utils = require('dotnvim.utils.path_utils')
local telescope_utils = require('dotnvim.utils.telescope_utils')

local M = {}

-- @param callback func(csproj)
M.select_csproj = function(callback)
    local selections = M.get_all_csproj()
    if pcall(require, 'telescope') and DotnvimConfig.ui.no_pretty_uis ~= true then
        telescope_utils.telescope_select_csproj(selections, callback)
    else
        local items = {}
        for _, file in ipairs(selections) do
            table.insert(items, file.value)
        end
        vim.ui.select(items, {
            prompt = 'Select a .csproj file:',
            format_item = function(item)
                return item
            end
        }, function(choice)
            if choice then
                callback(choice)
            else
                print("No file selected")
            end
        end)
    end
end

-- stolen from nvim-dap-go -- thank you <3
M.load_module = function(module_name, source)
    local ok, module = pcall(require, module_name)
    assert(ok, string.format(source .. " dependency error: %s not installed", module_name))
    return module
end

M.get_file_and_namespace = function(path)
    path = path or vim.fn.expand('%:p')

    path = string.gsub(path, "\\", "/")

    local directory = string.match(path, "(.+/)[^/\\]+%..+$")
    local file_name = string.match(path, "[^/\\]+%..+$")
    local file_base_name = path_utils.get_last_path_part(file_name)
    file_base_name = string.match(file_base_name, "[^%.]+")

    local parents = {}
    for dir in string.gmatch(directory, "[^/\\]+") do
        table.insert(parents, dir .. '/')
    end
    table.insert(parents, "")

    local result = {}
    local curr_directory = directory
    for i = #parents, 2, -1 do
        local directory_to_remove = parents[i]
        curr_directory = string.gsub(curr_directory, directory_to_remove, "")
        local foundFiles = scandir.scan_dir(curr_directory, { depth = 2 })
        for _, file in pairs(foundFiles) do
            if result.csproj == nil and string.match(file, ".csproj") then
                result.csproj = { file = file, directory = curr_directory }
            end
            if result.sln == nil and result.slnx == nil then
                if string.match(file, ".sln") then
                    result.sln = { file = file, directory = curr_directory }
                end
                if string.match(file, ".slnx") then
                    result.slnx = { file = file, directory = curr_directory }
                end
            end
        end
    end

    local namespace = ''
    if result.slnx ~= nil then
        namespace = M.get_namespace_from_path(path, result.slnx.directory)
    elseif result.sln ~= nil then
        namespace = M.get_namespace_from_path(path, result.sln.directory)
    elseif result.csproj ~= nil then
        namespace = M.get_namespace_from_path(path, result.csproj.directory)
    end

    namespace = string.gsub(namespace, "%." .. file_base_name .. "%..*$", "")
    namespace = string.gsub(namespace, "^%.", "")
    namespace = string.gsub(namespace, "%.$", "")

    return {
        namespace = namespace,
        path = path,
        file_name = file_base_name,
    }
end

M.get_curr_file_and_namespace = function()
    local path = vim.fn.expand('%:p')

    return M.get_file_and_namespace(path)
end

M.get_namespace_from_path = function(path, directory)
    local namespace = string.gsub(path, directory, "")

    namespace = string.gsub(namespace, "/", ".")
    namespace = string.gsub(namespace, "\\", ".")

    return namespace
end

M.get_tokens_split_by_whitespace = function(entry)
    entry = string.gsub(entry, "  ", "~")
    entry = string.gsub(entry, " ", "_")
    entry = string.gsub(entry, "~", " ")

    local tokens = {}
    for v in string.gmatch(entry, "%S+") do
        v = string.match(v, "%S+")
        v = string.gsub(v, "_", " ")
        v = string.gsub(v, '^%s*(.-)%s*$', '%2')
        v = string.gsub(v, '[ \t]+%f[\r\n%z]', '')
        table.insert(tokens, v)
    end

    return tokens
end

-- returns
-- {
--     index = 0,
--     value = path/to/<any>.csproj
-- }
M.get_all_csproj = function()
    local result = {}
    local path = vim.fn.getcwd()
    local cwd = string.gsub(path, "\\", "/")
    local csproj_files = scandir.scan_dir(cwd, {
        hidden = false,              -- Include hidden files (those starting with .)
        only_dirs = false,           -- Include both files and directories
        depth = 5,                   -- Set the depth of search
        search_pattern = "%.csproj$" -- Lua pattern to match .csproj files
    })
    for index, value in ipairs(csproj_files) do
        table.insert(result, {
            index = index,
            value = value
        })
    end
    return result
end

function M.get_dll_from_csproj(csproj_path)
    local project_name_with_extension = csproj_path:match("([^/\\]+%.csproj)$")
    if not project_name_with_extension then
        error("Invalid .csproj path: " .. (csproj_path or "nil"))
    end

    local project_name = project_name_with_extension:gsub("%.csproj$", "")
    local dll_name = project_name .. ".dll"
    local lookin = csproj_path:gsub(project_name_with_extension, "")
    print(lookin)

    -- Scan for the .dll file in the specified directory
    local dlls = scandir.scan_dir(lookin, {
        hidden = false,               -- Include hidden files (those starting with .)
        only_dirs = false,            -- Include both files and directories
        depth = 5,                    -- Set the depth of search
        search_pattern = dll_name,    -- Lua pattern to match the .dll file
    })

    print(#dlls)
    if #dlls > 0 then
        return dlls[1]
    else
        error(csproj_path .. " has not been built yet.")
    end
end

-- Function to append lines to a buffer
M.append_to_buffer = function(bufnr, lines)
    -- Get the current number of lines in the buffer
    local line_count = vim.api.nvim_buf_line_count(bufnr)

    -- Insert lines at the end of the buffer
    vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, lines)

    -- Get the window displaying the buffer
    local windows = vim.fn.win_findbuf(bufnr)
    if #windows > 0 then
        local win = windows[1]

        -- Move cursor to the end of the buffer safely
        local last_line = vim.api.nvim_buf_line_count(bufnr)
        if last_line > 0 then
            vim.api.nvim_win_set_cursor(win, { last_line, 0 })
        end
    end
end


return M
