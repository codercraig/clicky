local settings = require('settings')
local jobIconMapping = {
    [1] = 'WAR',
    [2] = 'MNK',
    [3] = 'WHM',
    [4] = 'BLM',
    [5] = 'RDM',
    [6] = 'THF',
    [7] = 'PLD',
    [8] = 'DRK',
    [9] = 'BST',
    [10] = 'BRD',
    [11] = 'RNG',
    [12] = 'SAM',
    [13] = 'NIN',
    [14] = 'DRG',
    [15] = 'SMN',
    [16] = 'BLU',
    [17] = 'COR',
    [18] = 'PUP',
    [19] = 'DNC',
    [20] = 'SCH',
    [21] = 'RUN',
    [22] = 'GEO',
}

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
                { commands = { { command = "/clicky edit on", delay = 0 } }, name = "EditON", pos = { x = 0, y = 1 } },
                { commands = { { command = "/clicky edit off", delay = 0 } }, name = "EditOff", pos = { x = 0, y = 2 } },
                { commands = { { command = "/clicky addnew", delay = 0 } }, name = "NewGUI", pos = { x = 0, y = 3 } }
            },
            requires_target = false
        },
        {
            id = 2,
            visible = true,
            opacity = 1.0,
            window_pos = { x = 61, y = 640 },
            buttons = {
                { commands = { { command = "!mog", delay = 0 } }, name = "Mog", pos = { x = 0, y = 1 } },
                { commands = { { command = "!chef", delay = 0 } }, name = "Chef", pos = { x = 0, y = 2 } },
                { commands = { { command = "!points", delay = 0 } }, name = "Points", pos = { x = 0, y = 3 } }
            },
            requires_target = false
        },
        {
            id = 3,
            visible = true,
            opacity = 1.0,
            window_pos = { x = 1045, y = 450 },
            buttons = {
                { commands = { { command = "/attack", delay = 0 } }, name = "Attack", pos = { x = 0, y = 1 } },
                { commands = { { command = "/check", delay = 0 } }, name = "Check", pos = { x = 0, y = 3 } },
                { commands = { { command = "/ra <t>", delay = 0 } }, name = "RANGE", pos = { x = 0, y = 2 } }
            },
            requires_target = true
        }
    }
}

local function save_job_settings(settings_table, job)
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

return {
    save_job_settings = save_job_settings,
    load_job_settings = load_job_settings,
    initial_load_settings = initial_load_settings
}
