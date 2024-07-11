function handle_command(e)
    local args = e.command:args()
    if #args == 0 or not args[1]:any('/clicky') then
        return
    end

    e.blocked = true

    -- Check if additional arguments are provided
    if #args == 1 then
        clicky.show_info_window = not clicky.show_info_window
        return
    end

    if #args >= 2 and args[2]:any('show') then
        UpdateVisibility(tonumber(args[3]) or 1, true)
        clicky.isRendering = true
        return
    end

    if #args >= 2 and args[2]:any('hide') then
        UpdateVisibility(tonumber(args[3]) or 1, false)
        clicky.isRendering = false
        return
    end

    if #args >= 2 and args[2]:any('addnew') then
        add_new_window()
        return
    end

    if #args >= 2 and args[2]:any('edit') and args[3]:any('on') then
        clicky.edit_mode = true
        for _, window in ipairs(clicky.settings.windows) do
            window.opacity = 1.0
        end
        save_job_settings(clicky.settings, clicky.last_job_id)
        return
    end

    if #args >= 2 and args[2]:any('edit') and args[3]:any('off') then
        clicky.edit_mode = false
        for _, window in ipairs(clicky.settings.windows) do
            window.opacity = 0.0
        end
        save_job_settings(clicky.settings, clicky.last_job_id)
        return
    end

    if #args >= 2 and args[2]:any('save') then
        save_job_settings(clicky.settings, clicky.last_job_id)  -- Manual save command
        print('Settings saved manually.')
        return
    end

    print(chat.header(addon.name):append(chat.error('Usage: /clicky [show|hide|addnew|edit] [on|off] [window_id]')))
end
