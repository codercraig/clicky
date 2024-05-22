addon.name      = 'Clicky';
addon.author    = 'Oxos';
addon.version   = '1.0';
addon.desc      = 'Customizable Buttons for Final Fantasy XI.';

require('common');
local imgui = require('imgui');
local settings = require('settings');
local d3d = require('d3d8');
local ffi = require('ffi');
local coroutine = require('coroutine');
local images = require("images");
local guiimages = images.loadTextures();

local function drawJobIcon(jobID)
    local total = 22
    local ratio = 1 / total
    local iconID = jobID - 1

    imgui.Image(tonumber(ffi.cast("uint32_t", guiimages.jobs)), { 48, 48 }, { ratio * iconID, 0 }, { ratio * iconID + ratio, 1 }, { 1, 1, 1, 1 }, { 0, 0, 0, 0 })
end

-- Default Settings
local default_settings = T{
    visible = T{ true, },
    opacity = T{ 1.0, },
    windows = { -- List of windows
        { id = 1, visible = true, opacity = 1.0, window_pos = { x = 350, y = 700 }, buttons = {} }
    }
};

-- Clicky Variables
local clicky = T{
    settings = settings.load(default_settings),
};

local isRendering = false -- Track if rendering should occur
local show_thf_actions = false -- Track if THF actions should be displayed
local show_attack_button = false -- Track if Attack Target button should be displayed
local editing_button_index = nil -- Index of the button being edited
local isEditWindowOpen = false -- Track if the edit window is open
local editing_window_id = nil -- Track which window is being edited
local edit_mode = false -- Track if edit mode is active

local function UpdateVisibility(window_id, visible)
    for _, window in ipairs(clicky.settings.windows) do
        if window.id == window_id then
            window.visible = visible
            settings.save()
            return
        end
    end
end

-- Function to execute a sequence of commands with delays
local function execute_commands(commands, delay)
    coroutine.wrap(function()
        for _, command in ipairs(commands) do
            AshitaCore:GetChatManager():QueueCommand(1, command)
            coroutine.sleep(delay) -- Add a delay between commands
        end
    end)()
end

-- Function to check if the player has a target
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

-- Function to render the THF button window
local function render_thf_button_window()
    imgui.SetNextWindowPos({ 350, 700 }, ImGuiCond_Once)
    local windowFlags = bit.bor(
        ImGuiWindowFlags_NoTitleBar,
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_AlwaysAutoResize,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_NoNav,
        ImGuiWindowFlags_NoBringToFrontOnFocus
    )

    if imgui.Begin('THF Button', true, windowFlags) then
        drawJobIcon(6) -- Draw the THF job icon
        if imgui.IsItemClicked() then
            show_thf_actions = not show_thf_actions
        end
        imgui.End()
    end
end

-- Function to render the THF actions window
local function render_thf_actions_window()
    if not show_thf_actions then return end

    imgui.SetNextWindowPos({ clicky.settings.thf_window_pos.x, clicky.settings.thf_window_pos.y }, ImGuiCond_Once)
    local windowFlags = bit.bor(
        ImGuiWindowFlags_NoTitleBar,
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_AlwaysAutoResize,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_NoNav,
        ImGuiWindowFlags_NoBringToFrontOnFocus
    )
    if imgui.Begin('THF Actions', true, windowFlags) then
        if imgui.Button('Sneak Attack', { 150, 50 }) then
            AshitaCore:GetChatManager():QueueCommand(1, '/ja "Sneak Attack" <me>')
        end
        imgui.SameLine()
        if imgui.Button('Trick Attack', { 150, 50 }) then
            AshitaCore:GetChatManager():QueueCommand(1, '/ja "Trick Attack" <me>')
        end
        imgui.SameLine()
        if imgui.Button('WS', { 150, 50 }) then
            AshitaCore:GetChatManager():QueueCommand(1, '/ws "Exenterator" <t>')
        end
        if imgui.Button('Steal', { 150, 50 }) then
            AshitaCore:GetChatManager():QueueCommand(1, '/ja "Steal" <t>')
        end
        imgui.SameLine()
        if imgui.Button('Mug', { 150, 50 }) then
            AshitaCore:GetChatManager():QueueCommand(1, '/ja "Mug" <t>')
        end
        if imgui.Button('Hide', { 150, 50 }) then
            AshitaCore:GetChatManager():QueueCommand(1, '/ja "Hide" <me>')
        end
        imgui.SameLine()
        if imgui.Button('Flee', { 150, 50 }) then
            AshitaCore:GetChatManager():QueueCommand(1, '/ja "Flee" <me>')
        end

        -- Allow the window to be moved
        local x, y = imgui.GetWindowPos()
        clicky.settings.thf_window_pos.x = x
        clicky.settings.thf_window_pos.y = y
        settings.save()
        imgui.End()
    end
