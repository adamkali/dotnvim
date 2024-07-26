local dotnvim_t = require "dotnvim.utils.templates"
local utils     = require "dotnvim.utils"
local function extract_directory(file_path)
    return file_path:match("(.*/)")
end
local M = {}

local default_out_space = {
    filename = "",
    filepath = "",
    buffer = ""
}

-- Use Telescope as a selector to run the bootstrapper
-- @param bootstrappers bootstrappers table to use
M.telescope_select_bootstrapper = function(bootstrappers)
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local previewers = require 'telescope.previewers'

    local opts = {}
    pickers.new(opts, {
        prompt_title = " Bootstrapper",
        finder = finders.new_table {
            results = bootstrappers,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.name,
                    ordinal = entry.search,
                }
            end
        },
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer {
            define_preview = function(self, entry, status)
                local bufnr = self.state.bufnr
                vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false,
                    vim.split(entry.value.callback("PREVIEW", "NAMESPACE"), "\n"))
                vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
                vim.api.nvim_buf_set_option(bufnr, 'filetype', 'cs')
            end
        },
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry().value
                print('selection: ' .. selection.name)
                vim.ui.input({ prompt = 'Class Name: ' }, function(input)
                    local out_space = default_out_space
                    if input then
                        out_space = selection.func(input, nil)
                        local extracted = extract_directory(out_space.filepath)
                        local plenary = require('plenary.path')
                        local path = plenary:new(extracted .. input .. '.cs')
                        path:write(out_space.buffer, 'w')
                        vim.cmd("edit " .. path.filename)
                    end
                end)
            end)
            return true
        end,
    }):find()
end

-- return
-- {
--     index = 0,
--     value = path/to/<any>.csproj
-- }
M.telescope_select_csproj = function(selections, callback)
    assert(#selections > 0, "No selections provided") -- Ensure there are selections

    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local result_idx = nil

    local opts = {}
    pickers.new(opts, {
        prompt_title = " Select a Project to Build",
        finder = finders.new_table {
            results = selections,
            entry_maker = function(entry)
                return {
                    value = entry.value,                            -- <-- -----------------\
                    display = entry.value,                          -- SAME THING            |
                    ordinal = entry.value,                          -- /--------------------/
                }                                                   -- |
            end                                                     -- |
        },                                                          -- |
        sorter = conf.generic_sorter(opts),                         -- |
        attach_mappings = function(prompt_bufnr, _map)              -- |
            actions.select_default:replace(function()               -- |
                local selection = action_state.get_selected_entry() -- |
                actions.close(prompt_bufnr)                         -- |
                callback(selection.value)                           
                --               ^\____________________________________/
            end)
            return true
        end,
    }):find()
end

return M
