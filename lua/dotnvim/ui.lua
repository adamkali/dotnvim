local Popup = require("nui.popup")
local Layout = require("nui.layout")
local Input = require("nui.input")
local dotnvim_utils = require("dotnvim.utils")
local NugetClient = require("dotnvim.nuget")
local UI = {}

UI.state = {}
UI.state.title_linenum = 1
UI.state.csproj_linenum = 1
UI.state.hl_ns = nil
UI.state.selected_package = {
    title = "",
    version = "",
}

function UI.state:reset()
    UI.state.title_linenum = 1
    UI.state.csproj_linenum = 1
    UI.state.hl_ns = nil
    UI.state.selected_package = {
        title = "",
        version = "",
    }
end

local event = require("nui.utils.autocmd").event

--- @param popup table from nui.popup use to get bufnr from the class
--- @param st number get the of the buffer
--- @param arr table the array of messags to pass to buffer stored in the popup
local function write(popup, st, arr)
    vim.api.nvim_buf_set_lines(popup.bufnr, st, -1, false, arr)
end

local function format_package_version(version)
    local pac_ver = version["version"] .. " Downloads: " .. string.format(version["downloads"])
    print(pac_ver or "No Pacages")
    return pac_ver
end

--#region Package Search and install
local packages_titles_popup,
packages_vers_popup,
package_description_popup = Popup({
        enter = true,
        border = {
            style = "single",
            text = {
                top = "(1) Nuget Packages",
                top_align = "center"
            }
        },
    }),
    Popup({
        border = {
            style = "single",
            text = {
                top = "(2) Available Package Versions",
                top_align = "center"
            }
        },
    }),
    Popup({
        border = {
            style = "single",
            text = {
                top = "Package Description",
                top_align = "center"
            }
        },
    })

local layout              = Layout({
        position = "50%",
        size = {
            width = "80%",
            height = "80%",
        },
    },
    Layout.Box({
        Layout.Box(packages_titles_popup, { size = "40%" }),
        Layout.Box({
            Layout.Box(packages_vers_popup, { size = "50%" }),
            Layout.Box(package_description_popup, { size = "50%" })
        }, { size = "60%", dir = "col" }),
    }, { dir = "row" })
)
--#endregion

--#region Nuget Package Search Input
local function _prompt_config()
    if vim.g.DotnvimConfig.ui.no_pretty_uis ~= false then
        return " "
    else
        return "? "
    end
end

local package_name_input = Input({
    position = "50%",
    size     = {
        width = 30,
    },
    border   = {
        style = "single",
        text = {
            top = "Search By Name",
            top_align = "center"
        },
    }
}, {
    prompt = _prompt_config(),
    default_value = "",
    on_submit = function(value)
        -- TODO: For now pass nil for sources
        -- We will then use a second window
        -- to select from
        -- $ dotnet nuget list source
        local results = NugetClient.search_package_by_source(value, nil, vim.g.DotnvimConfig.nuget.search.params)
        local titles = {}
        for _, result in ipairs(results) do
            table.insert(titles, result)
        end
        UI.NugetAddPackageUI()
        UI.NugetPackagesUi(titles)
        layout:show()
    end
})


--#endregion

--#region Csproj Install list
local csporj_popup           = Popup({
    enter = true,
    border = {
        style = "single",
        text = {
            top = "Csproj Under Root",
            top_align = "center",
            bottom = "(dd) to remove csproj form upgrade. (Enter) install to highlated projects.",
            bottom_alighn = "center"
        }
    },
})
local selected_package_popup = Popup({
    enter = true,
    border = "single"
})
local install_layout         = Layout({
        position = "50%",
        size = {
            width = "80%",
            height = "85%",
        },
    },
    Layout.Box({
        Layout.Box(packages_titles_popup, { size = "10%" }),
        Layout.Box(package_description_popup, { size = "90%" })
    }, { dir = "col" })
)
--#endregion