end

-- Initialize buffers for editing
local seacom = {
    name_buffer = { '' },
    name_buffer_size = 128,
    command_buffer = { '' },
    command_buffer_size = 256,
}

-- Function to render the edit window
local function render_edit_window()
    if isEditWindowOpen and editing_button_index ~= nil then
        local window = clicky.settings.windows[editing_window_id]
        local button = window.buttons[editing_button_index]
        if imgui.Begin('Edit Button', true, ImGuiWindowFlags_AlwaysAutoResize) then
            imgui.Text('Button Name:')
            if imgui.InputText('##EditButtonName', seacom.name_buffer, seacom.name_buffer_size) then
                button.name = seacom.name_buffer[1]
            end

            imgui.Text('Button Command:')
            if imgui.InputText('##EditButtonCommand', seacom.command_buffer, seacom.command_buffer_size) then
                button.command = seacom.command_buffer[1]
            end

            if imgui.Button('Save', { 75, 50 }) then
                button.name = seacom.name_buffer[1]
                button.command = seacom.command_buffer[1]
                settings.save()
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end

            imgui.SameLine()
            if imgui.Button('Cancel', { 75, 50 }) then
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end

            imgui.SameLine()
            if imgui.Button('Remove', { 75, 50 }) then
                table.remove(window.buttons, editing_button_index)
                settings.save()
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end

            imgui.SameLine()
            if imgui.Button('>', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x + 1, y = button.pos.y }
                table.insert(window.buttons, { name = 'New', command = '', pos = newButtonPos })
                settings.save()
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end

            imgui.End()
        end
    end
end

-- Function to render the custom buttons window
local function render_buttons_window(window)
    if not window.visible then
        return
    end

    -- Make the main window movable only in edit mode
    imgui.SetNextWindowPos({ window.window_pos.x, window.window_pos.y }, ImGuiCond_Once)
    local windowFlags = bit.bor(
        ImGuiWindowFlags_NoTitleBar,
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_AlwaysAutoResize,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_NoNav,
        ImGuiWindowFlags_NoBringToFrontOnFocus,
        (edit_mode and 0 or ImGuiWindowFlags_NoMove) -- Disable moving the window if not in edit mode
    )
    
    if not edit_mode then
        windowFlags = bit.bor(windowFlags, ImGuiWindowFlags_NoBackground, ImGuiWindowFlags_NoDecoration)
    end

    -- Begin the ImGui window without title bar, scrollbars, or resize
    imgui.SetNextWindowBgAlpha(edit_mode and window.opacity or 0.0)
    if imgui.Begin('Clicky Buttons ' .. window.id, true, windowFlags) then
        if edit_mode then
            -- Display the plus and close buttons at the top
            imgui.SetCursorPosY(0)
            if imgui.Button('+', { 25, 25 }) then
                local max_y = 0
                for _, button in ipairs(window.buttons) do
                    if button.pos.y > max_y then
                        max_y = button.pos.y
                    end
                end
                table.insert(window.buttons, { name = 'New', command = '', pos = { x = 0, y = max_y + 1 } })
                settings.save()
            end

            imgui.SameLine()
            if imgui.Button('x', { 25, 25 }) then
                window.visible = false
                settings.save()
            end
        end

        -- Display the custom buttons
        for i, button in ipairs(window.buttons) do
            if button.pos == nil then
                button.pos = { x = 0, y = i }
            end

            imgui.SetCursorPosX(button.pos.x * 80)
            imgui.SetCursorPosY((button.pos.y + 1) * 55)  -- Offset by 1 row to make space for "+" and "x"
            if imgui.Button(button.name, { 70, 50 }) then
                AshitaCore:GetChatManager():QueueCommand(1, button.command)
            end

            -- Check for right-click to start editing
            if imgui.IsItemHovered() and edit_mode then
                if imgui.IsMouseClicked(1) then -- 1 is for right-click
                    editing_button_index = i -- Start editing
                    seacom.name_buffer[1] = button.name
                    seacom.command_buffer[1] = button.command
                    isEditWindowOpen = true -- Open the edit window
                    editing_window_id = window.id -- Track which window is being edited
                end
            end
        end

        -- Allow the window to be moved
        local x, y = imgui.GetWindowPos()
        window.window_pos.x = x
        window.window_pos.y = y
        settings.save()
        
        imgui.End()
    end
