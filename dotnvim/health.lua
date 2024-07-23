local health = vim.health or require "health"
local start = health.start or health.report_start
local health_ok = health.ok or health.report_ok
local health_warn = health.warn or health.report_warn
local health_error = health.error or health.report_error
local health_info = health.info or health.report_info

--local is_win = vim.api.nvim_call_function("has", { "win32" }) == 1

local M = {}

function M.check()
    start("dotnvim")
    local function info(msg, ...)
        health_info(msg:format(...))
    end
    local function ok(msg, ...)
        health_ok(msg:format(...))
    end
    local function warn(msg, ...)
        health_warn(msg:format(...))
    end
    local function error(msg, ...)
        health_warn(msg:format(...))
    end

    local function exe_check(binary)
        local found = vim.fn.executable(binary) == 1
        -- if not found  and is_win then
        --     binary = binary .. ".exe"
        --     found = vim.fn.executable(binary) == 1
        -- end
        if found then
            local handle = io.popen(binary .. " --version")
            if handle ~= nil then
                local binary_ver = handle:read "*a"
                handle:close()
                return true, binary_ver
            end
        end
        return false, nil
    end

    -- check the executables
    info("Checking Required Executables")
    local dotnet_exe, dotnet_vers = exe_check("dotnet")
    local fd_exe, fd_vers = exe_check("fd")
    if dotnet_exe then
        ok("    ==> #dotnet# is installed -> "..dotnet_vers)
    else
        error("!!! ==> #dotnet# is not installed, make sure dotnet is in $PATH")
    end

    if fd_exe then
        ok("    ==> #fd# is installed -> "..fd_vers)
    else
        error("!!! ==> #fd# is not installed, make sure fd is in $PATH")
    end
    -- Check the Required Dependencies
    info("Checking Required Dependencies")
    if pcall(require, 'nvim-treesitter.configs') then
        ok("    ==> #nvim-treesitter# is installed.")
    else
        error("!!! ==> #nvim-treesitter# is not installed. This plugin must be installed [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)")
    end

    -- check the required optionall dependencies
    info("Checking Optional Dependencies")
    if pcall(require, 'telescope') then
        ok("    ==> #telescope# is installed for dotnvim.buildcsproj")
    else
        warn("!!! ==> #telescope# is not installed. You will not be able to use telescope ui features. [telescope](https://github.com/nvim-telescope/telescope.nvim)")
    end
    if pcall(require, 'nui') then
        ok("    ==> #nui.nvim# is installed for ui capabilities during bootsrap")
    else
        warn("!!! ==> #nui.nvim# is not installed. You will not be able to use ui features when bootstrapping. [nui](https://github.com/MunifTanjim/nui.nvim)")
    end
end

return M
