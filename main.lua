addon.name      = 'Clicky'
addon.author    = 'Oxos'
addon.version   = '1.0'
addon.desc      = 'Customizable Buttons for Final Fantasy XI.'

require('common')
local imgui = require('imgui')
local d3d = require('d3d8')
local ffi = require('ffi')
local images = require("images")
local timer = require("timer")
local chat = require('chat')

-- Load custom modules
local settings = require('clicky_settings')
local render = require('clicky_render')
local commands = require('clicky_commands')
local utils = require('clicky_utils')

local guiimages = images.loadTextures()

-- Clicky Variables
local clicky = {
    settings = settings.initial_load_settings()
}

local last_time = os.clock()
local isRendering = true
local last_job_id = nil

local function job_change_cb()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    if not player then
        print('Error: Unable to get player memory manager')
        return
    end

    local job_id = player:GetMainJob()
    if job_id ~= last_job_id then
        if last_job_id then
            settings.save_job_settings(clicky.settings, last_job_id)
        end

        clicky.settings = settings.load_job_settings(job_id)
        last_job_id = job_id
        render.update_window_positions(clicky.settings.windows)
    end
end

ashita.events.register('d3d_present', 'present_cb', function()
    job_change_cb()
    
    local current_time = os.clock()
    local dt = current_time - last_time
    last_time = current_time

    timer.Check(dt)
    if isRendering then
        for _, window in ipairs(clicky.settings.windows) do
            render.render_buttons_window(window, clicky.settings, last_job_id)
        end
        render.render_edit_window(clicky.settings, last_job_id)
        render.render_info_window()
        imgui.Render()
    end
end)

ashita.events.register('command', 'command_cb', function (e)
    commands.handle_command(e, clicky, last_job_id)
end)

ashita.events.register('unload', 'unload_cb', function ()
    if last_job_id then
        settings.save_job_settings(clicky.settings, last_job_id)
    end
end)

for _, window in ipairs(clicky.settings.windows) do
    render.UpdateVisibility(window.id, window.visible, clicky.settings, last_job_id)
end
isRendering = true
