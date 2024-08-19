addon.name      = 'Clicky'
addon.author    = 'Oxos'
addon.version   = '1.0'
addon.desc      = 'Customizable Buttons for Final Fantasy XI.'

require('common')
local imgui = require('imgui')
local settings = require('settings')
local d3d = require('d3d8')
local ffi = require('ffi')
local timer = require("timer")
local chat = require('chat')

-- Define dark blue style
local darkBluePfStyles = {
    {ImGuiCol_Text, {1.0, 1.0, 1.0, 1.0}}, -- White text
    {ImGuiCol_TextDisabled, {0.5, 0.5, 0.5, 1.0}}, -- Grey text
    {ImGuiCol_WindowBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue background
    {ImGuiCol_ChildBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue background
    {ImGuiCol_PopupBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue background
    {ImGuiCol_Border, {0.3, 0.3, 0.3, 1.0}}, -- Grey border
    {ImGuiCol_BorderShadow, {0.0, 0.0, 0.0, 0.0}}, -- No border shadow
    {ImGuiCol_FrameBg, {0.1, 0.1, 0.3, 1.0}}, -- Dark blue frame background
    {ImGuiCol_FrameBgHovered, {0.2, 0.2, 0.4, 1.0}}, -- Lighter blue when hovered
    {ImGuiCol_FrameBgActive, {0.3, 0.3, 0.5, 1.0}}, -- Even lighter blue when active
    {ImGuiCol_TitleBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue title background
    {ImGuiCol_TitleBgActive, {0.1, 0.1, 0.3, 1.0}}, -- Lighter blue when active
    {ImGuiCol_TitleBgCollapsed, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue when collapsed
    {ImGuiCol_Button, {0.1, 0.1, 0.3, 1.0}}, -- Dark blue button
    {ImGuiCol_ButtonHovered, {0.2, 0.2, 0.4, 1.0}}, -- Lighter blue button when hovered
    {ImGuiCol_ButtonActive, {0.3, 0.3, 0.5, 1.0}}, -- Even lighter blue button when active
    {ImGuiCol_Header, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue header
    {ImGuiCol_HeaderHovered, {0.2, 0.2, 0.4, 1.0}}, -- Lighter blue header when hovered
    {ImGuiCol_HeaderActive, {0.3, 0.3, 0.5, 1.0}}, -- Even lighter blue header when active
}

-- Push and pop style functions
local function PushStyles(styles)
    for _, s in pairs(styles) do
        imgui.PushStyleColor(s[1], s[2])
    end
end

local function PopStyles(styles)
    for _ in pairs(styles) do
        imgui.PopStyleColor()
    end
end

-- Job mapping
local jobIconMapping = {
    [1] = 'WAR', [2] = 'MNK', [3] = 'WHM', [4] = 'BLM',
    [5] = 'RDM', [6] = 'THF', [7] = 'PLD', [8] = 'DRK',
    [9] = 'BST', [10] = 'BRD', [11] = 'RNG', [12] = 'SAM',
    [13] = 'NIN', [14] = 'DRG', [15] = 'SMN', [16] = 'BLU',
    [17] = 'COR', [18] = 'PUP', [19] = 'DNC', [20] = 'SCH',
    [21] = 'RUN', [22] = 'GEO',
}

-- Default settings
-- Default settings
local default_settings = {
    visible = { true },
    opacity = { 1.0 },
    windows = {
        {
            id = 1,
            visible = true,
            opacity = 1.0,
            window_pos = { x = 63, y = 361 },
            buttons = {
                { 
                    commands = { { command = "/clicky edit on", delay = 0 } }, 
                    right_click_commands = {}, -- Placeholder for right-click commands
                    middle_click_commands = {}, -- Placeholder for middle-click commands
                    name = "EditON", 
                    pos = { x = 0, y = 1 } 
                },
                { 
                    commands = { { command = "/clicky edit off", delay = 0 } }, 
                    right_click_commands = {}, 
                    middle_click_commands = {}, 
                    name = "EditOff", 
                    pos = { x = 0, y = 2 } 
                },
                { 
                    commands = { { command = "/clicky addnew", delay = 0 } }, 
                    right_click_commands = {}, 
                    middle_click_commands = {}, 
                    name = "NewGUI", 
                    pos = { x = 0, y = 3 } 
                }
            },
            requires_target = false
        },
        {
            id = 2,
            visible = true,
            opacity = 1.0,
            window_pos = { x = 61, y = 640 },
            buttons = {
                { 
                    commands = { { command = "!mog", delay = 0 } }, 
                    right_click_commands = {}, 
                    middle_click_commands = {}, 
                    name = "Mog", 
                    pos = { x = 0, y = 1 } 
                },
                { 
                    commands = { { command = "!chef", delay = 0 } }, 
                    right_click_commands = {}, 
                    middle_click_commands = {}, 
                    name = "Chef", 
                    pos = { x = 0, y = 2 } 
                },
                { 
                    commands = { { command = "!points", delay = 0 } }, 
                    right_click_commands = {}, 
                    middle_click_commands = {}, 
                    name = "Points", 
                    pos = { x = 0, y = 3 } 
                }
            },
            requires_target = false
        }
    }
}


local last_job_id = nil -- Track the last job ID
local isRendering = false -- Track if rendering should occur
local editing_button_index = nil -- Index of the button being edited
local isEditWindowOpen = false -- Track if the edit window is open
local editing_window_id = nil -- Track which window is being edited
local edit_mode = false -- Track if edit mode is active

local show_info_window = false
local current_profile = "No profile loaded"  -- Variable to hold the name of the currently loaded profile

-- Render info window
local function render_info_window()
    if not show_info_window then return end

    imgui.SetNextWindowBgAlpha(0.8)
    local open = show_info_window
    if imgui.Begin('Clicky Info', open, ImGuiWindowFlags_NoTitleBar + ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoCollapse) then
        imgui.Text("Clicky Addon V0")
        imgui.Separator()
        imgui.Text(string.format("Profile loaded: %s", current_profile))
        imgui.End()
    end
    
    if not open then
        show_info_window = false
    end
end

-- Save job settings
local function save_job_settings(settings_table, job)
    if not edit_mode then return end

    local job_name = jobIconMapping[job]
    if not job_name then
        print(string.format('Invalid job ID: %d', job))
        return
    end

    local settings_alias = string.format('%s_settings', job_name)
    local success, err = pcall(function()
        settings.save(settings_alias, settings_table)
    end)
    if not success then
        print(string.format('Failed to save settings for job: %s (%d), error: %s', job_name, job, err))
    else
        print(string.format('Saved settings for job: %s (%d)', job_name, job))
    end
end

-- Load job settings
local function load_job_settings(job)
    local job_name = jobIconMapping[job]
    if not job_name then
        print(string.format('Invalid job ID: %d', job))
        return default_settings
    end

    local settings_alias = string.format('%s_settings', job_name)
    local success, loaded_settings = pcall(function()
        return settings.load(default_settings, settings_alias)
    end)

    if not success or not loaded_settings or not next(loaded_settings) then
        print(string.format('Job settings file not found or failed to load for job: %s. Creating new one.', job_name))
        local save_success, save_err = pcall(function()
            settings.save(settings_alias, default_settings)
        end)
        if not save_success then
            print(string.format('Failed to save new settings for job: %s, error: %s', job_name, save_err))
            coroutine.wrap(function()
                coroutine.sleep(5)
                AshitaCore:GetChatManager():QueueCommand(1, string.format('/addon reload %s', addon.name))
            end)()
        end
        loaded_settings = default_settings
    end

    current_profile = string.format('%s_settings.lua', job_name)
    return T(loaded_settings)
end

-- Initial settings load
local function initial_load_settings()
    local settings_alias = "settings"
    local success, loaded_settings = pcall(function()
        return settings.load(default_settings, settings_alias)
    end)

    if not success or not loaded_settings or not next(loaded_settings) then
        print('Settings file not found or failed to load. Creating new one.')
        local save_success, save_err = pcall(function()
            settings.save(settings_alias, default_settings)
        end)
        if not save_success then
            print(string.format('Failed to save new settings, error: %s', save_err))
        end
        loaded_settings = default_settings
    end
    return T(loaded_settings)
end

-- Clicky Variables
local clicky = {
    settings = initial_load_settings()
}

local function UpdateVisibility(window_id, visible)
    for _, window in ipairs(clicky.settings.windows) do
        if window.id == window_id then
            window.visible = visible
            if last_job_id then
                save_job_settings(clicky.settings, last_job_id)
            end
            return
        end
    end
end

-- Execute commands
local function execute_commands(commands)
    if not commands or #commands == 0 then
        print("No commands to execute.")
        return
    end

    local index = 1

    local function execute_next_command()
        if index <= #commands then
            local command = commands[index]
            AshitaCore:GetChatManager():QueueCommand(1, command.command)
            index = index + 1
            if index <= #commands then
                local delay = command.delay or 0
                if delay > 0 then
                    timer.Simple(delay, execute_next_command)
                else
                    execute_next_command()
                end
            end
        else
            print("All commands executed.")
        end
    end

    execute_next_command()
end

-- Helper functions
local function has_target()
    local targetManager = AshitaCore:GetMemoryManager():GetTarget()
    if targetManager == nil then
        return false
    end

    local targetIndex = targetManager:GetTargetIndex(0)
    if targetIndex == 0 then
        return false
    end

    return true
end

local function button_exists_at_position(buttons, pos)
    for _, button in ipairs(buttons) do
        if button.pos.x == pos.x and button.pos.y == pos.y then
            return true
        end
    end
    return false
end

local function get_player_main_job()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    return player:GetMainJob()
end

local seacom = {
    name_buffer = { '' },
    name_buffer_size = 128,
    command_buffer = { '' },
    command_buffer_size = 256,
}

local settings_buffers = {
    requires_target = { false }
}

--test

-- Example lists for each dropdown
local action_types = { "/ma", "/ja", "/ws" } -- Magic, Ability, Weapon Skill
local magic_spells = { "Cure", "Cure II", "Cure III", "Cure IV", "Cure V", "Cure VI" } -- Example spells
local abilities = { "Provoke", "Shield Bash", "Sneak Attack" } -- Example abilities
local targets = { "<me>", "<t>", "<bt>", "<stnpc>", "<stal>" } -- Example target types

-- Default selections for each dropdown
local selected_action_type = 1
local selected_spell = 1
local selected_target = 1


local function render_edit_window()
    if isEditWindowOpen and editing_button_index ~= nil then
        local window = clicky.settings.windows[editing_window_id]
        local button = window.buttons[editing_button_index]
        if not button.commands then
            button.commands = {}
        end
        if not button.right_click_commands then
            button.right_click_commands = {}
        end
        if not button.middle_click_commands then
            button.middle_click_commands = {}
        end

        PushStyles(darkBluePfStyles)

        if imgui.Begin('Edit Button', true, ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoTitleBar) then
            -- Save and Close Buttons
            if imgui.Button('Save', { 50, 25 }) then
                button.name = seacom.name_buffer[1]
                save_job_settings(clicky.settings, last_job_id)
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end

            imgui.SameLine()
            if imgui.Button('X', { 50, 25 }) then
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end

            imgui.Separator()
            imgui.NewLine()  -- Add a new line here

            -- Button Name
            imgui.Text('Button Name:')
            if imgui.Button('DEL', { 50, 25 }) then
                table.remove(window.buttons, editing_button_index)
                save_job_settings(clicky.settings, last_job_id)
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end
            imgui.SameLine()
            if imgui.InputText('##EditButtonName', seacom.name_buffer, seacom.name_buffer_size) then
                button.name = seacom.name_buffer[1]
            end

            imgui.Separator()
            imgui.NewLine()  -- Add a new line here

            --Layout for Left, Right, and Middle Click Commands
            -- imgui.Columns(3, nil, false) -- 3 columns, no border

            -- Left Click Commands
            imgui.Text('Left Click Commands:')
            for cmdIndex, cmdInfo in ipairs(button.commands) do
                local cmdBuffer = { cmdInfo.command }
                local delayBuffer = { tostring(cmdInfo.delay) }
                if imgui.InputText('##EditButtonCommand' .. cmdIndex, cmdBuffer, seacom.command_buffer_size) then
                    button.commands[cmdIndex].command = cmdBuffer[1]
                end
                imgui.SameLine()
                imgui.SetNextItemWidth(50)
                if imgui.InputText('##EditButtonDelay' .. cmdIndex, delayBuffer, 5) then
                    local delay = tonumber(delayBuffer[1]) or 0
                    button.commands[cmdIndex].delay = delay
                end
                imgui.SameLine()
                if imgui.Button('Test##LeftClick' .. cmdIndex, { 50, 25 }) then
                    execute_commands({ cmdInfo })
                end
            end
            if imgui.Button('+Add', { 110, 40 }) then
                table.insert(button.commands, { command = "", delay = 0 })
            end
            imgui.SameLine()
            if imgui.Button('-Remove', { 110, 40 }) then
                if #button.commands > 1 then
                    table.remove(button.commands, #button.commands)
                end
            end

            imgui.NextColumn() -- Move to the second column
            imgui.Separator()
            imgui.NewLine()  -- Add a new line here

            -- Right Click Commands
            imgui.Text('Right Click Commands:')
            for cmdIndex, cmdInfo in ipairs(button.right_click_commands) do
                local cmdBuffer = { cmdInfo.command }
                local delayBuffer = { tostring(cmdInfo.delay) }
                if imgui.InputText('##EditRightClickCommand' .. cmdIndex, cmdBuffer, seacom.command_buffer_size) then
                    button.right_click_commands[cmdIndex].command = cmdBuffer[1]
                end
                imgui.SameLine()
                imgui.SetNextItemWidth(50)
                if imgui.InputText('##EditRightClickDelay' .. cmdIndex, delayBuffer, 5) then
                    local delay = tonumber(delayBuffer[1]) or 0
                    button.right_click_commands[cmdIndex].delay = delay
                end
                imgui.SameLine()
                if imgui.Button('Test##RightClick' .. cmdIndex, { 50, 25 }) then
                    execute_commands({ cmdInfo })
                end
            end
            if imgui.Button('+Add ', { 110, 40 }) then
                table.insert(button.right_click_commands, { command = "", delay = 0 })
            end
            imgui.SameLine()
            if imgui.Button('-Remove ', { 110, 40 }) then
                if #button.right_click_commands > 0 then
                    table.remove(button.right_click_commands, #button.right_click_commands)
                end
            end

            imgui.NextColumn() -- Move to the third column
            imgui.Separator()
            imgui.NewLine()  -- Add a new line here

            -- Middle Mouse Button Commands
            imgui.Text('Middle Mouse Button Commands:')
            for cmdIndex, cmdInfo in ipairs(button.middle_click_commands) do
                local cmdBuffer = { cmdInfo.command }
                local delayBuffer = { tostring(cmdInfo.delay) }
                if imgui.InputText('##EditMiddleClickCommand' .. cmdIndex, cmdBuffer, seacom.command_buffer_size) then
                    button.middle_click_commands[cmdIndex].command = cmdBuffer[1]
                end
                imgui.SameLine()
                imgui.SetNextItemWidth(50)
                if imgui.InputText('##EditMiddleClickDelay' .. cmdIndex, delayBuffer, 5) then
                    local delay = tonumber(delayBuffer[1]) or 0
                    button.middle_click_commands[cmdIndex].delay = delay
                end
                imgui.SameLine()
                if imgui.Button('Test##MiddleClick' .. cmdIndex, { 50, 25 }) then
                    execute_commands({ cmdInfo })
                end
            end
            if imgui.Button('+Add  ', { 110, 40 }) then
                table.insert(button.middle_click_commands, { command = "", delay = 0 })
            end
            imgui.SameLine()
            if imgui.Button('-Remove  ', { 110, 40 }) then
                if #button.middle_click_commands > 0 then
                    table.remove(button.middle_click_commands, #button.middle_click_commands)
                end
            end

            imgui.Columns(1) -- Reset to single column

            imgui.Separator()
            imgui.NewLine()  -- Add a new line here

            -- Movement Buttons
            if imgui.Button('<', { 50, 50 }) then
                if button.pos.x > 0 then
                    local newButtonPos = { x = button.pos.x - 1, y = button.pos.y }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        button.pos = newButtonPos
                        save_job_settings(clicky.settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('>', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x + 1, y = button.pos.y }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    button.pos = newButtonPos
                    save_job_settings(clicky.settings, last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('^', { 50, 50 }) then
                if button.pos.y > 0 then
                    local newButtonPos = { x = button.pos.x, y = button.pos.y - 1 }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        button.pos = newButtonPos
                        save_job_settings(clicky.settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('v', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x, y = button.pos.y + 1 }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    button.pos = newButtonPos
                    save_job_settings(clicky.settings, last_job_id)
                end
            end

            -- New Button Creation
            if imgui.Button('+<', { 50, 50 }) then
                if button.pos.x > 0 then
                    local newButtonPos = { x = button.pos.x - 1, y = button.pos.y }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                        save_job_settings(clicky.settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('+>', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x + 1, y = button.pos.y }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    save_job_settings(clicky.settings, last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('+^', { 50, 50 }) then
                if button.pos.y > 0 then
                    local newButtonPos = { x = button.pos.x, y = button.pos.y - 1 }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                        save_job_settings(clicky.settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('+v', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x, y = button.pos.y + 1 }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    save_job_settings(clicky.settings, last_job_id)
                end
            end

            imgui.End()
        end

        PopStyles(darkBluePfStyles)
    end
end


-- Add a new window
-- Add a new window
local function add_new_window()
    local new_id = #clicky.settings.windows + 1
    -- Create a new window with proper button initialization
    table.insert(clicky.settings.windows, {
        id = new_id,
        visible = true,
        opacity = 1.0,
        window_pos = { x = 350 + (new_id - 1) * 20, y = 700 + (new_id - 1) * 20 },
        buttons = {
            {
                name = 'New',
                commands = {},             -- Initialize as an empty table
                right_click_commands = {}, -- Initialize as an empty table
                middle_click_commands = {},-- Initialize as an empty table
                pos = { x = 0, y = 0 }
            }
        },
        requires_target = false,
        job = nil
    })
    save_job_settings(clicky.settings, last_job_id)
end

local prev_window_pos = { x = nil, y = nil }

-- Render the buttons window
local function render_buttons_window(window)
    if not window.visible then return end
    if not edit_mode and window.requires_target and not has_target() then return end
    local player_job = get_player_main_job()
    if window.job and window.job ~= player_job then return end

    local set_pos_cond = edit_mode and ImGuiCond_Once or ImGuiCond_Always
    imgui.SetNextWindowPos({ window.window_pos.x, window.window_pos.y }, set_pos_cond)

    local windowFlags = bit.bor(
        ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoNav,
        ImGuiWindowFlags_NoBringToFrontOnFocus, (edit_mode and 0 or ImGuiWindowFlags_NoMove)
    )
    if not edit_mode then
        windowFlags = bit.bor(windowFlags, ImGuiWindowFlags_NoBackground, ImGuiWindowFlags_NoDecoration)
    end

    imgui.SetNextWindowBgAlpha(edit_mode and 0.5 or window.opacity)

    PushStyles(darkBluePfStyles)

    if imgui.Begin('Clicky Buttons ' .. window.id, true, windowFlags) then
        if edit_mode then
            imgui.SetCursorPosY(0)
            if imgui.Button('+', { 25, 25 }) then
                local max_y = 0
                for _, button in ipairs(window.buttons) do
                    if button.pos.y > max_y then
                        max_y = button.pos.y
                    end
                end
                local newButtonPos = { x = 0, y = max_y + 1 }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    save_job_settings(clicky.settings, last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('x', { 25, 25 }) then
                window.visible = false
                save_job_settings(clicky.settings, last_job_id)
            end

            imgui.SameLine()
            settings_buffers.requires_target[1] = window.requires_target or false
            if imgui.Checkbox('Requires Target', settings_buffers.requires_target) then
                window.requires_target = settings_buffers.requires_target[1]
                save_job_settings(clicky.settings, last_job_id)
            end
        end

        for i, button in ipairs(window.buttons) do
            if button.pos == nil then button.pos = { x = 0, y = i } end
            if not button.commands then button.commands = {} end

            imgui.SetCursorPosX(button.pos.x * 80)
            imgui.SetCursorPosY((button.pos.y + 1) * 55)

            if imgui.Button(button.name, { 70, 50 }) then
                if edit_mode then
                    -- In edit mode, left-click to open command/wait menu
                    editing_button_index = i
                    seacom.name_buffer[1] = button.name
                    isEditWindowOpen = true
                    editing_window_id = window.id
                else
                    -- Normal mode: execute left-click commands
                    execute_commands(button.commands)
                end
            elseif imgui.IsItemClicked(1) and not edit_mode then
                -- Normal mode: execute right-click commands
                execute_commands(button.right_click_commands)
            elseif imgui.IsItemClicked(2) and not edit_mode then
                -- Normal mode: execute middle-click commands
                execute_commands(button.middle_click_commands)
            end

            if imgui.IsItemHovered() and edit_mode then
                if imgui.IsMouseClicked(1) then
                    editing_button_index = i
                    seacom.name_buffer[1] = button.name
                    isEditWindowOpen = true
                    editing_window_id = window.id
                end
            end
        end

        if edit_mode then
            local x, y = imgui.GetWindowPos()
            if prev_window_pos.x ~= x or prev_window_pos.y ~= y then
                window.window_pos.x = x
                window.window_pos.y = y
                prev_window_pos.x = x
                prev_window_pos.y = y
            end
        else
            -- If exiting edit mode, close the command editor window
            if isEditWindowOpen then
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end
        end

        imgui.End()
    end

    PopStyles(darkBluePfStyles)
end



local function update_window_positions()
    for _, window in ipairs(clicky.settings.windows) do
        imgui.SetNextWindowPos({ window.window_pos.x, window.window_pos.y }, ImGuiCond_Always)
    end
end

local function job_change_cb()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    if not player then
        print('Error: Unable to get player memory manager')
        return
    end

    local job_id = player:GetMainJob()
    if job_id ~= last_job_id then
        if last_job_id then
            save_job_settings(clicky.settings, last_job_id)
        end

        clicky.settings = load_job_settings(job_id)
        last_job_id = job_id
        update_window_positions()
    end
end

-- Initialize last time for delta time calculation
local last_time = os.clock()

ashita.events.register('d3d_present', 'present_cb', function()
    job_change_cb()
    
    -- Calculate delta time
    local current_time = os.clock()
    local dt = current_time - last_time
    last_time = current_time

    timer.Check(dt)
    if isRendering then
        for _, window in ipairs(clicky.settings.windows) do
            render_buttons_window(window)
        end
        render_edit_window()
        render_info_window()
    end
end)

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args()
    if #args == 0 or not args[1]:any('/clicky') then
        return
    end

    e.blocked = true

    -- Check if additional arguments are provided
    if #args == 1 then
        show_info_window = not show_info_window
        return
    end

    if #args >= 2 and args[2]:any('show') then
        UpdateVisibility(tonumber(args[3]) or 1, true)
        isRendering = true
        return
    end

    if #args >= 2 and args[2]:any('hide') then
        UpdateVisibility(tonumber(args[3]) or 1, false)
        isRendering = false
        return
    end

    if #args >= 2 and args[2]:any('addnew') then
        add_new_window()
        return
    end

    if #args >= 2 and args[2]:any('edit') and args[3]:any('on') then
        edit_mode = true
        for _, window in ipairs(clicky.settings.windows) do
            window.opacity = 1.0
        end
        save_job_settings(clicky.settings, last_job_id)
        return
    end

    if #args >= 2 and args[2]:any('edit') and args[3]:any('off') then
        edit_mode = false
        for _, window in ipairs(clicky.settings.windows) do
            window.opacity = 0.0
        end
        save_job_settings(clicky.settings, last_job_id)
        return
    end

    if #args >= 2 and args[2]:any('save') then
        save_job_settings(clicky.settings, last_job_id)
        print('Settings saved manually.')
        return
    end

    print(chat.header(addon.name):append(chat.error('Usage: /clicky [show|hide|addnew|edit] [on|off] [window_id]')))
end)

ashita.events.register('unload', 'unload_cb', function ()
    if last_job_id then
        save_job_settings(clicky.settings, last_job_id)
    end
end)

for _, window in ipairs(clicky.settings.windows) do
    UpdateVisibility(window.id, window.visible)
end
isRendering = true
