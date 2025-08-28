# DotNvim Configuration UI

The DotNvim plugin now includes a comprehensive configuration UI that displays all your configured settings in an easy-to-read floating window.

## Usage

### View All Configuration
To view your complete DotNvim configuration:

```lua
-- Via Lua API
require('dotnvim').show_config()

-- Via command
:DotNvimConfig
```

### View Specific Configuration Section
To view a specific configuration section:

```lua
-- Via Lua API
require('dotnvim').show_config_section('builders')
require('dotnvim').show_config_section('ui')
require('dotnvim').show_config_section('dap')
require('dotnvim').show_config_section('nuget')
require('dotnvim').show_config_section('tasks')
require('dotnvim').show_config_section('debug')

-- Via command
:DotNvimConfigSection builders
:DotNvimConfigSection ui
:DotNvimConfigSection dap
:DotNvimConfigSection nuget
:DotNvimConfigSection tasks
:DotNvimConfigSection debug
```

## What's Displayed

The configuration UI shows:

### 📊 Status Section
- Configuration initialization status
- Last used project path
- Running watch status

### 🔨 Builders Configuration
- Build output callback settings
- HTTPS launch settings
- Other build-related configurations

### 🎨 UI Configuration
- Pretty UI preferences
- Display options

### 🐛 DAP (Debug Adapter Protocol) Configuration
- Adapter settings (netcoredbg configuration)
- Debug configurations for C#
- Adapter command and arguments

### 📦 NuGet Configuration
- Package sources
- Authentication settings
- Custom authenticators

### ⚡ Tasks Configuration
- Task execution mode
- DAP integration settings
- Pre-debug task configuration
- Timeout settings

### 🔍 Debug Configuration
- Debug logging enablement
- Log file path settings

## Navigation

Within the configuration window:
- Press `q`, `<Esc>`, or `<C-c>` to close the window
- Use standard Neovim navigation keys to scroll through the content
- The window is read-only and syntax-highlighted as Lua code

## Configuration Tips

The UI also provides helpful tips at the bottom:
- How to customize settings using `require("dotnvim").setup({...})`
- Reference to documentation
- Log file location for troubleshooting

## Example Usage in Your Config

```lua
-- In your Neovim configuration
local dotnvim = require('dotnvim')

-- Setup with custom configuration
dotnvim.setup({
  builders = {
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
    },
  },
  -- ... other configurations
})

-- View your configuration anytime
vim.keymap.set('n', '<leader>dc', function()
  dotnvim.show_config()
end, { desc = 'Show DotNvim config' })

-- Quick access to specific sections
vim.keymap.set('n', '<leader>dd', function()
  dotnvim.show_config_section('dap')
end, { desc = 'Show DAP config' })
```

This configuration UI makes it easy to verify your settings, troubleshoot issues, and understand the current state of your DotNvim setup.