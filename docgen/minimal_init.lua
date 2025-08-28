-- Minimal Neovim configuration for documentation generation
-- This file is used by the documentation generation system

-- Determine neorg path (CI vs local)
local neorg_path = vim.env.NEORG_PATH or '/tmp/neorg'
if vim.fn.isdirectory(neorg_path) == 0 then
  -- Try alternative paths for local development
  local alt_paths = {
    vim.fn.expand('~/.local/share/nvim/lazy/neorg'),
    vim.fn.expand('~/.local/share/nvim/site/pack/packer/start/neorg'),
    './neorg', -- If cloned locally
  }
  
  for _, path in ipairs(alt_paths) do
    if vim.fn.isdirectory(path) == 1 then
      neorg_path = path
      break
    end
  end
end

-- Add neorg to runtime path
vim.opt.rtp:prepend(neorg_path)

-- Disable swap files and backups for headless operation
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Setup neorg with minimal configuration for export
require('neorg').setup {
  load = {
    ["core.defaults"] = {},
    ["core.export"] = {},
    ["core.export.markdown"] = {
      config = {
        extensions = "all",
        metadata = true,
      }
    },
    ["core.integrations.treesitter"] = {
      config = {
        configure_parsers = true,
        install_parsers = false, -- Don't auto-install in CI
      }
    }
  }
}

-- Helper function to export a single file
local function export_norg_file(input_file, output_file)
  vim.cmd('edit ' .. input_file)
  
  -- Wait for file to load
  vim.wait(1000, function()
    return vim.api.nvim_buf_get_name(0):match('%.norg$') ~= nil
  end)
  
  -- Export to markdown
  vim.cmd('Neorg export to-file ' .. output_file)
  
  -- Wait for export to complete
  vim.wait(2000, function()
    return vim.fn.filereadable(output_file) == 1
  end)
end

-- Export all norg files if run in batch mode
if vim.env.BATCH_EXPORT then
  local docs_dir = 'docs/norg'
  local output_dir = 'docs/generated'
  
  -- Ensure output directory exists
  vim.fn.mkdir(output_dir, 'p')
  
  -- Find all .norg files
  local norg_files = vim.fn.glob(docs_dir .. '/*.norg', false, true)
  
  for _, norg_file in ipairs(norg_files) do
    local filename = vim.fn.fnamemodify(norg_file, ':t:r') -- Remove path and extension
    local output_file = output_dir .. '/' .. filename .. '.md'
    
    print('Converting ' .. norg_file .. ' to ' .. output_file)
    export_norg_file(norg_file, output_file)
  end
  
  print('Documentation generation complete')
  vim.cmd('qa!')
end