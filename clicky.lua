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

-- Default Settings
local default_settings = T{
    visible = T{ true, },
    opacity = T{ 1.0, },
    window_pos = { x = 350, y = 700 }, -- Default window position
    thf_window_pos = { x = 510, y = 700 }, -- Default THF window position
    buttons = {} -- List of custom buttons
};

-- Clicky Variables
local clicky = T{
    settings = settings.load(default_settings),
};

local isRendering = false -- Track if rendering should occur
local show_thf_actions = false -- Track if THF actions should be displayed
local show_attack_button = false -- Track if Attack Target button should be displayed
local editing_button_index = nil -- Index of the button being edited

local function UpdateVisibility(visible)
    clicky.settings.visible[1] = visible
    settings.save()
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

-- Function to render the additional buttons
local function render_additional_buttons()
    -- Make the window movable
    imgui.SetNextWindowPos({ clicky.settings.thf_window_pos.x, clicky.settings.thf_window_pos.y }, ImGuiCond_Once)
    local windowFlags = bit.bor(
        ImGuiWindowFlags_NoTitleBar,
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_AlwaysAutoResize,
        --ImGuiWindowFlags_NoMove,
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
local editing_button_name_buf = ffi.new("char[128]", "")
local editing_button_command_buf = ffi.new("char[256]", "")

local seacom = {
    name_buffer = { '' },
    name_buffer_size = 128,
    command_buffer = { '' },
    command_buffer_size = 256,
}


--- Function to render the GUI
local function render_buttons()
    if not clicky.settings.visible[1] then
        return
    end

    -- Make the main window movable
    imgui.SetNextWindowPos({ clicky.settings.window_pos.x, clicky.settings.window_pos.y }, ImGuiCond_Once)
    -- Set window flags: No title bar, no resize, no scrollbar, always auto resize
    local windowFlags = bit.bor(
        ImGuiWindowFlags_NoTitleBar,
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_AlwaysAutoResize,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_NoNav,
        ImGuiWindowFlags_NoBringToFrontOnFocus
    )

    -- Begin the ImGui window without title bar, scrollbars, or resize
    imgui.SetNextWindowBgAlpha(clicky.settings.opacity[1])
    if imgui.Begin('Clicky Buttons', true, windowFlags) then
        -- Display the THF button 
        if imgui.Button('THF', { 150, 50 }) then
            show_thf_actions = not show_thf_actions
        end

        -- Display the custom buttons
        for i, button in ipairs(clicky.settings.buttons) do
            if imgui.Button(button.name, { 150, 50 }) then
                AshitaCore:GetChatManager():QueueCommand(1, button.command)
            end

            -- Check for right-click to start editing
            if imgui.IsItemHovered() then
                if imgui.IsMouseClicked(1) then -- 1 is for right-click
                    editing_button_index = i -- Start editing
                    seacom.name_buffer[1] = button.name
                    seacom.command_buffer[1] = button.command
                    isEditWindowOpen = true -- Open the edit window
                end
            end
        end

        -- Display the plus button to add new buttons
        if imgui.Button('+', { 150, 50 }) then
            table.insert(clicky.settings.buttons, { name = 'New Button', command = '' })
            settings.save()
        end

        -- Allow the window to be moved
        local x, y = imgui.GetWindowPos()
        clicky.settings.window_pos.x = x
        clicky.settings.window_pos.y = y
        settings.save()
        
        imgui.End()
    end

    -- Render additional buttons if the flag is set
    if show_thf_actions then
        render_additional_buttons()
    end

    -- Render the "Attack Target" button next to the player if there is a target
    if show_attack_button then
        imgui.SetNextWindowPos({ 500, 550 }, ImGuiCond_Always) -- Adjust position based on your screen resolution and player position
        if imgui.Begin('Attack Actions', true, windowFlags) then
            if imgui.Button('Attack', { 100, 50 }) then
                AshitaCore:GetChatManager():QueueCommand(1, '/attack')
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

-- Function to render the edit window
local function render_edit_window()
    if isEditWindowOpen and editing_button_index ~= nil then
        local button = clicky.settings.buttons[editing_button_index]
        if imgui.Begin('Edit Button', true, ImGuiWindowFlags_AlwaysAutoResize) then
            imgui.Text('Button Name:')
            if imgui.InputText('##EditButtonName', seacom.name_buffer, seacom.name_buffer_size) then
                button.name = seacom.name_buffer[1]
            end

            imgui.Text('Button Command:')
            if imgui.InputText('##EditButtonCommand', seacom.command_buffer, seacom.command_buffer_size) then
                button.command = seacom.command_buffer[1]
            end

            if imgui.Button('Save', { 100, 50 }) then
                clicky.settings.buttons[editing_button_index].name = seacom.name_buffer[1]
                clicky.settings.buttons[editing_button_index].command = seacom.command_buffer[1]
                settings.save()
                isEditWindowOpen = false
                editing_button_index = nil
            end

            imgui.SameLine()
            if imgui.Button('Cancel', { 100, 50 }) then
                isEditWindowOpen = false
                editing_button_index = nil
            end

            imgui.End()
        end
    end
end

-- Integrate with Ashita's ImGui rendering
ashita.events.register('d3d_present', 'present_cb', function()
    if isRendering then
        render_buttons()
        render_edit_window()
        imgui.Render()
    end
end)


-- Update the attack button visibility based on the player's target
ashita.events.register('d3d_present', 'update_target_cb', function()
    show_attack_button = has_target()
end)

-- Handle commands to show/hide the buttons
ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args()
    if #args == 0 or not args[1]:any('/clicky') then
        return
    end

    -- Block all related commands
    e.blocked = true

    -- Handle: /clicky show
    if #args >= 2 and args[2]:any('show') then
        UpdateVisibility(true)
        isRendering = true
        return
    end

    -- Handle: /clicky hide
    if #args >= 2 and args[2]:any('hide') then
        UpdateVisibility(false)
        isRendering = false
        return
    end

    -- Unhandled: Print help information
    print(chat.header(addon.name):append(chat.error('Usage: /clicky [show|hide]')))
end)

-- Save settings on unload
ashita.events.register('unload', 'unload_cb', function ()
    settings.save()
end)

-- Ensure visibility when initializing
UpdateVisibility(clicky.settings.visible[1])
isRendering = clicky.settings.visible[1]