end

-- Function to add a new window
local function add_new_window()
    local new_id = #clicky.settings.windows + 1
    table.insert(clicky.settings.windows, { id = new_id, visible = true, opacity = 1.0, window_pos = { x = 350 + (new_id - 1) * 20, y = 700 + (new_id - 1) * 20 }, buttons = {} })
    settings.save()
end

-- Function to render the attack window
local function render_attack_window()
    if show_attack_button then
        imgui.SetNextWindowPos({ 500, 550 }, ImGuiCond_Once) -- Adjust position based on your screen resolution and player position
        local windowFlags = bit.bor(
            ImGuiWindowFlags_NoTitleBar,
            ImGuiWindowFlags_NoResize,
            ImGuiWindowFlags_NoScrollbar,
            ImGuiWindowFlags_AlwaysAutoResize,
            ImGuiWindowFlags_NoCollapse,
            ImGuiWindowFlags_NoNav,
            ImGuiWindowFlags_NoBringToFrontOnFocus
        )
        if imgui.Begin('Attack Actions', true, windowFlags) then
            if imgui.Button('Attack', { 100, 50 }) then
                AshitaCore:GetChatManager():QueueCommand(1, '/attack')
            end
          
            if imgui.Button('Ranged', { 100, 50 }) then
                AshitaCore:GetChatManager():QueueCommand(1, '/ra <t>')
            end
            if imgui.Button('Trust', { 100, 50 }) then
                AshitaCore:GetChatManager():QueueCommand(1, '/ma "Kupofried" <me>')
            end
            if imgui.Button('Check', { 100, 50 }) then
                AshitaCore:GetChatManager():QueueCommand(1, '/check')
            end
            imgui.End()
        end
    end
end

-- Integrate with Ashita's ImGui rendering
ashita.events.register('d3d_present', 'present_cb', function()
    if isRendering then
        for _, window in ipairs(clicky.settings.windows) do
            render_buttons_window(window)
        end
        render_edit_window()
        render_thf_button_window()
        render_thf_actions_window()
        render_attack_window()
        imgui.Render()
    end
end)

-- Update the attack button visibility based on the player's target
ashita.events.register('d3d_present', 'update_target_cb', function()
    show_attack_button = has_target()
end)

-- Handle commands to show/hide the buttons and toggle edit mode
ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args()
    if #args == 0 or not args[1]:any('/clicky') then
        return
    end

    -- Block all related commands
    e.blocked = true

    -- Handle: /clicky show
    if #args >= 2 and args[2]:any('show') then
        UpdateVisibility(tonumber(args[3]) or 1, true)
        isRendering = true
        return
    end

    -- Handle: /clicky hide
    if #args >= 2 and args[2]:any('hide') then
        UpdateVisibility(tonumber(args[3]) or 1, false)
        isRendering = false
        return
    end

    -- Handle: /clicky addnew
    if #args >= 2 and args[2]:any('addnew') then
        add_new_window()
        return
    end

    -- Handle: /clicky edit on
    if #args >= 2 and args[2]:any('edit') and args[3]:any('on') then
        edit_mode = true
        for _, window in ipairs(clicky.settings.windows) do
            window.opacity = 1.0
        end
        settings.save()
        return
    end

    -- Handle: /clicky edit off
    if #args >= 2 and args[2]:any('edit') and args[3]:any('off') then
        edit_mode = false
        for _, window in ipairs(clicky.settings.windows) do
            window.opacity = 0.0
        end
        settings.save()
        return
    end

    -- Unhandled: Print help information
    print(chat.header(addon.name):append(chat.error('Usage: /clicky [show|hide|addnew|edit] [on|off] [window_id]')))
end)

-- Save settings on unload
ashita.events.register('unload', 'unload_cb', function ()
    settings.save()
end)

-- Ensure visibility when initializing
for _, window in ipairs(clicky.settings.windows) do
    UpdateVisibility(window.id, window.visible)
end
isRendering = true