local function package_popup_move(dir, packages, package_titles, package_vers, package_description)
    vim.api.nvim_buf_clear_namespace(packages_titles_popup.bufnr, UI.state.hl_ns, 1, -1)
    UI.state.title_linenum = UI.state.title_linenum + dir
    if dir > 0 then
        if UI.state.title_linenum > #package_titles then
            UI.state.title_linenum = 1
        end
    elseif 0 > dir then
        if UI.state.title_linenum <= 0 then
            UI.state.title_linenum = #package_titles
        end
    end
    local using_package = packages[UI.state.title_linenum]
    package_vers = {}
    package_description = {}
    for _, version in ipairs(using_package["versions"]) do
        package_vers = vim.list_extend(package_vers, { format_package_version(version) })
    end
    local sane_description, _ = string.gsub(using_package["description"], "\n", " ")
    package_description = vim.list_extend(package_description, { sane_description })
    write(packages_vers_popup, 1, package_vers)
    write(package_description_popup, 1, package_description)
    vim.api.nvim_buf_add_highlight(
        packages_titles_popup.bufnr, UI.state.hl_ns, "Function", UI.state.title_linenum, 0, -1)
end

local function cs_popup_move(dir, csprojs)
    vim.api.nvim_buf_clear_namespace(csporj_popup.bufnr, UI.state.hl_ns, 1, -1)
    UI.state.csproj_linenum = UI.state.csproj_linenum + dir
    if dir > 0 then
        if UI.state.csproj_linenum > #csprojs then
            UI.state.csproj_linenum = 1
        end
    elseif 0 > dir then
        if UI.state.csproj_linenum <= 0 then
            UI.state.csproj_linenum = #csprojs
        end
    end
    vim.api.nvim_buf_add_highlight(
        csporj_popup.bufnr, UI.state.hl_ns, "Function", UI.state.csproj_linenum, 0, -1)
end

UI.NugetSearch = function()
    package_name_input:mount()
end

UI.NugetAddPackageUI = function()
    write(selected_package_popup, 1,
        { UI.state.selected_package.title .. " Version: " .. UI.state.selected_package.version })
    local csporj_list = {}
    local csprojs = dotnvim_utils.get_all_csproj()
    for _, csproj in ipairs(csprojs) do
        csporj_list = vim.list_extend(csporj_list, { csproj.value })
    end
    write(csporj_popup, 1, csporj_list)
    csporj_popup:map("n", "<CR>", function()
        install_layout:unmount()
        UI.state:reset()
    end)
    csporj_popup:map("n", "t", function()
        cs_popup_move(1, csporj_list)
    end)
    csporj_popup:map("n", "n", function()
        cs_popup_move(-1, csporj_list)
    end)
    install_layout:mount()
    install_layout:hide()
end

--- @param packages table this is of the structure {{
---   ["id"] = "url/to/id.json",
---   ["version"] = "Latest Sem Version",
---   ["description"] = "description of the package",
---   ["authors"] = {"string","array","of","authors"},
---   ["iconUrl"] = "image url",
---   ["licenseUrl"] = "url/to/license",
---   ["owners"] = {"a", "string", "or", "array", "of", "strings" },
---   ["projectUrl"] = "url/to/csproj",
---   ["registration"] = "The absolute URL to the associated registration index",
---   ["summary"] = "summary of the project",
---   ["tags"] = { "string", "or", "array", "of", "strings" }
---   ["title"] = "Title of the package",
---   ["totalDownloads"] = "Total Number of download in version array [int]",
---   ["verified"] = "boolean if it is verified by microsoft",
---   ["packageTypes"] = "array of tables",
--- }, ... }
UI.NugetPackagesUi = function(packages)
    local package_vers = {}
    local package_description = {}
    local package_titles = {}
    UI.state.hl_ns = nil
    for i, package in ipairs(packages) do
        table.insert(package_titles, package["title"])
        if i == 0 then
            for _, version in ipairs(package["versions"]) do
                package_vers = vim.list_extend(package_vers, { format_package_version(version) })
            end
            package_description = vim.list_extend(package_description, { package["description"] })
        end
    end

    packages_titles_popup:map("n", "t",
        function() package_popup_move(1, packages, package_titles, package_vers, package_description) end, {})
    packages_titles_popup:map("n", "n",
        function() package_popup_move(-1, packages, package_titles, package_vers, package_description) end, {})
    packages_titles_popup:map("n", "<CR>", function()
        UI.state.selected_package = {
            title = packages[UI.state.title_linenum]["title"],
            version = packages[UI.state.title_linenum]["version"]
        }
        layout:unmount()
        install_layout:show()
    end)

    write(packages_titles_popup, 1, package_titles)
    write(packages_vers_popup, 1, package_vers)
    write(package_description_popup, 1, package_description)
    UI.state.hl_ns = vim.api.nvim_buf_add_highlight(
        packages_titles_popup.bufnr, 0, "Function", UI.state.title_linenum, 1, -1)
    layout:mount()
    layout:hide()
end


return UI
