local imgui = require('imgui')
local settings = require('clicky_settings')
local utils = require('clicky_utils')

local darkBluePfStyles = {
    {ImGuiCol_Text, {1.0, 1.0, 1.0, 1.0}},
    {ImGuiCol_TextDisabled, {0.5, 0.5, 0.5, 1.0}},
    {ImGuiCol_WindowBg, {0.0, 0.0, 0.2, 1.0}},
    {ImGuiCol_ChildBg, {0.0, 0.0, 0.2, 1.0}},
    {ImGuiCol_PopupBg, {0.0, 0.0, 0.2, 1.0}},
    {ImGuiCol_Border, {0.3, 0.3, 0.3, 1.0}},
    {ImGuiCol_BorderShadow, {0.0, 0.0, 0.0, 0.0}},
    {ImGuiCol_FrameBg, {0.1, 0.1, 0.3, 1.0}},
    {ImGuiCol_FrameBgHovered, {0.2, 0.2, 0.4, 1.0}},
    {ImGuiCol_FrameBgActive, {0.3, 0.3, 0.5, 1.0}},
    {ImGuiCol_TitleBg, {0.0, 0.0, 0.2, 1.0}},
    {ImGuiCol_TitleBgActive, {0.1, 0.1, 0.3, 1.0}},
    {ImGuiCol_TitleBgCollapsed, {0.0, 0.0, 0.2, 1.0}},
    {ImGuiCol_Button, {0.1, 0.1, 0.3, 1.0}},
    {ImGuiCol_ButtonHovered, {0.2, 0.2, 0.4, 1.0}},
    {ImGuiCol_ButtonActive, {0.3, 0.3, 0.5, 1.0}},
    {ImGuiCol_Header, {0.0, 0.0, 0.2, 1.0}},
    {ImGuiCol_HeaderHovered, {0.2, 0.2, 0.4, 1.0}},
    {ImGuiCol_HeaderActive, {0.3, 0.3, 0.5, 1.0}},
}

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

local function render_edit_window(settings, last_job_id)
    if isEditWindowOpen and editing_button_index ~= nil then
        local window = settings.windows[editing_window_id]
        local button = window.buttons[editing_button_index]
        if not button.commands then
            button.commands = {}
        end

        PushStyles(darkBluePfStyles)

        if imgui.Begin('Edit Button', true, ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoTitleBar) then
            if imgui.Button('Save', { 50, 25 }) then
                button.name = seacom.name_buffer[1]
                settings.save_job_settings(settings, last_job_id)
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

            imgui.Text('Button Name:')
            if imgui.Button('DEL', { 50, 25 }) then
                table.remove(window.buttons, editing_button_index)
                settings.save_job_settings(settings, last_job_id)
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end
            imgui.SameLine()
            if imgui.InputText('##EditButtonName', seacom.name_buffer, seacom.name_buffer_size) then
                button.name = seacom.name_buffer[1]
            end

            imgui.Separator()

            imgui.Text('Button/Wait Commands:')
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

            imgui.Separator()

            -- Movement Buttons
            if imgui.Button('<', { 50, 50 }) then
                if button.pos.x > 0 then
                    local newButtonPos = { x = button.pos.x - 1, y = button.pos.y }
                    if not utils.button_exists_at_position(window.buttons, newButtonPos) then
                        button.pos = newButtonPos
                        settings.save_job_settings(settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('>', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x + 1, y = button.pos.y }
                if not utils.button_exists_at_position(window.buttons, newButtonPos) then
                    button.pos = newButtonPos
                    settings.save_job_settings(settings, last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('^', { 50, 50 }) then
                if button.pos.y > 0 then
                    local newButtonPos = { x = button.pos.x, y = button.pos.y - 1 }
                    if not utils.button_exists_at_position(window.buttons, newButtonPos) then
                        button.pos = newButtonPos
                        settings.save_job_settings(settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('v', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x, y = button.pos.y + 1 }
                if not utils.button_exists_at_position(window.buttons, newButtonPos) then
                    button.pos = newButtonPos
                    settings.save_job_settings(settings, last_job_id)
                end
            end

            -- New Button Creation
            if imgui.Button('+<', { 50, 50 }) then
                if button.pos.x > 0 then
                    local newButtonPos = { x = button.pos.x - 1, y = button.pos.y }
                    if not utils.button_exists_at_position(window.buttons, newButtonPos) then
                        table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                        settings.save_job_settings(settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('+>', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x + 1, y = button.pos.y }
                if not utils.button_exists_at_position(window.buttons, newButtonPos) then
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    settings.save_job_settings(settings, last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('+^', { 50, 50 }) then
                if button.pos.y > 0 then
                    local newButtonPos = { x = button.pos.x, y = button.pos.y - 1 }
                    if not utils.button_exists_at_position(window.buttons, newButtonPos) then
                        table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                        settings.save_job_settings(settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('+v', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x, y = button.pos.y + 1 }
                if not utils.button_exists_at_position(window.buttons, newButtonPos) then
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    settings.save_job_settings(settings, last_job_id)
                end
            end

            imgui.End()
        end

        PopStyles(darkBluePfStyles)
    end
end

local function render_buttons_window(window, settings, last_job_id)
    if not window.visible then
        return
    end

    if not edit_mode and window.requires_target and not utils.has_target() then
        return
    end

    local player_job = utils.get_player_main_job()
    if window.job and window.job ~= player_job then
        return
    end

    local set_pos_cond = edit_mode and ImGuiCond_Once or ImGuiCond_Always
    imgui.SetNextWindowPos({ window.window_pos.x, window.window_pos.y }, set_pos_cond)

    local windowFlags = bit.bor(
        ImGuiWindowFlags_NoTitleBar,
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_AlwaysAutoResize,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_NoNav,
        ImGuiWindowFlags_NoBringToFrontOnFocus,
        (edit_mode and 0 or ImGuiWindowFlags_NoMove)
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
                if not utils.button_exists_at_position(window.buttons, newButtonPos) then
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    settings.save_job_settings(settings, last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('x', { 25, 25 }) then
                window.visible = false
                settings.save_job_settings(settings, last_job_id)
            end

            imgui.SameLine()
            settings_buffers.requires_target[1] = window.requires_target or false
            if imgui.Checkbox('Requires Target', settings_buffers.requires_target) then
                window.requires_target = settings_buffers.requires_target[1]
                settings.save_job_settings(settings, last_job_id)
            end
        end

        for i, button in ipairs(window.buttons) do
            if button.pos == nil then
                button.pos = { x = 0, y = i }
            end

            if not button.commands then
                button.commands = {}
            end

            imgui.SetCursorPosX(button.pos.x * 80)
            imgui.SetCursorPosY((button.pos.y + 1) * 55)
            if imgui.Button(button.name, { 70, 50 }) then
                utils.execute_commands(button.commands)
            end

            if imgui.IsItemHovered() and edit_mode then
                if imgui.IsMouseClicked(1) then
                    editing_button_index = i
                    seacom.name_buffer[1] = button.name
                    seacom.command_buffer[1] = button.command
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
        end

        imgui.End()
    end

    PopStyles(darkBluePfStyles)
end

local function update_window_positions(windows)
    for _, window in ipairs(windows) do
        imgui.SetNextWindowPos({ window.window_pos.x, window.window_pos.y }, ImGuiCond_Always)
    end
end

return {
    render_info_window = render_info_window,
    render_edit_window = render_edit_window,
    render_buttons_window = render_buttons_window,
    update_window_positions = update_window_positions,
    PushStyles = PushStyles,
    PopStyles = PopStyles
}
