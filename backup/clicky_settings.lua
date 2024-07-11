function initial_load_settings()
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

function save_job_settings(settings_table, job)
    if not clicky.edit_mode then
        return
    end

    local job_name = jobIconMapping[job]
    if not job_name then
        print(string.format('Invalid job ID: %d', job))
        return
    end

    -- Ensure the settings_table is not nil or empty
    if not settings_table or not next(settings_table) then
        print('Error: settings_table is nil or empty')
        return
    end

    local settings_alias = string.format('%s_settings', job_name)
    local success, err = pcall(function()
        settings.save(settings_alias, settings_table)
    end)
    if not success then
        print(string.format('Failed to save settings for job: %s (%d), error: %s', job_name, job, err))
    else
        print(string.format('Saved settings for job: %s (%d)', job_name, job))  -- Debug print statement
    end
end

function load_job_settings(job)
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

    clicky.current_profile = string.format('%s_settings.lua', job_name)  -- Set the current profile name
    return T(loaded_settings)
end
