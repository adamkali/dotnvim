local Utils = require('dotnvim.utils')
local generator = {}

--- @class generator.class_config
--- @field  use_filename_as_name boolean
--- @field  use_cwd_as_ns boolean
--- @field  use_public boolean
--- @field  use_private boolean
--- @field  use_protected boolean
--- @field  use_model_default boolean
--- @field  use_controller_default boolean

--- @class generator.Config
--- @field class_config generator.class_config


--- @type generator.Config
generator.Config = {
    class_config = {
        use_filename_as_name = true,
        use_cwd_as_ns = true,
        use_public = true,
        use_private = false,
        use_protected = false,
        use_model_default = false,
        use_controller_default = false
    }
}


---@param opts generator.class_config
generator.generate_class = function(opts)
    local current_buf = vim.api.nvim_get_current_buf()
    local file_obj = Utils.get_curr_file_and_namespace()
    local namespace = "DefaultNamespace"
    local classname = "DefaultController"
    local qf_list = {}
    if opts.use_cwd_as_ns then
        namespace = file_obj.namespace
    else
        qf_list.

    end
    if opts.use_filename_as_name then
        classname = file_obj.file_name
    end
    local transparency = function()
        if opts.use_public then
            return "public "
        elseif opts.use_protected then
            return "protected "
        elseif opts.use_private then
            return "private "
        end
    end
    local generated = require('dotnvim.generators.class_generator').generator(classname, namespace, {
        public = transparency(),
        model = opts.use_model_default,
        controller = opts.use_controller_default
    })
    local lines = vim.split(generated, "\n", nil)
    vim.api.nvim_buf_set_lines(current_buf, 1, #lines, false, lines)
end

---@param ots: table
generator.setup = function(opts)
    if opts.generate_class_config then
        for use_opt, value in pairs(opts.generate_class_config) do
            generator.Config.class_config[use_opt] = value
        end
    end
    vim.api.nvim_create_user_command("DotnvimGenerate", function(args, bang, nargs)
    end, {})
end
