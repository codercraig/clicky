addon.name      = 'Clicky'
addon.author    = 'Oxos'
addon.version   = '1.0'
addon.desc      = 'Customizable Buttons for Final Fantasy XI.'

require('common')
local imgui = require('imgui')
local settings = require('settings')
local timer = require('timer')
local chat = require('chat')
--local images = require('images')
require('clicky_utils')
require('clicky_commands')
require('clicky_settings')
require('clicky_render')

--local guiimages = images.loadTextures()

-- Clicky Variables
local clicky = {
    settings = initial_load_settings(),
    isRendering = false,
    show_info_window = false,
    current_profile = "No profile loaded",
    last_job_id = nil,
    edit_mode = false,
    isEditWindowOpen = false,
    editing_button_index = nil,
    editing_window_id = nil
}

-- Initialize last time for delta time calculation
local last_time = os.clock()

ashita.events.register('d3d_present', 'present_cb', function()
    job_change_cb()
    
    -- Calculate delta time
    local current_time = os.clock()
    local dt = current_time - last_time
    last_time = current_time

    timer.Check(dt) -- Update the timer
    if clicky.isRendering then
        for _, window in ipairs(clicky.settings.windows) do
            render_buttons_window(window)
        end
        render_edit_window()
        render_info_window()  -- Render the info window
    end
end)

ashita.events.register('command', 'command_cb', function (e)
    handle_command(e)
end)

ashita.events.register('unload', 'unload_cb', function ()
    if clicky.last_job_id then
        save_job_settings(clicky.settings, clicky.last_job_id)
    end
end)

for _, window in ipairs(clicky.settings.windows) do
    UpdateVisibility(window.id, window.visible)
end
clicky.isRendering = true
