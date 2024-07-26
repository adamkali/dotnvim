# dotnvim (Unstable)

## Introduction

**dotnvim** is the .NET tooling for Neovim that you've always wanted. .NET development in Neovim can be challenging due to the lack of robust tooling, especially compared to the support available for other languages like Rust with [rustaceanvim](https://github.com/mrcjkb/rustaceanvim), and of course the ide that shall not be named. This plugin aims to fill that gap, providing a seamless development experience for .NET developers who prefer Neovim. Enjoy!

## Table of Contents

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

local function dotnet_build()
    local dotnet = require 'dotnvim'
    dotnet.build(false)
end

local function dotnet_build_last()
    local dotnet = require 'dotnvim'
    dotnet.build(true)
end

return {
    {
        'adamkali/dotnvim',
        ft = { 'cs', 'vb', 'csproj', 'sln', 'slnx', 'props', 'csx', 'targets' },
        keys = {
            { '=ds', dotnet_bootstrap, desc = 'Bootstrap Class' },
            { '=db', dotnet_build, desc = 'Build Project' },
            { '=dB', dotnet_build_last, desc = 'Build Last Project' },
        },
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

## Required Executables

- `fd`
- `dotnet`

## Neovim Plugin Dependencies

- `plenary`
- `nvim-treesitter`

## Neovim Plugin Optional Dependencies

- `telescope`
- `nui.nvim`

## Credits

- **[MoaidHathot](https://github.com/MoaidHathot/dotnet.nvim)**: Inspiration for improving .NET development in Neovim.
- **dap-go**: For debugging bootstraps. (Link needed)
- **tjdvrees**: Guidance on Lua best practices.
- **folke**: For code inspiration and snippets. (Link needed)
- **Simba**: My cat, for moral support. 🐱
- **[nui.nvim](https://github.com/MunifTanjim/nui.nvim)**: For excellent UI components.

