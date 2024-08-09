-- Check if the minimum required Neovim version is met
if vim.fn.has("nvim-0.9.0") ~= 1 then
    vim.api.nvim_err_writeln("dotnvim requires at least nvim-0.9.0.")
    return
end

vim.g.DotnvimConfig = {
    builders = {
        build_output_callback = nil,
        https_launch_setting_always = true,
    },
    ui = {
        no_pretty_uis = false,
    },
    dap = {
        adapter = {
            type = 'executable',
            command = "netcoredbg",
            args = { '--interpreter=vscode' },
        }
    },
    nuget = { }
}

local log_file_path = vim.fn.stdpath('data') .. '/dotnvim.log'

-- Create a user command to view the log
vim.api.nvim_create_user_command('DotnvimLog', function()
    vim.cmd("edit " .. log_file_path)
end, { nargs = 0 })

-- Autocommand to handle .cs, .csproj, and .sln files
vim.api.nvim_create_user_command('DotnvimNugetAuth', function()
    require('dotnvim').nuget_auth()
end, { nargs = 0 })

