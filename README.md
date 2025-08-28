<a href="https://dotfyle.com/plugins/adamkali/dotnvim">
	<img src="https://dotfyle.com/plugins/adamkali/dotnvim/shield?style=for-the-badge" />
</a>
<div align="center"><img src="https://github.com/adamkali/dotnvim/blob/main/assets/DotNvim.png" height="256" width="256" ></div>

# dotnvim (Unstable)

## Introduction

**dotnvim** is the .NET tooling for Neovim that you've always wanted. .NET development in Neovim can be challenging due to the lack of robust tooling, especially compared to the support available for other languages like Rust with [rustaceanvim](https://github.com/mrcjkb/rustaceanvim), and of course the ide that shall not be named. This plugin aims to fill that gap, providing a seamless development experience for .NET developers who prefer Neovim. Enjoy!

If you like what `dotnvim` is doing here, want to see more, or just not ready to add it to your config: please leave a star, it means the world. 

If you would like to try out the plugin in a containerized way, go ahead and check out [dotnvim-config](https://github.com/adamkali/dotnvim-config) to try out the plugin. And while you are there, give it a star as well ;)

## Table of Contents

- [Features](#features)
- [Sample Config](#sample-config)
- [Task System](#task-system)
- [Required Executables](#required-executables)
- [Neovim Plugin Dependencies](#neovim-plugin-dependencies)
- [Neovim Plugin Optional Dependencies](#neovim-plugin-optional-dependencies)
- [Credits](#credits)

## Sample Config

### Basic Lazy.nvim Configuration

```lua
return {
    {
        'adamkali/dotnvim',
        ft = { 'cs', 'vb', 'csproj', 'sln', 'slnx', 'props', 'csx', 'targets' },
        keys = {
            { '<leader>ds', function() require('dotnvim').bootstrap() end, desc = 'Bootstrap Class' },
            { '<leader>db', function() require('dotnvim').build(true) end, desc = 'Build Last Project' },
            { '<leader>dw', function() require('dotnvim').watch(true) end, desc = 'Watch Last Project' },
            { '<F10>', function() require('dotnvim').restart_watch() end, desc = 'Restart Watch Job'},
            { '<F34>', function() require('dotnvim').shutdown_watch() end, desc = 'Shutdown Watch Job'},
            { '<leader>dna', function() require('dotnvim').nuget_auth() end, desc = 'Authenticate Nuget Sources' },
            { '<leader>dt', ':DotnvimTaskRun<CR>', desc = 'Run Task' }
        },
        opts = {
            -- Builder configuration
            builders = {
                build_output_callback = nil,
                https_launch_setting_always = true,
            },
            -- UI configuration
            ui = {
                no_pretty_uis = false,
            },
            -- DAP (debugging) configuration
            dap = {
                adapter = {
                    type = 'executable',
                    command = "netcoredbg",
                    args = { '--interpreter=vscode' },
                },
                configurations = {}, -- Optional: add custom DAP configurations here
            },
            -- NuGet authentication
            nuget = {
                sources = {
                    "your-nuget-source-name"
                },
                authenticators = {
                    {
                        cmd = "aws",
                        args = { "codeartifact", "login", "--tool", "dotnet", "--domain", "YOUR_LIB", "--domain-owner", "AWSID", "--repository", "YOUR_REPO" }
                    },
                    -- Add more authenticators as needed
                },
            },
            -- Task system configuration
            tasks = {
                enabled = true,
                execution_mode = "dependency_aware", -- "sequential" or "dependency_aware"
                dap_integration = {
                    enabled = true,
                    pre_debug_tasks = nil, -- Auto-discover or specify: {"pre-debug", "build"}
                    block_on_failure = true,
                    timeout_seconds = 300,
                }
            },
            debug = {
                enabled = true,  -- Enable comprehensive debug logging
                log_file_path = nil,  -- Optional: custom log file path (defaults to ~/.local/share/nvim/dotnvim.log)
            }
        }
    },
}
```

### Alternative Configuration (using config function)

If you prefer the traditional approach or need more complex setup logic:

```lua
return {
    {
        'adamkali/dotnvim',
        ft = { 'cs', 'vb', 'csproj', 'sln', 'slnx', 'props', 'csx', 'targets' },
        keys = {
            { '<leader>ds', function() require('dotnvim').bootstrap() end, desc = 'Bootstrap Class' },
            { '<leader>db', function() require('dotnvim').build(true) end, desc = 'Build Last Project' },
            { '<leader>dw', function() require('dotnvim').watch(true) end, desc = 'Watch Last Project' },
            { '<F10>', function() require('dotnvim').restart_watch() end, desc = 'Restart Watch Job'},
            { '<F34>', function() require('dotnvim').shutdown_watch() end, desc = 'Shutdown Watch Job'},
            { '<leader>dna', function() require('dotnvim').nuget_auth() end, desc = 'Authenticate Nuget Sources' },
            { '<leader>dt', ':DotnvimTaskRun<CR>', desc = 'Run Task' }
        },
        config = function(_, opts)
            require('dotnvim').setup(opts)
        end,
        opts = {
            -- Same configuration options as above
            nuget = {
                sources = { "your-nuget-source-name" },
                authenticators = {
                    {
                        cmd = "aws",
                        args = { "codeartifact", "login", "--tool", "dotnet", "--domain", "YOUR_LIB", "--domain-owner", "AWSID", "--repository", "YOUR_REPO" }
                    },
                },
            },
            tasks = {
                enabled = true,
                execution_mode = "dependency_aware",
                dap_integration = {
                    enabled = true,
                    pre_debug_tasks = {"pre-debug", "build"},
                    block_on_failure = true,
                    timeout_seconds = 300,
                }
            }
        }
    },
}
```

## Configuration Reference

All configuration options can be passed through the `opts` table in Lazy.nvim. Here's a complete reference:

### Configuration Structure

```lua
opts = {
    -- Builder configuration
    builders = {
        build_output_callback = function(output) end, -- Optional callback for build output
        https_launch_setting_always = true,          -- Always use HTTPS in launch settings
    },
    
    -- UI configuration
    ui = {
        no_pretty_uis = false, -- Disable fancy UI components (falls back to vim.ui.select)
    },
    
    -- DAP (Debug Adapter Protocol) configuration
    dap = {
        adapter = {
            type = 'executable',        -- DAP adapter type
            command = "netcoredbg",     -- Path to netcoredbg
            args = { '--interpreter=vscode' }, -- Arguments for the debugger
        },
        configurations = {}, -- Optional: Custom DAP configurations (alternative to .vscode/launch.json)
    },
    
    -- NuGet package source authentication
    nuget = {
        sources = {               -- List of NuGet source names to authenticate
            "your-source-name",
        },
        authenticators = {        -- Authentication commands for each source
            {
                cmd = "aws",      -- Command to run
                args = {          -- Arguments for the command
                    "codeartifact", "login", "--tool", "dotnet",
                    "--domain", "YOUR_DOMAIN",
                    "--domain-owner", "YOUR_AWS_ACCOUNT_ID",
                    "--repository", "YOUR_REPO"
                }
            },
            {
                cmd = "dotnet",
                args = { "nuget", "setapikey", "your-api-key", "--source", "your-source" }
            }
        },
    },
    
    -- Task system configuration  
    tasks = {
        enabled = true,                    -- Enable/disable task system
        execution_mode = "dependency_aware", -- "sequential" or "dependency_aware"
        
        -- DAP integration for pre-debug tasks
        dap_integration = {
            enabled = true,                -- Enable automatic pre-debug task execution
            pre_debug_tasks = nil,         -- Specific tasks to run (nil = auto-discover)
            block_on_failure = true,       -- Block debugging if tasks fail
            timeout_seconds = 300,         -- Task execution timeout
        }
    },
    
    -- Debug logging configuration  
    debug = {
        enabled = false,                   -- Enable comprehensive debug logging
        log_file_path = nil,              -- Custom log file path (nil uses default: ~/.local/share/nvim/dotnvim.log)
    }
}
```

### Debug Logging

**dotnvim** includes comprehensive debug logging to help troubleshoot task execution issues:

- **Log file location**: `~/.local/share/nvim/dotnvim.log` (by default)
- **Automatic rotation**: Log files are rotated when they exceed 10MB
- **Debug mode**: When enabled, logs detailed information about:
  - DAP hook execution and state changes
  - Task discovery and parsing
  - Task execution flow and callbacks
  - State management and cleanup

#### Viewing Logs

Use the `:DotnvimLog` command to open the log file, or view it directly:

```bash
tail -f ~/.local/share/nvim/dotnvim.log
```

### Lazy.nvim Auto-Setup

**dotnvim** fully supports Lazy.nvim's automatic setup mechanism. When you provide `opts`, Lazy.nvim automatically calls `require('dotnvim').setup(opts)` for you. This means the basic configuration example above will work without any additional `config` function.

### When to Use `config` Function

You only need a custom `config` function if you need:
- Complex setup logic
- Conditional configuration
- Integration with other plugins that must be loaded first
- Custom initialization that goes beyond the standard `setup(opts)` pattern

## Task System

**dotnvim** includes a powerful task system that allows you to define and execute custom build workflows with dependency resolution and DAP integration. Tasks can be configured in multiple formats and automatically run before debugging sessions.

### Task Configuration

Tasks are configured in project files located in either `.nvim/` or `.vscode/` directory:

- `.nvim/tasks.json`, `.nvim/tasks.yaml`, `.nvim/tasks.toml`
- `.vscode/tasks.json`, `.vscode/tasks.yaml`, `.vscode/tasks.toml`

The plugin searches `.nvim/` first, then falls back to `.vscode/` for compatibility.

#### JSON Format Example (`.nvim/tasks.json`)

```json
{
  "version": "0.1.0",
  "tasks": [
    {
      "name": "restore",
      "command": "dotnet restore ${workspaceFolder}",
      "cwd": "${workspaceFolder}",
      "env": {"DOTNET_NOLOGO": "true"}
    },
    {
      "name": "build",
      "previous": ["restore"],
      "command": "dotnet build ${workspaceFolder} --no-restore",
      "cwd": "${workspaceFolder}",
      "env": {
        "DOTNET_NOLOGO": "true",
        "PROJECT_ROOT": "${workspaceFolder}"
      }
    },
    {
      "name": "test",
      "previous": ["build"],
      "command": "dotnet test ${workspaceFolder} --no-build",
      "cwd": "${workspaceFolder}",
      "env": {
        "ASPNETCORE_ENVIRONMENT": "Test",
        "TEST_OUTPUT": "${workspaceFolder}/TestResults"
      }
    },
    {
      "name": "pre-debug",
      "previous": ["build"],
      "command": "echo 'Ready for debugging ${workspaceFolderBasename}'",
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

#### YAML Format Example (`.nvim/tasks.yaml`)

```yaml
version: "0.1.0"
tasks:
  - name: restore
    command: dotnet restore ${workspaceFolder}
    cwd: ${workspaceFolder}
    env:
      DOTNET_NOLOGO: "true"
  
  - name: build
    previous: [restore]
    command: dotnet build ${workspaceFolder} --no-restore
    cwd: ${workspaceFolder}
    env:
      DOTNET_NOLOGO: "true"
      PROJECT_ROOT: ${workspaceFolder}
  
  - name: pre-debug
    previous: [build]
    command: echo 'Ready for debugging ${workspaceFolderBasename}'
    cwd: ${workspaceFolder}
```

#### TOML Format Example (`.nvim/tasks.toml`)

```toml
version = "0.1.0"

[[tasks]]
name = "restore"
command = "dotnet restore ${workspaceFolder}"
cwd = "${workspaceFolder}"

[tasks.env]
DOTNET_NOLOGO = "true"

[[tasks]]
name = "build"
previous = ["restore"]
command = "dotnet build ${workspaceFolder} --no-restore"
cwd = "${workspaceFolder}"

[tasks.env]
DOTNET_NOLOGO = "true"
PROJECT_ROOT = "${workspaceFolder}"

[[tasks]]
name = "pre-debug"
previous = ["build"]
command = "echo 'Ready for debugging ${workspaceFolderBasename}'"
cwd = "${workspaceFolder}"
```

### Task Properties

- **name**: Unique task identifier
- **command**: Shell command to execute (supports variable substitution)
- **cwd**: Working directory (supports variable substitution)
- **env**: Environment variables (optional, supports variable substitution)
- **previous**: Array of task dependencies (optional)

### Variable Substitution

**dotnvim** supports VSCode-style variable substitution in task configurations. Variables are enclosed in `${variableName}` format and are resolved at runtime.

#### Supported Variables

- `${workspaceFolder}` - Root directory of the workspace/project
- `${workspaceFolderBasename}` - Name of the workspace folder
- `${file}` - Currently open file (absolute path)
- `${relativeFile}` - Currently open file relative to workspace
- `${relativeFileDirname}` - Directory of currently open file relative to workspace
- `${fileBasename}` - Basename of currently open file
- `${fileBasenameNoExtension}` - Basename without extension
- `${fileDirname}` - Directory of currently open file
- `${fileExtname}` - Extension of currently open file
- `${cwd}` - Current working directory
- `${pathSeparator}` - Path separator for the current OS

#### Variable Examples

```json
{
  "version": "0.1.0",
  "tasks": [
    {
      "name": "build-project",
      "command": "dotnet build ${workspaceFolder}/MyProject.csproj",
      "cwd": "${workspaceFolder}",
      "env": {
        "PROJECT_ROOT": "${workspaceFolder}",
        "OUTPUT_PATH": "${workspaceFolder}/bin/Debug"
      }
    },
    {
      "name": "test-current",
      "command": "dotnet test ${fileDirname}/${fileBasenameNoExtension}.Tests.csproj",
      "cwd": "${fileDirname}",
      "env": {
        "TEST_FILE": "${file}"
      }
    }
  ]
}
```

### User Commands

**dotnvim** provides several commands for task management:

- `:DotnvimTaskRun [task_name]` - Run a specific task or select from available tasks
- `:DotnvimTaskStatus` - Show task system status and configuration
- `:DotnvimTaskCancel` - Cancel running tasks
- `:DotnvimTaskInit [format]` - Initialize example task configuration (json, yaml, toml)

### Task Execution Modes

- **dependency_aware** (default): Resolves and executes task dependencies automatically
- **sequential**: Executes tasks in the order specified

### DAP Integration

The task system integrates seamlessly with `nvim-dap` for pre-debug task execution:

- Automatically discovers and runs `pre-debug`, `debug-prep`, `prepare-debug`, or `before-debug` tasks
- Configurable timeout and failure handling
- Synchronous execution to ensure tasks complete before debugging starts

#### DAP Integration Configuration

Configure DAP integration through the `opts.tasks.dap_integration` section:

```lua
-- In your Lazy.nvim configuration
opts = {
    tasks = {
        dap_integration = {
            enabled = true,                    -- Enable DAP integration
            pre_debug_tasks = {"pre-debug"},   -- Specific tasks to run (or nil for auto-discovery)
            block_on_failure = true,           -- Block debugging if tasks fail
            timeout_seconds = 300,             -- Task timeout in seconds
        }
    }
}
```

### Task Management API

For programmatic access:

```lua
local dotnvim = require('dotnvim')

-- Run a single task
dotnvim.run_task("build")

-- Run multiple tasks
dotnvim.run_tasks({"restore", "build"})

-- Check task status
local status = dotnvim.task_status()

-- Get available tasks
local tasks = dotnvim.get_available_tasks()

-- Cancel running tasks
dotnvim.cancel_tasks()

-- Create example configuration
dotnvim.create_task_config("json") -- or "yaml", "toml"
```

### Example Workflow

1. Create task configuration: `:DotnvimTaskInit json`
2. Edit the generated `.nvim/tasks.json` file
3. Run tasks: `:DotnvimTaskRun` or `<leader>dt`
4. Debug with automatic pre-debug tasks via DAP integration

## Features

### Core Development Tools

#### `require('dotnvim').bootstrap()`
Interactive code scaffolding for .NET projects with support for:

**C# Model Generation**
- Bootstraps a Model with default getter and setter properties
- Supports custom namespaces and inheritance

**ASP.NET API Controllers**
- Basic MVC controller scaffolding 
- Full CRUD controller generation with:
  - GET (single and all)
  - POST (create)
  - PUT (update)
  - DELETE operations

#### `require('dotnvim').build(last)` 
Project compilation with intelligent project selection:
- Builds projects from solution root (where .sln exists)
- `last = true` uses previously selected project
- Interactive project selection via Telescope or vim.ui.select

#### `require('dotnvim').watch(last)`
Hot reload development server:
- Starts `dotnet watch` process on selected project
- Persistent process management with restart capabilities
- Output logging to dedicated buffer

#### `require('dotnvim').nuget_auth()`
Multi-source NuGet authentication:
- Configurable authentication commands per source
- Support for AWS CodeArtifact, Azure DevOps, and private feeds
- Batch authentication for multiple sources

### Task System

**dotnvim** provides a comprehensive task execution system with dependency resolution and DAP integration:

#### Core Task Functions
- `require('dotnvim').run_task(task_name)` - Execute specific task
- `require('dotnvim').run_tasks(task_names)` - Execute multiple tasks
- `require('dotnvim').get_available_tasks()` - List configured tasks
- `require('dotnvim').task_status()` - Get execution status
- `require('dotnvim').cancel_tasks()` - Stop running tasks
- `require('dotnvim').create_task_config(format)` - Initialize task configuration

#### Task Configuration Support
- **Multiple formats**: JSON, YAML, TOML
- **Variable substitution**: VSCode-style `${workspaceFolder}` variables  
- **Dependency resolution**: Automatic task ordering with `previous` array
- **Environment variables**: Per-task environment configuration
- **Custom working directories**: Task-specific `cwd` settings

#### DAP Integration Features
- **Pre-debug task execution**: Automatic task running before debug sessions
- **Configurable timeout**: Task execution limits with failure handling
- **Block on failure**: Optional debug session blocking for failed tasks
- **Auto-discovery**: Automatic detection of `pre-debug`, `debug-prep` tasks

### Debug Support 

Enhanced debugging experience with nvim-dap integration:

#### Configuration Sources
- `.vscode/launch.json` compatibility
- Plugin-based DAP configurations
- Automatic adapter setup for netcoredbg

#### Pre-Debug Task Execution
```lua
-- Automatic execution before debugging
{
  tasks = {
    dap_integration = {
      enabled = true,
      pre_debug_tasks = {"build", "pre-debug"}, -- or nil for auto-discovery
      block_on_failure = true,
      timeout_seconds = 300
    }
  }
}
```

#### Example Launch Configuration
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": ".NET Core Launch (web)",
            "type": "coreclr",
            "request": "launch",
            "preLaunchTask": "build",
            "program": "${workspaceFolder}/MyApp/bin/Debug/net8.0/MyApp.dll",
            "env": {
                "ASPNETCORE_ENVIRONMENT": "Development",
                "ASPNETCORE_URLS": "https://localhost:5001;http://localhost:5000"
            }
        }
    ]
}
```

### Process Management

#### Watch Process Control
- `require('dotnvim').restart_watch()` - Restart development server
- `require('dotnvim').shutdown_watch()` - Clean process termination
- Background PID tracking and cleanup

#### Project State Management  
- `require('dotnvim').query_last_ran_csproj()` - Get last used project
- Persistent project selection across sessions
- Smart project root detection

### User Commands

**dotnvim** provides several Neovim commands for easy access:

- `:DotnvimTaskRun [task_name]` - Run a task (with autocomplete)
- `:DotnvimTaskStatus` - Show task system status in dedicated buffer  
- `:DotnvimTaskCancel` - Cancel currently running tasks
- `:DotnvimTaskInit [format]` - Create example task configuration (json/yaml/toml)
- `:DotnvimNugetAuth` - Authenticate NuGet sources
- `:DotnvimLog` - Open the plugin log file for troubleshooting

### Configuration Management

#### Runtime Configuration
- `require('dotnvim').show_config()` - Display current configuration
- `require('dotnvim').show_config_section(section)` - Show specific config section
- Centralized configuration management with validation
- State persistence across Neovim sessions

#### Logging and Debugging
- Comprehensive debug logging to `~/.local/share/nvim/dotnvim.log`
- Configurable log levels and file rotation
- Real-time task execution monitoring
- DAP hook state tracking

## Required Executables

### Essential Dependencies
- `dotnet` - .NET CLI (required for all functionality)
- `fd` - File finder utility (required for project discovery)

### Optional Dependencies  
- `netcoredbg` - .NET Core debugger (required for debugging support)

> [!NOTE]
> NuGet authentication uses the `dotnet` CLI internally, so no separate `nuget` executable is required.

## Neovim Plugin Dependencies

- `plenary`
- `nvim-treesitter`

### Required for Debugging
- `nvim-dap`

## Neovim Plugin Optional Dependencies

- `telescope`
- `nui.nvim`

## Contributing 
Thank you! please see [CONTRIBUTING](https://github.com/adamkali/dotnvim/blob/main/CONTRIBUTING.md) and check out the [Issues](https://github.com/adamkali/dotnvim/issues)

## Full Configuration Reference

Here's a complete configuration example showing all available options with their default values and detailed explanations:

```lua
{
    'adamkali/dotnvim',
    ft = { 'cs', 'vb', 'csproj', 'sln', 'slnx', 'props', 'csx', 'targets' },
    keys = {
        -- Core functionality
        { '<leader>ds', function() require('dotnvim').bootstrap() end, desc = 'Bootstrap Class' },
        { '<leader>db', function() require('dotnvim').build(true) end, desc = 'Build Last Project' },
        { '<leader>dw', function() require('dotnvim').watch(true) end, desc = 'Watch Last Project' },
        
        -- Process management
        { '<F10>', function() require('dotnvim').restart_watch() end, desc = 'Restart Watch Job'},
        { '<F34>', function() require('dotnvim').shutdown_watch() end, desc = 'Shutdown Watch Job'},
        
        -- NuGet authentication
        { '<leader>dna', function() require('dotnvim').nuget_auth() end, desc = 'Authenticate Nuget Sources' },
        
        -- Task system
        { '<leader>dt', ':DotnvimTaskRun<CR>', desc = 'Run Task' },
        { '<leader>dts', ':DotnvimTaskStatus<CR>', desc = 'Task Status' },
        { '<leader>dtc', ':DotnvimTaskCancel<CR>', desc = 'Cancel Tasks' },
        { '<leader>dti', ':DotnvimTaskInit<CR>', desc = 'Initialize Tasks' },
        
        -- Configuration and debugging
        { '<leader>dc', function() require('dotnvim').show_config() end, desc = 'Show Configuration' },
        { '<leader>dl', ':DotnvimLog<CR>', desc = 'Open Log File' },
        { '<leader>dh', ':checkhealth dotnvim<CR>', desc = 'Health Check' },
    },
    opts = {
        -- ============================================================================
        -- BUILDER CONFIGURATION
        -- ============================================================================
        builders = {
            -- Optional callback function that receives build output
            -- Useful for custom parsing or notifications
            build_output_callback = function(output)
                -- Example: Parse and show warnings/errors in quickfix
                -- vim.fn.setqflist({}, 'r', { title = 'Build Output', lines = output })
            end,
            
            -- Always use HTTPS in ASP.NET launch settings generation
            -- When false, uses both HTTP and HTTPS endpoints
            https_launch_setting_always = true,
        },
        
        -- ============================================================================
        -- UI CONFIGURATION
        -- ============================================================================
        ui = {
            -- Disable fancy UI components (Telescope, NUI)
            -- Falls back to vim.ui.select for all selections
            no_pretty_uis = false,
        },
        
        -- ============================================================================
        -- DEBUG ADAPTER PROTOCOL (DAP) CONFIGURATION
        -- ============================================================================
        dap = {
            -- netcoredbg adapter configuration
            adapter = {
                type = 'executable',
                command = "netcoredbg",  -- Must be in PATH or provide full path
                args = { '--interpreter=vscode' },
            },
            
            -- Optional: Custom DAP configurations
            -- Alternative to .vscode/launch.json
            configurations = {
                {
                    type = "coreclr",
                    name = "Launch Console App",
                    request = "launch",
                    program = function()
                        -- Dynamic program selection
                        return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
                    end,
                    cwd = "${workspaceFolder}",
                    stopAtEntry = false,
                    env = {
                        ASPNETCORE_ENVIRONMENT = "Development"
                    }
                },
                {
                    type = "coreclr",
                    name = "Launch Web App",
                    request = "launch",
                    program = "${workspaceFolder}/MyWebApp/bin/Debug/net8.0/MyWebApp.dll",
                    cwd = "${workspaceFolder}/MyWebApp",
                    stopAtEntry = false,
                    env = {
                        ASPNETCORE_ENVIRONMENT = "Development",
                        ASPNETCORE_URLS = "https://localhost:5001;http://localhost:5000"
                    },
                    -- Optional: browser launch
                    serverReadyAction = {
                        action = "openExternally",
                        pattern = "\\bNow listening on:\\s+(https?://\\S+)"
                    }
                }
            }
        },
        
        -- ============================================================================
        -- NUGET AUTHENTICATION
        -- ============================================================================
        nuget = {
            -- List of NuGet source names to authenticate
            -- These should match the names in your nuget.config
            sources = {
                "MyCompanyFeed",
                "AzureDevOps",
                "AWSCodeArtifact"
            },
            
            -- Authentication commands for each source
            -- Commands are executed in order for each source
            authenticators = {
                -- AWS CodeArtifact example
                {
                    cmd = "aws",
                    args = { 
                        "codeartifact", "login", 
                        "--tool", "dotnet",
                        "--domain", "my-domain",
                        "--domain-owner", "123456789012",
                        "--repository", "my-repo",
                        "--region", "us-east-1"
                    }
                },
                
                -- Azure DevOps example
                {
                    cmd = "az",
                    args = {
                        "artifacts", "universal", "download",
                        "--organization", "https://dev.azure.com/myorg/",
                        "--feed", "my-feed",
                        "--name", "auth-token",
                        "--version", "*",
                        "--path", "/tmp/"
                    }
                },
                
                -- Simple API key example
                {
                    cmd = "dotnet",
                    args = {
                        "nuget", "setapikey",
                        "${NUGET_API_KEY}",  -- Environment variable
                        "--source", "MyPrivateFeed"
                    }
                },
                
                -- Custom authentication script
                {
                    cmd = "/path/to/custom-auth-script.sh",
                    args = { "MyCompanyFeed" }
                }
            },
        },
        
        -- ============================================================================
        -- TASK SYSTEM CONFIGURATION
        -- ============================================================================
        tasks = {
            -- Enable/disable the entire task system
            enabled = true,
            
            -- Task execution mode:
            -- "sequential": Execute tasks in specified order
            -- "dependency_aware": Resolve and execute dependencies automatically
            execution_mode = "dependency_aware",
            
            -- DAP integration for pre-debug tasks
            dap_integration = {
                -- Enable automatic pre-debug task execution
                enabled = true,
                
                -- Specific tasks to run before debugging
                -- nil = auto-discover tasks named: pre-debug, debug-prep, prepare-debug, before-debug
                -- array = specific task names to execute
                pre_debug_tasks = nil,  -- or {"restore", "build", "pre-debug"}
                
                -- Block debugging if pre-debug tasks fail
                block_on_failure = true,
                
                -- Maximum time to wait for tasks to complete (seconds)
                timeout_seconds = 300,
            }
        },
        
        -- ============================================================================
        -- DEBUG LOGGING
        -- ============================================================================
        debug = {
            -- Enable comprehensive debug logging
            -- Logs detailed information about task execution, DAP hooks, etc.
            enabled = false,  -- Set to true for troubleshooting
            
            -- Custom log file path
            -- nil = use default: ~/.local/share/nvim/dotnvim.log
            log_file_path = nil,  -- or "/path/to/custom/dotnvim.log"
        },
        
        -- ============================================================================
        -- HEALTH CHECK CONFIGURATION
        -- ============================================================================
        health = {
            -- Custom executable paths (if not in PATH)
            executables = {
                dotnet = "dotnet",  -- or "/usr/local/share/dotnet/dotnet"
                fd = "fd",          -- or "/usr/local/bin/fd"
                netcoredbg = "netcoredbg",  -- or "/path/to/netcoredbg"
            }
        }
    }
}
```

### Environment Variables

**dotnvim** respects several environment variables for configuration:

```bash
# NuGet authentication
export NUGET_API_KEY="your-api-key-here"
export AZURE_DEVOPS_EXT_PAT="your-pat-token"

# AWS CodeArtifact
export AWS_PROFILE="your-aws-profile"
export AWS_REGION="us-east-1"

# Custom executable paths
export DOTNET_ROOT="/usr/local/share/dotnet"
export NETCOREDBG_PATH="/path/to/netcoredbg"

# Task system
export DOTNVIM_TASK_TIMEOUT="600"  # seconds
export DOTNVIM_LOG_LEVEL="debug"   # error, warn, info, debug

# Development
export DOTNVIM_DEBUG="1"           # Enable debug mode
```

### Minimal Configuration

If you want the simplest possible setup:

```lua
{
    'adamkali/dotnvim',
    ft = { 'cs', 'csproj', 'sln' },
    keys = {
        { '<leader>db', function() require('dotnvim').build() end },
        { '<leader>dw', function() require('dotnvim').watch() end },
    },
    opts = {} -- Use all defaults
}
```

This minimal setup provides core build and watch functionality with sensible defaults.

## Credits
- **[MoaidHathot](https://github.com/MoaidHathot/dotnet.nvim)**: Inspiration for this project.
- [nvim-dap-go](https://github.com/leoluz/nvim-dap-go) For debugging bootstraps.
- **[tjdvrees](https://github.com/nvim-telescope/telescope.nvim)**: __telescope__ 🔭
- **[folke](https://github.com/folke)**: Code inspiration for... well everything!
- **[nui.nvim](https://github.com/MunifTanjim/nui.nvim)**: For excellent UI components.
- **Simba**: My cat, for moral support. 🐱

