if 1 ~= vim.fn.has "nvim-0.9.0" then
    vim.api.nvim_err_writeln "dotnvim requires at least nvim-0.9.0. See `:h telescope.changelog-2499`"
    return
end


-- @param last_used_csproj string
-- @param running_watch plenary.Job
Dotnvim = {
    last_used_csproj = nil,
    running_job = nil,
    running_watch = nil
}

DotnvimConfig = {
}

-- @param build_output_callback function(dotnet_command_str, dotnet_trailing_args?)?
-- @param https_launch_setting_always boolean
DotnvimConfig.builders = {
    build_output_callback = nil,
    https_launch_setting_always = true,
}
-- @param no_pretty_uis boolean
DotnvimConfig.ui = {
    no_pretty_uis = false
}
