if 1 ~= vim.fn.has "nvim-0.9.0" then
    vim.api.nvim_err_writeln "dotnvim requires at least nvim-0.9.0. See `:h telescope.changelog-2499`"
    return
end

vim.g.dotnvim = {
    last_used_csproj = nil,
    build_output_lines = {},
    build_error_lines = {}
}
