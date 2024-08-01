<a href="https://dotfyle.com/plugins/adamkali/dotnvim">
	<img src="https://dotfyle.com/plugins/adamkali/dotnvim/shield?style=for-the-badge" />
</a>

# dotnvim (Unstable)

<a href="url"><img src="https://github.com/adamkali/dotnvim/blob/main/assets/DotNvim.png" height="128" width="128" ></a>


## Introduction

**dotnvim** is the .NET tooling for Neovim that you've always wanted. .NET development in Neovim can be challenging due to the lack of robust tooling, especially compared to the support available for other languages like Rust with [rustaceanvim](https://github.com/mrcjkb/rustaceanvim), and of course the ide that shall not be named. This plugin aims to fill that gap, providing a seamless development experience for .NET developers who prefer Neovim. Enjoy!

If you like what `dotnvim` is doing here, want to see more, or just not ready to add it to your config: please leave a star, it means the world. 

If you would like to try out the plugin in a containerized way, go ahead and check out (dotnvim-config)[https://github.com/adamkali/dotnvim-config] to try out the plugin. And while you are there, give it a star as well ;)

## Table of Contents

- [Features](#features)
- [Sample Config](#sample-config)
- [Required Executables](#required-executables)
- [Neovim Plugin Dependencies](#neovim-plugin-dependencies)
- [Neovim Plugin Optional Dependencies](#neovim-plugin-optional-dependencies)
- [Credits](#credits)

## Sample Config

```lua
local function dotnet_bootstrap()
    local dotnet = require 'dotnvim'
    dotnet.bootstrap()
end

local function dotnet_build_last()
    local dotnet = require 'dotnvim'
    dotnet.build(true)
end

local function dotnet_watch_last()
    local dotnet = require('dotnvim')
    dotnet.watch(true)
end

local function dotnet_restart_watch()
    local dotnet = require('dotnvim')
    dotnet.restart_watch()
end

local function dotnet_shutdown_watch()
    local dotnet = require('dotnvim')
    dotnet.shutdown_watch()
end

return {
    {
        dir = 'adamkali/dotnvim',
        ft = { 'cs', 'vb', 'csproj', 'sln', 'slnx', 'props', 'csx', 'targets' },
        keys = {
            { '<leader>ds', dotnet_bootstrap, desc = 'Bootstrap Class' },
            { '<leader>db', dotnet_build_last, desc = 'Build Last Project' },
            { '<leader>dw', dotnet_watch_last, desc = 'Watch Last Project' },
            { '<F10>', dotnet_restart_watch, desc = 'Restart Watch Job'},
            { '<F34>', dotnet_shutdown_watch, desc = 'Shutdown Watch Job'}
        },
        opts = {
            builders = {
                -- will append -lp https always.
                -- 
                https_launch_setting_always = true,
            },
            ui = {
                no_pretty_uis = false
            },
            dap = {
		configurations = {}
            }
        }
    },
}
```

## Features

### `require('dotnvim').bootstrap()`
bootstraps in the current namespace and directory, when given a class name. 

#### C# Model 
Bootstraps a Model with a default getter and setter.

#### ASP.NET API Controller
Bootstraps a MVC controller similar to the ~~VS~~.


#### ASP.NET API Controller With Read Write
Bootstraps a MVC controller with the CRUD methods 
- Get 
- Get All 
- Post 
- Put 
- Delete

### `require('dotnvim').build(last)`
Builds a project based on the Solution root. (i.e. where the .sln). The `last` parameter refers to if you have already built a project, and you pass in `true`, dotnvim will build the last used project as its solution.

### `require('dotnvim').watch(last)`
starts a watch process on the Solution root. (i.e. where the .sln).

- `last` if last is true the plugin will use the `.csproj` stored in requireDotnvim

### Dap support 
`dotnvim` has support for debugging based on `.vscode/launch.json` and the ability to add configurations in `require().setup({ dap.configuraitons = { <HERE> }}). Here is a good example of one:
```json
{
    "$schema": "https://raw.githubusercontent.com/mfussenegger/dapconfig-schema/master/dapconfig-schema.json",
    "version": "0.2.0",
    "configurations": [
                {
                        "name": ".NET Core Launch (web)",
                        "type": "coreclr",
                        "request": "launch",
                        "preLaunchTask": "build",
                        "program": "${workspaceFolder}/SimbasWeightLoss.API/bin/Debug/net6.0/SimbasWeightLoss.API.dll",
                        "args": [],
                        "cwd": "${workspaceFolder}/SimbasWeightLoss.API",
                        "stopAtEntry": false,
                        "serverReadyAction": {
                                "action": "openExternally",
                                "pattern": "\\bNow listening on:\\s+(https?://\\S+)"
                        },
                        "env": {
                                "ASPNETCORE_ENVIRONMENT": "Development"
                        },
                        "sourceFileMap": {
                                "/Views": "${workspaceFolder}/Views"
                        }
                }
        ]
}
```

Then use ure own dap configuration as usual!.

> [!WARNING]
> At the moment properly managing the pid state is borked. [see dotnet issue #20152](https://github.com/dotnet/aspnetcore/issues/20152). As a result, `dotnvim` will be tackling this in a new issue [#8](https://github.com/adamkali/dotnvim/issues/8).


## Required Executables

- `fd`
- `dotnet`

### Required for Debugging
- netcoredbg

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

## Credits

- **[MoaidHathot](https://github.com/MoaidHathot/dotnet.nvim)**: Inspiration for this project.
- **dap-go**: For debugging bootstraps. (Link needed)
- **[tjdvrees](https://github.com/nvim-telescope/telescope.nvim)**: __telescope__ 🔭
- **[folke](https://github.com/folke)**: Code inspiration for... well everything!
- **[nui.nvim](https://github.com/MunifTanjim/nui.nvim)**: For excellent UI components.
- **Simba**: My cat, for moral support. 🐱

