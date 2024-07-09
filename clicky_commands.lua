local settings = require('clicky_settings')
local render = require('clicky_render')
local chat = require('chat')

local function handle_command(e, clicky, last_job_id)
    local args = e.command:args()
    if #args == 0 or not args[1]:any('/clicky') then
        return
    end

    e.blocked = true

    if #args == 1 then
        show_info_window = not show_info_window
        return
    end

    if #args >= 2 and args[2]:any('show') then
        render.UpdateVisibility(tonumber(args[3]) or 1, true, clicky.settings, last_job_id)
        isRendering = true
        return
    end

    if #args >= 2 and args[2]:any('hide') then
        render.UpdateVisibility(tonumber(args[3]) or 1, false, clicky.settings, last_job_id)
        isRendering = false
        return
    end

    if #args >= 2 and args[2]:any('addnew') then
        render.add_new_window(clicky.settings, last_job_id)
        return
    end

    if #args >= 2 and args[2]:any('edit') and args[3]:any('on') then
        edit_mode = true
        for _, window in ipairs(clicky.settings.windows) do
            window.opacity = 1.0
        end
        settings.save_job_settings(clicky.settings, last_job_id)
        return
    end

    if #args >= 2 and args[2]:any('edit') and args[3]:any('off') then
        edit_mode = false
        for _, window in ipairs(clicky.settings.windows) do
            window.opacity = 0.0
        end
        settings.save_job_settings(clicky.settings, last_job_id)
        return
    end

    if #args >= 2 and args[2]:any('save') then
        settings.save_job_settings(clicky.settings, last_job_id)
        print('Settings saved manually.')
        return
    end

    print(chat.header(addon.name):append(chat.error('Usage: /clicky [show|hide|addnew|edit] [on|off] [window_id]')))
end

return {
    handle_command = handle_command
}
