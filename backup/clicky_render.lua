local imgui = require('imgui')

function render_buttons_window(window)
    if not window.visible then
        return
    end

    if not clicky.edit_mode and window.requires_target and not has_target() then
        return
    end

    local player_job = get_player_main_job()
    if window.job and window.job ~= player_job then
        return
    end

    -- Use ImGuiCond_Always only when not in edit mode to allow movement
    local set_pos_cond = clicky.edit_mode and ImGuiCond_Once or ImGuiCond_Always
    imgui.SetNextWindowPos({ window.window_pos.x, window.window_pos.y }, set_pos_cond)

    local windowFlags = bit.bor(
        ImGuiWindowFlags_NoTitleBar,
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_AlwaysAutoResize,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_NoNav,
        ImGuiWindowFlags_NoBringToFrontOnFocus,
        (clicky.edit_mode and 0 or ImGuiWindowFlags_NoMove)
    )
    if not clicky.edit_mode then
        windowFlags = bit.bor(windowFlags, ImGuiWindowFlags_NoBackground, ImGuiWindowFlags_NoDecoration)
    end

    imgui.SetNextWindowBgAlpha(clicky.edit_mode and 0.5 or window.opacity)

    PushStyles(darkBluePfStyles)  -- Push styles

    if imgui.Begin('Clicky Buttons ' .. window.id, true, windowFlags) then
        if clicky.edit_mode then
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
                    save_job_settings(clicky.settings, clicky.last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('x', { 25, 25 }) then
                window.visible = false
                save_job_settings(clicky.settings, clicky.last_job_id)
            end

            imgui.SameLine()
            settings_buffers.requires_target[1] = window.requires_target or false
            if imgui.Checkbox('Requires Target', settings_buffers.requires_target) then
                window.requires_target = settings_buffers.requires_target[1]
                save_job_settings(clicky.settings, clicky.last_job_id)
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
                execute_commands(button.commands)  -- Adjust the delay as needed
            end

            if imgui.IsItemHovered() and clicky.edit_mode then
                if imgui.IsMouseClicked(1) then
                    clicky.editing_button_index = i
                    seacom.name_buffer[1] = button.name
                    seacom.command_buffer[1] = button.command
                    clicky.isEditWindowOpen = true
                    clicky.editing_window_id = window.id
                end
            end
        end

        if clicky.edit_mode then
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

    PopStyles(darkBluePfStyles)  -- Pop styles
end

function render_edit_window()
    if clicky.isEditWindowOpen and clicky.editing_button_index ~= nil then
        local window = clicky.settings.windows[clicky.editing_window_id]
        local button = window.buttons[clicky.editing_button_index]
        if not button.commands then
            button.commands = {}
        end

        PushStyles(darkBluePfStyles)  -- Push styles

        -- ImGuiWindowFlags_AlwaysAutoResize
        if imgui.Begin('Edit Button', true, ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoTitleBar) then
            if imgui.Button('Save', { 50, 25 }) then
                button.name = seacom.name_buffer[1]
                save_job_settings(clicky.settings, clicky.last_job_id)
                if not debug_save then
                    debug_save = true
                end
                clicky.isEditWindowOpen = false
                clicky.editing_button_index = nil
                clicky.editing_window_id = nil
            end

            imgui.SameLine()
            if imgui.Button('X', { 50, 25 }) then
                clicky.isEditWindowOpen = false
                clicky.editing_button_index = nil
                clicky.editing_window_id = nil
            end

            imgui.Separator()

            imgui.Text('Button Name:')
            if imgui.Button('DEL', { 50, 25 }) then
                table.remove(window.buttons, clicky.editing_button_index)
                save_job_settings(clicky.settings, clicky.last_job_id)
                clicky.isEditWindowOpen = false
                clicky.editing_button_index = nil
                clicky.editing_window_id = nil
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
                imgui.SetNextItemWidth(50) -- Adjust the width as needed
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
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        button.pos = newButtonPos
                        save_job_settings(clicky.settings, clicky.last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('>', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x + 1, y = button.pos.y }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    button.pos = newButtonPos
                    save_job_settings(clicky.settings, clicky.last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('^', { 50, 50 }) then
                if button.pos.y > 0 then
                    local newButtonPos = { x = button.pos.x, y = button.pos.y - 1 }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        button.pos = newButtonPos
                        save_job_settings(clicky.settings, clicky.last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('v', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x, y = button.pos.y + 1 }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    button.pos = newButtonPos
                    save_job_settings(clicky.settings, clicky.last_job_id)
                end
            end

            -- New Button Creation
            if imgui.Button('+<', { 50, 50 }) then
                if button.pos.x > 0 then
                    local newButtonPos = { x = button.pos.x - 1, y = button.pos.y }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                        save_job_settings(clicky.settings, clicky.last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('+>', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x + 1, y = button.pos.y }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    save_job_settings(clicky.settings, clicky.last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('+^', { 50, 50 }) then
                if button.pos.y > 0 then
                    local newButtonPos = { x = button.pos.x, y = button.pos.y - 1 }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                        save_job_settings(clicky.settings, clicky.last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('+v', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x, y = button.pos.y + 1 }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    save_job_settings(clicky.settings, clicky.last_job_id)
                end
            end

            imgui.End()
        end

        PopStyles(darkBluePfStyles)  -- Pop styles
    end
end

function render_info_window()
    if not clicky.show_info_window then return end

    imgui.SetNextWindowBgAlpha(0.8)
    
    -- Use ImGuiWindowFlags_AlwaysAutoResize for auto-resizing and ImGuiWindowFlags_NoCollapse to prevent collapsing
    -- The third parameter `open` will determine if the window remains open
    local open = clicky.show_info_window
    if imgui.Begin('Clicky Info', open, ImGuiWindowFlags_NoTitleBar + ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoCollapse) then
        imgui.Text("Clicky Addon V0")
        imgui.Separator()
        imgui.Text(string.format("Profile loaded: %s", clicky.current_profile))
        imgui.End()
    end

    -- Check if the window should be closed
    if not open then
        clicky.show_info_window = false
    end
end

function add_new_window()
    local new_id = #clicky.settings.windows + 1
    table.insert(clicky.settings.windows, { id = new_id, visible = true, opacity = 1.0, window_pos = { x = 350 + (new_id - 1) * 20, y = 700 + (new_id - 1) * 20 }, buttons = {}, requires_target = false, job = nil })
    save_job_settings(clicky.settings, clicky.last_job_id)
end

local prev_window_pos = { x = nil, y = nil }
