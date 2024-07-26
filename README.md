## Table of Contents
- [Required](#required)

## Sample Config
```lua 
local dotnet_opts = {
    mode = "n",     -- NORMAL mode
    silent = true,  -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = false, -- use `nowait` when creating keymaps
    expr = true,    -- use `expr` when creating keymaps
}

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
            { '=ds', dotnet_bootstrap, desc = ' Bootstrap Class' },
            { '=db', dotnet_build, desc = ' Build Project' },
            { '=dB', dotnet_build_last, desc = ' Build Last Project' },
        },
    },
}
```

## Required Executables
- fd
- dotnet

## Neovim Plugin Dependencies
- plenary
- nvim-treesitter

## Neovim Plugin Optional Dependencies
- telescope 
- nui.nvim

## Credit 
- [MoaidHathot](https://github.com/MoaidHathot/dotnet.nvim) for the tick of wanting to make my .net development without visual studio better
- [dap-go]() Debugging bootstrap :)
- [tjdvrees]() Lua best practices
- [folke]() I stole alot of theirs code too but i am just a little guy 🥺
- [Simba]() My cat :3
- [nui](https://github.com/MunifTanjim/nui.nvim) so much good stuff here :)

