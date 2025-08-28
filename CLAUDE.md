# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**dotnvim** is a Neovim plugin that provides .NET tooling and development support for .NET projects within Neovim. It offers project bootstrapping, building, watching, debugging, and NuGet authentication capabilities.

## Architecture

The plugin follows a modular Lua architecture:

- **Entry Point**: `lua/dotnvim/init.lua` - Main module with public API functions
- **Core Modules**:
  - `builder.lua` - Handles `dotnet build` and `dotnet watch` operations
  - `bootstrappers.lua` - Provides code generation for C# classes and controllers
  - `config.lua` - Configuration management and DAP setup
  - `nuget.lua` - NuGet source authentication
  - `health.lua` - Plugin health checking
- **Utilities**: `lua/dotnvim/utils/` - Path utilities, LSP helpers, Telescope integration, and templates
- **Generators**: `lua/dotnvim/generators/` - Code generation templates for classes and controllers

## Required Dependencies

### System Executables
- `dotnet` - .NET CLI
- `fd` - File finder utility
- `netcoredbg` - .NET Core debugger (for debugging support)

### Neovim Plugins
- `plenary.nvim` - Required for async jobs and utilities
- `nvim-treesitter` - Required for syntax parsing
- `telescope.nvim` - Optional, for project selection UI
- `nui.nvim` - Optional, for bootstrap UI components
- `nvim-dap` - Optional, for debugging support

## Key APIs and Usage

### Main Functions (lua/dotnvim/init.lua)
- `M.build(last)` - Build project (last=true uses cached project)
- `M.watch(last)` - Start dotnet watch (last=true uses cached project)  
- `M.bootstrap()` - Interactive code generation for classes/controllers
- `M.nuget_auth()` - Authenticate configured NuGet sources
- `M.restart_watch()` - Restart the watch process
- `M.shutdown_watch()` - Kill running watch processes
- `M.setup(config)` - Configure plugin with user settings

### Configuration System
- Configuration is managed centrally by `config_manager.lua`
- State (last used csproj, running jobs) is managed separately from user configuration
- Access config via `config_manager.get_*_config()` functions
- Access state via `config_manager.get_*()` and `config_manager.set_*()` functions

### Task System
- **NEW**: Full task workflow system with pre-debug execution support
- Task configuration files: `.nvim/tasks.{json,yaml,toml}` or `.vscode/tasks.{json,yaml,toml}`
- Multi-format support: JSON, YAML, and TOML configurations
- Dependency resolution with array-based task dependencies
- DAP integration: automatic pre-debug task execution
- Commands: `:DotnvimTaskRun`, `:DotnvimTaskStatus`, `:DotnvimTaskCancel`, `:DotnvimTaskInit`

## Configuration Structure

```lua
{
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
  nuget = {
    sources = {},
    authenticators = {
      {
        cmd = "",
        args = {}
      }
    }
  },
  tasks = {
    enabled = true,
    execution_mode = "dependency_aware",  -- "sequential", "dependency_aware"
    dap_integration = {
      enabled = true,
      pre_debug_tasks = nil,  -- Auto-discover or specify: {"pre-debug", "build"}
      block_on_failure = true,
      timeout_seconds = 300,
    }
  }
}
```

## Task Configuration Examples

### JSON Format (`.nvim/tasks.json`)
```json
{
  "version": "0.1.0",
  "tasks": [
    {
      "name": "restore",
      "command": "dotnet restore",
      "cwd": ".",
      "env": {"DOTNET_NOLOGO": "true"}
    },
    {
      "name": "build",
      "previous": ["restore"],
      "command": "dotnet build --no-restore",
      "cwd": ".",
      "env": {"DOTNET_NOLOGO": "true"}
    },
    {
      "name": "test",
      "previous": ["build"],
      "command": "dotnet test --no-build",
      "cwd": ".",
      "env": {"ASPNETCORE_ENVIRONMENT": "Test"}
    },
    {
      "name": "pre-debug",
      "previous": ["build"],
      "command": "echo 'Ready for debugging'",
      "cwd": "."
    }
  ]
}
```

### YAML Format (`.nvim/tasks.yaml`)
```yaml
version: "0.1.0"
tasks:
  - name: restore
    command: dotnet restore
    cwd: .
    env:
      DOTNET_NOLOGO: "true"
  
  - name: build
    previous: [restore]
    command: dotnet build --no-restore
    cwd: .
    env:
      DOTNET_NOLOGO: "true"
  
  - name: pre-debug
    previous: [build]
    command: echo 'Ready for debugging'
    cwd: .
```

## Health Check

Run `:checkhealth dotnvim` to verify all dependencies are correctly installed. The health check validates:
- Required executables (`dotnet`, `fd`, `netcoredbg`)
- Required plugins (`plenary`, `nvim-treesitter`)
- Optional plugins (`telescope`, `nui.nvim`)

## Development Notes

- Uses `plenary.job` for async dotnet command execution
- Output buffers are created with timestamps for build/watch logs
- Process management uses `pgrep` to find and kill dotnet processes
- Supports both Telescope and vim.ui.select for project selection
- DAP configurations can be loaded from `.vscode/launch.json` or plugin config
- Log file location: `vim.fn.stdpath('data') .. '/dotnvim.log'`