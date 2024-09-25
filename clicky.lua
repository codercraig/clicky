addon.name      = 'Clicky'
addon.author    = 'Oxos'
addon.version   = '1.0'
addon.desc      = 'Customizable Buttons for Final Fantasy XI.'

require('common')
local imgui = require('imgui')
local settings = require('settings')
local d3d = require('d3d8')
local ffi = require('ffi')
local timer = require("timer")
local chat = require('chat')

-- Define dark blue style
local darkBluePfStyles = {
    {ImGuiCol_Text, {1.0, 1.0, 1.0, 1.0}}, -- White text
    {ImGuiCol_TextDisabled, {0.5, 0.5, 0.5, 1.0}}, -- Grey text
    {ImGuiCol_WindowBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue background
    {ImGuiCol_ChildBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue background
    {ImGuiCol_PopupBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue background
    {ImGuiCol_Border, {0.3, 0.3, 0.3, 1.0}}, -- Grey border
    {ImGuiCol_BorderShadow, {0.0, 0.0, 0.0, 0.0}}, -- No border shadow
    {ImGuiCol_FrameBg, {0.1, 0.1, 0.3, 1.0}}, -- Dark blue frame background
    {ImGuiCol_FrameBgHovered, {0.2, 0.2, 0.4, 1.0}}, -- Lighter blue when hovered
    {ImGuiCol_FrameBgActive, {0.3, 0.3, 0.5, 1.0}}, -- Even lighter blue when active
    {ImGuiCol_TitleBg, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue title background
    {ImGuiCol_TitleBgActive, {0.1, 0.1, 0.3, 1.0}}, -- Lighter blue when active
    {ImGuiCol_TitleBgCollapsed, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue when collapsed
    {ImGuiCol_Button, {0.1, 0.1, 0.3, 1.0}}, -- Dark blue button
    {ImGuiCol_ButtonHovered, {0.2, 0.2, 0.4, 1.0}}, -- Lighter blue button when hovered
    {ImGuiCol_ButtonActive, {0.3, 0.3, 0.5, 1.0}}, -- Even lighter blue button when active
    {ImGuiCol_Header, {0.0, 0.0, 0.2, 1.0}}, -- Dark blue header
    {ImGuiCol_HeaderHovered, {0.2, 0.2, 0.4, 1.0}}, -- Lighter blue header when hovered
    {ImGuiCol_HeaderActive, {0.3, 0.3, 0.5, 1.0}}, -- Even lighter blue header when active
}

-- Push and pop style functions
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

-- Job mapping
local jobIconMapping = {
    [1] = 'WAR', [2] = 'MNK', [3] = 'WHM', [4] = 'BLM',
    [5] = 'RDM', [6] = 'THF', [7] = 'PLD', [8] = 'DRK',
    [9] = 'BST', [10] = 'BRD', [11] = 'RNG', [12] = 'SAM',
    [13] = 'NIN', [14] = 'DRG', [15] = 'SMN', [16] = 'BLU',
    [17] = 'COR', [18] = 'PUP', [19] = 'DNC', [20] = 'SCH',
    [21] = 'GEO', [22] = 'RUN',
}

-- Default settings
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
                { 
                    commands = { { command = "/clicky edit on", delay = 0 } }, 
                    right_click_commands = {}, -- Placeholder for right-click commands
                    middle_click_commands = {}, -- Placeholder for middle-click commands
                    name = "EditON", 
                    pos = { x = 0, y = 1 } 
                },
                { 
                    commands = { { command = "/clicky edit off", delay = 0 } }, 
                    right_click_commands = {}, 
                    middle_click_commands = {}, 
                    name = "EditOff", 
                    pos = { x = 0, y = 2 } 
                },
                { 
                    commands = { }, 
                    right_click_commands = {},  
                    middle_click_commands = {{ command = "/clicky addnew", delay = 0 }}, 
                    name = "NewGUI", 
                    pos = { x = 0, y = 3 } 
                }
            },
            requires_target = false
        },
        {
            id = 2,
            visible = true,
            opacity = 1.0,
            window_pos = { x = 61, y = 640 },
            buttons = {
                { 
                    commands = {}, 
                    right_click_commands = {}, 
                    middle_click_commands = {{ command = "!mog", delay = 0 }}, 
                    name = "Mog", 
                    pos = { x = 0, y = 1 } 
                },
                { 
                    commands = {}, 
                    right_click_commands = {}, 
                    middle_click_commands = {{ command = "!chef", delay = 0 }}, 
                    name = "Chef", 
                    pos = { x = 0, y = 2 } 
                },
                { 
                    commands = {}, 
                    right_click_commands = {}, 
                    middle_click_commands = {{ command = "!points", delay = 0 }}, 
                    name = "Points", 
                    pos = { x = 0, y = 3 } 
                }
            },
            requires_target = false
        }
    }
}

local last_job_id = nil -- Track the last job ID
local isRendering = false -- Track if rendering should occur
local editing_button_index = nil -- Index of the button being edited
local isEditWindowOpen = false -- Track if the edit window is open
local editing_window_id = nil -- Track which window is being edited
local edit_mode = false -- Track if edit mode is active

local show_info_window = false
local current_profile = "No profile loaded"  -- Variable to hold the name of the currently loaded profile

-- Render info window
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

-- Save job settings
local function save_job_settings(settings_table, job)
    if not edit_mode then return end

    if job == nil then
        print('Error: job ID is nil in save_job_settings')
        return
    end

    local job_name = jobIconMapping[job]
    if not job_name then
        print(string.format('Invalid job ID: %s', tostring(job)))
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


-- Load job settings
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

-- Initial settings load
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

-- Clicky Variables
local clicky = {
    settings = initial_load_settings()
}

local function UpdateVisibility(window_id, visible)
    for _, window in ipairs(clicky.settings.windows) do
        if window.id == window_id then
            window.visible = visible
            if last_job_id then
                save_job_settings(clicky.settings, last_job_id)
            end
            return
        end
    end
end

-- Execute commands
local function execute_commands(commands)
    if not commands or #commands == 0 then
        print("No commands to execute.")
        return
    end

    local index = 1

    local function execute_next_command()
        if index <= #commands then
            local command = commands[index]
            -- Debug print the command before execution
            --print("Executing Command:", command.command)

            
            AshitaCore:GetChatManager():QueueCommand(1, command.command)
            index = index + 1
            if index <= #commands then
                local delay = command.delay or 0
                if delay > 0 then
                    timer.Simple(delay, execute_next_command)
                else
                    execute_next_command()
                end
            end
        else
            print("All commands executed.")
        end
    end

    execute_next_command()
end

-- Helper functions
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

local function button_exists_at_position(buttons, pos)
    for _, button in ipairs(buttons) do
        if button.pos.x == pos.x and button.pos.y == pos.y then
            return true
        end
    end
    return false
end

local function get_player_main_job()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    return player:GetMainJob()
end

local seacom = {
    name_buffer = { '' },
    name_buffer_size = 128,
    command_buffer = { '' },
    command_buffer_size = 256,
}

local settings_buffers = {
    requires_target = { false }
}

-- Define the dropdown options
local action_types = { "Attack","Magic", "Abilities", "Weapon Skills","Ranged", "Pet", "Equipset", "Items","Alt Magic", "Alt Abilities", "Alt Weapon Skills", "Alt Attack"}

local action_type_map = {
    ["Attack"] = "/attack",
    ["Magic"] = "/ma",
    ["Abilities"] = "/ja",
    ["Weapon Skills"] = "/ws",
    ["Ranged"] = "/ra",
    ["Pet"] = "/pet",
    ["Equipset"] = "/equipset",
    ["Items"] = "/item",
    -- Dual Boxing - Requires Multisend Addon
    ["Alt Magic"] = "/mso /ma",
    ["Alt Abilities"] = "/mso /ja",
    ["Alt Weapon Skills"] = "/mso /ws",
    ["Alt Attack"] = "/mso /attack"
}

-- Define the target options
local targets = {"", "Self", "Target","Select Target","Party#0", "Party#1", "Party#2", "Party#3", "Party#4", "Party#5","AltTarget","AltParty#0","AltParty#1","AltParty#2","AltParty#3","AltParty#4","AltParty#5","Sub Target (Party)", "Sub Target (Party Target)", "Alliance", "on", "off" }

local target_map = {
    [""] = "",
    ["Self"] = "<me>",
    ["Target"] = "<t>",
    ["Select Target"] = "<st>",
    ["Party#0"] = "<p0>",
    ["Party#1"] = "<p1>",
    ["Party#2"] = "<p2>",
    ["Party#3"] = "<p3>",
    ["Party#4"] = "<p4>",
    ["Party#5"] = "<p5>",
    ["AltTarget"] = "[t]",
    ["AltParty#0"] = "[p0]",
    ["AltParty#1"] = "[p1]",
    ["AltParty#2"] = "[p2]",
    ["AltParty#3"] = "[p3]",
    ["AltParty#4"] = "[p4]",
    ["AltParty#5"] = "[p5]",
    ["Sub Target (Party)"] = "<stpc>",
    ["Sub Target (Party Target)"] = "<stpt>",
    ["Alliance"] = "<stal>",
    ["on"] = "on",
    ["off"] = "off"
}

-- Initialize combined lists for spells and abilities
local combined_spells = { "" }  -- Start with an empty string to prevent nil index errors
local combined_abilities = { "" }  -- Same here

local function get_job_spells_and_abilities(job_id)
    local spells = {}
    local abilities = {}
    local weaponskills = {}

    if job_id == 3 then -- WHM
        spells = {
            "","Cure", "Cure II", "Cure III", "Cure IV", "Cure V", "Curaga", "Curaga II", "Curaga III",
            "Raise", "Raise II", "Reraise", "Reraise II", "Poisona", "Paralyna", "Blindna", "Silena",
            "Stona", "Viruna", "Cursna", "Dia", "Dia II", "Banish", "Banish II", "Banish III", 
            "Banishga", "Banishga II", "Diaga", "Holy", "Holy II", "Protect", "Protect II", "Protect III", 
            "Protect IV", "Shell", "Shell II", "Shell III", "Shell IV", "Regen", "Regen II", "Regen III",
            "Regen IV", "Auspice", "Erase", "Haste", "Barstonra", "Barwatera", "Baraera", "Barfira",
            "Barblizzara", "Barthundra", "Barstone", "Barwater", "Baraero", "Barfire", "Barblizzard", 
            "Barthunder", "Barpoison", "Barparalyze", "Barsleep", "Barblind", "Barsilence", "Barpetrify",
            "Barvirus", "Boost", "Aquaveil", "Stoneskin", "Blink", "Deodorize", "Sneak", 
            "Invisible", "Teleport-Mea", "Teleport-Dem", "Teleport-Holla", 
            "Teleport-Altep", "Teleport-Yhoat", "Teleport-Vahzl",
            "Protectra", "Protectra II", "Protectra III", "Protectra IV", "Shellra", "Shellra II", 
            "Shellra III", "Shellra IV", "Reraise III", "Enlight"
        }

        abilities = {
            "",
            "Benediction",
            "Divine Seal",
            "Afflatus Solace",
            "Afflatus Misery",
            "Devotion",
            "Martyr",
        }

        weaponskills = {
            "",  -- Include any relevant WS for WHM here
        }

    elseif job_id == 4 then -- BLM
        spells = {
            "","Stone","Stone", "Water", "Aero", "Fire", "Blizzard", "Thunder", "Stone II", "Water II",
            "Aero II", "Fire II", "Blizzard II", "Thunder II", "Stone III", "Water III", "Aero III",
            "Fire III", "Blizzard III", "Thunder III", "Blizzard IV","Thunder IV","Fire IV","Water IV",
            "Stonega", "Waterga", "Aeroga", "Firaga", "Blizzaga", "Thundaga", "Stonega II", "Waterga II",
            "Aeroga II", "Firaga II", "Blizzaga II", "Thundaga II", "Poison", "Poison II", "Poisonga", 
            "Bio", "Bio II", "Drain", "Aspir", "Warp", "Warp II", "Escape", "Tractor", "Sleep", "Sleep II",
            "Bind", "Dispel", "Stun","Freeze", "Freeze II", "Burst", "Burst II", "Flare", "Flare II", "Tornado",
            "Tornado II", "Flood", "Flood II",
        }

        abilities = {
            "",
            "Manafont",
            "Elemental Seal",
            "Tranquil Heart",
        }

        weaponskills = {
            "",  -- Include any relevant WS for BLM here
        }

    elseif job_id == 15 then -- SMN (Summoner)
        spells = {
            "","Fire Spirit", "Ice Spirit", "Air Spirit", "Earth Spirit", "Thunder Spirit", "Water Spirit",
            "Light Spirit", "Dark Spirit", "Carbuncle", "Ifrit", "Shiva", "Garuda", "Titan", "Ramuh", 
            "Leviathan", "Fenrir", "Diabolos"
        }

        abilities = {
            "",
            "Assault",
            "Release",
            "Retreat",
            "Avatar's Favor",
            "Mana Cede",
            "Elemental Siphon",
            "Apogee",
            -- Level 65 Pet Abilities
            "Eclipse Bite",  -- Fenrir
            "Nether Blast",  -- Diabolos
            -- Level 70 Pet Abilities
            "Flaming Crush",  -- Ifrit
            "Mountain Buster", -- Titan
            "Spinning Dive",  -- Leviathan
            "Predator Claws",  -- Garuda
            "Rush",           -- Shiva
            "Chaotic Strike"  -- Ramuh
        }

        weaponskills = {
            "",  -- Empty string to prevent nil index errors
            "Shining Strike",  -- Club
            "Seraph Strike",   -- Club
            "Earth Crusher",   -- Staff
            "Starburst",       -- Staff
            "Sunburst",        -- Staff
            "Full Swing",      -- Staff
            "Spirit Taker",    -- Staff
            "Retribution",     -- Staff
            "Gate of Tartarus", -- Staff (Mythic Weapon)
        }
    elseif job_id == 1 then -- WAR (Warrior)
        spells = {}  -- Warriors do not have spells
        abilities = {
            "", "Provoke", "Berserk", "Defender", "Aggressor", "Warcry", "Retaliation", "Restraint", "Warrior's Charge"
        }
        weaponskills = {
            "", "Raging Axe", "Smash Axe", "Rampage", "Decimation", "Full Break", "Steel Cyclone", "Fell Cleave"
        }

    elseif job_id == 2 then -- MNK (Monk)
    spells = {}  -- Monks do not have spells
    abilities = {
        "", "Hundred Fists", "Boost", "Dodge", "Focus", "Counterstance", "Chi Blast", "Perfect Counter", "Formless Strikes", "Impetus", "Footwork"
    }
    weaponskills = {
        "","Shijin Spiral", "Asuran Fists", "Raging Fists", "Howling Fist", "Dragon Kick", "Tornado Kick", "Final Heaven"
    }

    elseif job_id == 5 then -- RDM (Red Mage)
        spells = {
            "", "Cure", "Cure II", "Cure III", "Dia", "Dia II", "Dia III", "Paralyze", "Paralyze II", "Slow", "Slow II", 
            "Phalanx", "Phalanx II", "Enfire", "Enblizzard", "Enaero", "Enstone", "Enthunder", "Enwater", 
            "Refresh", "Refresh II", "Haste", "Dispel", "Bio", "Bio II", "Bio III", "Sleep", "Sleep II", 
            "Blind", "Bind", "Gravity", "Poison", "Poison II", "Paralyze", "Paralyze II", "Silence", 
            "Dispel", "Barstonra", "Barwatera", "Baraera", "Barfira", "Barblizzara", "Barthundra", 
            "Protect", "Protect II", "Shell", "Shell II", "Raise", "Raise II", "Reraise"
        }
        abilities = {
            "", "Chainspell"
        }
        weaponskills = {
            "", "Savage Blade", "Chant du Cygne", "Death Blossom"
        }

    elseif job_id == 6 then -- THF (Thief)
        spells = {}  -- Thieves do not have spells
        abilities = {
            "", "Steal", "Flee", "Hide", "Mug", "Sneak Attack", "Trick Attack", "Assassin's Charge", "Feint", "Conspirator", "Collaborator"
        }
        weaponskills = {
            "", "Dancing Edge", "Evisceration", "Shark Bite", "Mandalic Stab", "Mercy Stroke", "Exenterator"
        }

    elseif job_id == 7 then -- PLD (Paladin)
        spells = {
            "", "Cure", "Cure II", "Cure III", "Dia", "Banish", "Banish II", "Protect", "Protect II", 
            "Shell", "Shell II", "Flash", "Enlight", "Holy", "Reprisal", "Phalanx", "Regen", "Raise", "Reraise"
        }
        abilities = {
            "", "Invincible", "Shield Bash", "Sentinel", "Cover", "Rampart", "Fealty", "Chivalry"
        }
        weaponskills = {
            "", "Swift Blade", "Vorpal Blade", "Savage Blade", "Knights of Round", "Atonement"
        }

    elseif job_id == 8 then -- DRK (Dark Knight)
        spells = {
            "", "Bio", "Bio II", "Drain", "Aspir", "Absorb-STR", "Absorb-DEX", "Absorb-VIT", 
            "Absorb-AGI", "Absorb-INT", "Absorb-MND", "Absorb-CHR", "Stun"
        }
        abilities = {
            "", "Soul Eater", "Arcane Circle", "Weapon Bash", "Last Resort", "Dark Seal", "Blood Weapon"
        }
        weaponskills = {
            "", "Spinning Slash", "Cross Reaper", "Guillotine", "Insurgency", "Quietus", "Entropy"
        }

    elseif job_id == 9 then -- BST (Beastmaster)
        spells = {}  -- Beastmasters do not have spells
        abilities = {
            "", "Charm", "Call Beast", "Familiar", "Killer Instinct", "Feral Howl", "Unleash"
        }
        weaponskills = {
            "", "Rampage", "Calamity", "Decimation", "Onslaught"
        }

    elseif job_id == 10 then -- BRD (Bard)
        spells = {}  -- Bards do not have traditional spells
        abilities = {
            "", "Soul Voice", "Nightingale", "Troubadour"
        }
        weaponskills = {
            "", "Mordant Rime", "Evisceration"
        }

    elseif job_id == 11 then -- RNG (Ranger)
        spells = {}  -- Rangers do not have spells
        abilities = {
            "", "Eagle Eye Shot", "Sharpshot", "Barrage", "Camouflage", "Scavenge", "Unlimited Shot"
        }
        weaponskills = {
            "", "Sidewinder", "Slug Shot", "Arching Arrow", "Coronach", "Jishnu's Radiance"
        }

    elseif job_id == 12 then -- SAM (Samurai)
        spells = {}  -- Samurais do not have spells
        abilities = {
            "", "Meikyo Shisui", "Third Eye", "Meditate", "Seigan", "Hasso", "Sekkanoki", "Konzen-ittai"
        }
        weaponskills = {
            "", "Tachi: Gekko", "Tachi: Kasha", "Tachi: Kagero", "Tachi: Enpi", "Tachi: Yukikaze", "Tachi: Shoha"
        }

    elseif job_id == 13 then -- NIN (Ninja)
        spells = {
            "", "Utsusemi: Ichi", "Utsusemi: Ni", "Jubaku: Ichi", "Hojo: Ichi", "Kurayami: Ichi", 
            "Dokumori: Ichi", "Katon: Ichi", "Hyoton: Ichi", "Huton: Ichi", "Doton: Ichi", "Suiton: Ichi", 
            "Raiton: Ichi", "Katon: Ni", "Hyoton: Ni", "Huton: Ni", "Doton: Ni", "Suiton: Ni", "Raiton: Ni"
        }
        abilities = {
            "", "Mijin Gakure", "Provoke", "Yonin", "Innin", "Futae", "Issekigan"
        }
        weaponskills = {
            "", "Blade: Jin", "Blade: Ku", "Blade: Kamu", "Blade: Ten"
        }

    elseif job_id == 14 then -- DRG (Dragoon)
        spells = {}  -- Dragoons do not have spells
        abilities = {
            "", "Jump", "High Jump", "Super Jump", "Spirit Jump", "Soul Jump", "Call Wyvern", "Spirit Link"
        }
        weaponskills = {
            "", "Drakesbane", "Impulse Drive", "Geirskogul"
        }

    elseif job_id == 16 then -- BLU (Blue Mage)
        spells = {
            "", "Pollen", "Cocoon", "Cursed Sphere", "Death Ray", "Bludgeon", "Refueling", "Metallic Body", 
            "Screwdriver", "Sprout Smack", "Head Butt", "Queasyshroom", "Battle Dance", "Magic Fruit"
        }
        abilities = {
            "", "Azure Lore"
        }
        weaponskills = {
            "", "Chant du Cygne", "Expiacion", "Savage Blade"
        }

    elseif job_id == 17 then -- COR (Corsair)
        spells = {}  -- Corsairs do not have traditional spells
        abilities = {
            "", "Double-Up", "Random Deal", "Fold", "Snake Eye", "Wild Card", "Quick Draw", "Cutting Cards"
        }
        weaponskills = {
            "", "Leaden Salute", "Wildfire", "Last Stand"
        }

    elseif job_id == 18 then -- PUP (Puppetmaster)
        spells = {}  -- Puppetmasters do not have spells
        abilities = {
            "", 
            "Overdrive", 
            "Activate", 
            "Deactivate", 
            "Repair", 
            "Deus Ex Automata", 
            "Deploy", 
            "Retrieve", 
            "Maintenance", 
            "Ventriloquy", 
            "Role Reversal",
            "",
            -- Adding Puppetmaster Maneuvers
            "Fire Maneuver", 
            "Ice Maneuver", 
            "Wind Maneuver", 
            "Earth Maneuver", 
            "Thunder Maneuver", 
            "Water Maneuver", 
            "Light Maneuver", 
            "Dark Maneuver"
        }
        weaponskills = {
            "",
            "Combo",
            "Shoulder Tackle",
            "Stringing Pummel",
            "Victory Smite",
            "String Shredder",
            "Shijin Spiral",
            "Asuran Fists"
        }

    elseif job_id == 19 then -- DNC (Dancer)
        spells = {}  -- Dancers do not have spells
        abilities = {
            "", "Trance", "Step", "Flourish", "Waltz", "Drain Samba","Drain Samba II","Spectral Jig", "No Foot Rise", "Climactic Flourish"
        }
        weaponskills = {
            "", "Evisceration", "Pyrrhic Kleos"
        }

    elseif job_id == 20 then -- SCH (Scholar)
        spells = {
            "", "Stone", "Water", "Aero", "Fire", "Blizzard", "Thunder", "Cure", "Cure II", "Regen", 
            "Drain", "Aspir", "Sleep", "Sleep II", "Stonega", "Waterga", "Aeroga", "Firaga", "Blizzaga", 
            "Thundaga", "Sandstorm", "Rainstorm", "Windstorm", "Firestorm", "Hailstorm", "Thunderstorm"
        }
        abilities = {
            "", "Tabula Rasa", "Light Arts", "Dark Arts", "Manifestation", "Accession", "Altruism", "Focalization"
        }
        weaponskills = {
            "", "Omniscience", "Cataclysm", "Myrkr"
        }

    elseif job_id == 21 then -- GEO (Geomancer)
        spells = {
            "", "Indi-Barrier", "Indi-Acumen", "Indi-Fend", "Indi-Precision", "Indi-Refresh", 
            "Indi-Fury", "Indi-Focus", "Indi-Wilt", "Indi-Vex", "Indi-Haste", "Indi-Fade"
        }
        abilities = {
            "", "Bolster", "Collimated Fervor", "Life Cycle", "Blaze of Glory", "Dematerialize"
        }
        weaponskills = {
            "", "Exudation", "Realmrazer"
        }

    elseif job_id == 22 then -- RUN (Rune Fencer)
        spells = {
            "", "Inspire", "Vivacious Pulse", "Ignis", "Gelus", "Flabra", "Tellus", "Sulpor", "Unda", 
            "Lux", "Tenebrae", "Vallation", "Valiance", "Liement", "Gambit", "Rayke"
        }
        abilities = {
            "", "One for All", "Battuta", "Elemental Sforzo", "Sleight of Sword", "Swordplay"
        }
        weaponskills = {
            "", "Resolution", "Dimidiation", "Requiescat"
        }
    end


    return spells, abilities, weaponskills
end


-- Function to retrieve spells available for a given job
local function get_job_spells(job_id)
    local job_spells, _, _ = get_job_spells_and_abilities(job_id)
    local spell_dict = {}
    for _, spell_name in ipairs(job_spells) do
        spell_dict[spell_name] = true
    end
    return spell_dict
end

local function fetch_available_spells_with_jobs()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    local main_job_spells = {}
    local sub_job_spells = {}

    if not player then
        print("Error: Unable to access player memory manager.")
        return {}
    end

    -- Get player's main job and sub job
    local main_job_id = player:GetMainJob()
    local sub_job_id = player:GetSubJob()

    -- Retrieve the spells associated with the main job and sub job
    local main_job_spell_dict = get_job_spells(main_job_id)
    local sub_job_spell_dict = get_job_spells(sub_job_id)

    -- Iterate through all possible spell IDs
    for spellId = 1, 1024 do
        -- Get the spell resource by ID
        local spell = AshitaCore:GetResourceManager():GetSpellById(spellId)

        if spell and spell.Name then
            local spell_name = spell.Name[1]

            -- Check if the player knows the spell and if it's a main job spell
            if player:HasSpell(spell.Index) then
                if main_job_spell_dict[spell_name] then
                    table.insert(main_job_spells, spell_name)
                elseif sub_job_spell_dict[spell_name] then
                    table.insert(sub_job_spells, spell_name)
                end
            end
        end
    end

    -- Combine main job spells first, then subjob spells
    local combined_spells = {}
    local seen_spells = {}

    for _, spell_name in ipairs(main_job_spells) do
        if not seen_spells[spell_name] then
            table.insert(combined_spells, spell_name)
            seen_spells[spell_name] = true
        end
    end

    for _, spell_name in ipairs(sub_job_spells) do
        if not seen_spells[spell_name] then
            table.insert(combined_spells, spell_name)
            seen_spells[spell_name] = true
        end
    end

    -- Return the ordered and deduplicated list of spells
    return combined_spells
end

local function update_spells_and_abilities()
    -- Clear the existing lists
    combined_spells = { "" }  -- Start with an empty string to prevent nil index errors
    combined_abilities = { "" }  -- Start with an empty string to prevent nil index errors
    combined_weaponskills = { "" }  -- Start with an empty string to prevent nil index errors

    local player = AshitaCore:GetMemoryManager():GetPlayer()
    if not player then return end

    local main_job_id = player:GetMainJob()
    local sub_job_id = player:GetSubJob()

    -- Get dynamically fetched spells for the player based on job and subjob
    local available_spells = fetch_available_spells_with_jobs()

    -- Get job-specific spells, abilities, and weapon skills
    local main_spells, main_abilities, main_weaponskills = get_job_spells_and_abilities(main_job_id)
    local sub_spells, sub_abilities, sub_weaponskills = get_job_spells_and_abilities(sub_job_id)

    -- Helper function to check if a spell, ability, or weapon skill exists in the reference list
    local function exists_in_reference(item, reference)
        for _, ref_item in ipairs(reference) do
            if ref_item == item then
                return true
            end
        end
        return false
    end

    -- Add dynamically fetched spells to combined_spells if they exist in the reference list for the main or sub job
    if available_spells then
        for _, spell in ipairs(available_spells) do
            if exists_in_reference(spell, main_spells) or exists_in_reference(spell, sub_spells) then
                table.insert(combined_spells, spell)
            end
        end
    end

    -- Abilities are already fetched and can be added directly if they exist in the reference list for the main or sub job
    if main_abilities then
        for _, ability in ipairs(main_abilities) do
            if exists_in_reference(ability, main_abilities) then
                table.insert(combined_abilities, ability)
            end
        end
    end
    if sub_abilities then
        for _, ability in ipairs(sub_abilities) do
            if exists_in_reference(ability, sub_abilities) then
                table.insert(combined_abilities, ability)
            end
        end
    end

    -- Add weapon skills to combined_weaponskills if they exist in the reference list for the main or sub job
    if main_weaponskills then
        for _, weaponskill in ipairs(main_weaponskills) do
            if exists_in_reference(weaponskill, main_weaponskills) then
                table.insert(combined_weaponskills, weaponskill)
            end
        end
    end
    if sub_weaponskills then
        for _, weaponskill in ipairs(sub_weaponskills) do
            if exists_in_reference(weaponskill, sub_weaponskills) then
                table.insert(combined_weaponskills, weaponskill)
            end
        end
    end
end


local equipsets = {}
for i = 1, 200 do
    table.insert(equipsets, tostring(i))
end

-- Variables to store the selected options
local selected_action_type = 1
local selected_spell = 1
local selected_target = 1

local spell_search_input = ""  -- For search box
local search_input = { "" } -- Initialize the search input as a table with an empty string

-- Check the data has been updated properly based on players main/subjob
local update_triggered = false

local function update_command(button, is_right_click)
    -- Ensure the states are initialized
    if not button.action_type_states then button.action_type_states = {} end
    if not button.spell_states then button.spell_states = {} end
    if not button.target_states then button.target_states = {} end
    if not button.equipset_states then button.equipset_states = {} end

    -- Right-click states
    if is_right_click then
        if not button.right_click_action_type_states then button.right_click_action_type_states = {} end
        if not button.right_click_spell_states then button.right_click_spell_states = {} end
        if not button.right_click_target_states then button.right_click_target_states = {} end
        if not button.right_click_equipset_states then button.right_click_equipset_states = {} end
    end

    local commands = is_right_click and button.right_click_commands or button.commands
    local action_type_states = is_right_click and button.right_click_action_type_states or button.action_type_states
    local spell_states = is_right_click and button.right_click_spell_states or button.spell_states
    local target_states = is_right_click and button.right_click_target_states or button.target_states
    local equipset_states = is_right_click and button.right_click_equipset_states or button.equipset_states

    for cmdIndex, _ in ipairs(commands) do
        local action_type = action_types[action_type_states[cmdIndex]]
        local command_string

        if action_type == "Equipset" then
            -- Handle Equipset commands
            local equipset_number = equipset_states[cmdIndex] and equipset_states[cmdIndex][1]
            if equipset_number then
                command_string = string.format('/equipset %d', equipset_number)
            else
                command_string = nil -- Mark as invalid
            end
        elseif action_type == "Attack" or action_type == "Ranged" then
            -- Handle Attack commands
            command_string = string.format('%s %s', action_type_map[action_type], target_map[targets[target_states[cmdIndex]]])
        elseif action_type == "Magic" or action_type == "Alt Magic" then
            -- Handle Magic commands
            local spell_name = combined_spells[spell_states[cmdIndex]]
            if not spell_name or spell_name == "" then
                -- If the spell field is empty, trigger the update once to check that its meant to be empty.. 
                -- This could be caused by r0 or crashes, just a sanity check so player doesnt panic.
                if not update_triggered then
                    update_spells_and_abilities()
                    update_triggered = true
                end
            end

            command_string = spell_name and string.format('%s "%s" %s', action_type_map[action_type], spell_name or "", target_map[targets[target_states[cmdIndex]]])
        elseif action_type == "Abilities" or action_type == "Alt Abilities" then
            -- Handle Abilities commands
            local ability_name = combined_abilities[spell_states[cmdIndex]]
            if not ability_name or ability_name == "" then
                -- If the ability field is empty, trigger the update once
                if not update_triggered then
                    update_spells_and_abilities()
                    update_triggered = true
                end
            end
            command_string = ability_name and string.format('%s "%s" %s', action_type_map[action_type], ability_name or "", target_map[targets[target_states[cmdIndex]]])
        elseif action_type == "Weapon Skills" or action_type == "Alt Weapon Skills" then
            -- Handle Weapon Skills commands
            local weaponskill_name = combined_weaponskills[spell_states[cmdIndex]]
            if not weaponskill_name or weaponskill_name == "" then
                -- If the weaponskill field is empty, trigger the update once
                if not update_triggered then
                    update_spells_and_abilities()
                    update_triggered = true
                end
            end
            command_string = weaponskill_name and string.format('%s "%s" %s', action_type_map[action_type], weaponskill_name or "", target_map[targets[target_states[cmdIndex]]])
        else
            -- For any other types, just use the basic command structure (this can be adjusted as needed)
            command_string = string.format('%s "%s" %s', action_type_map[action_type], spell_states[cmdIndex] or "", target_map[targets[target_states[cmdIndex]]])
        end

        -- Check if the command_string is invalid
        if not command_string or command_string:find('""') or command_string:find('nil') then
            print("Empty button - Nothing running...")
        else
            -- Update the command in the list
            commands[cmdIndex].command = command_string
        end
    end
end

local function render_edit_window()
    if isEditWindowOpen and editing_button_index ~= nil then
        local window = clicky.settings.windows[editing_window_id]
        local button = window.buttons[editing_button_index]

        -- Initialize commands if they don't exist
        if not button.commands then button.commands = {} end
        if not button.right_click_commands then button.right_click_commands = {} end
        if not button.middle_click_commands then button.middle_click_commands = {} end

        -- Ensure individual states are initialized for each command
        if not button.action_type_states then button.action_type_states = {} end
        if not button.spell_states then button.spell_states = {} end
        if not button.target_states then button.target_states = {} end
        if not button.search_inputs then button.search_inputs = {} end
        if not button.delays then button.delays = {} end
        if not button.equipset_states then button.equipset_states = {0} end

        -- Initialize right-click specific states
        if not button.right_click_action_type_states then button.right_click_action_type_states = {} end
        if not button.right_click_spell_states then button.right_click_spell_states = {} end
        if not button.right_click_target_states then button.right_click_target_states = {} end
        if not button.right_click_search_inputs then button.right_click_search_inputs = {} end
        if not button.right_click_delays then button.right_click_delays = {} end
        if not button.right_click_equipset_states then button.right_click_equipset_states = {0} end

        -- Initialize middle-click specific states
        if not button.middle_click_commands then button.middle_click_commands = {} end
        if not button.middle_click_search_inputs then button.middle_click_search_inputs = {} end
        if not button.middle_click_delays then button.middle_click_delays = {} end

        -- Initialize states based on existing commands
        -- Loop over each command to ensure all relevant states are initialized for main (left-click) commands
        for i = 1, #button.commands do
            button.action_type_states[i] = button.action_type_states[i] or selected_action_type
            button.spell_states[i] = button.spell_states[i] or selected_spell
            button.target_states[i] = button.target_states[i] or selected_target
            button.search_inputs[i] = button.search_inputs[i] or { "" }
            button.delays[i] = button.delays[i] or { tostring(button.commands[i].delay or 0) }
            button.equipset_states[i] = button.equipset_states[i] or {0}
        end

        -- Loop over each command to ensure all relevant states are initialized for right-click commands
        for i = 1, #button.right_click_commands do
            button.right_click_action_type_states[i] = button.right_click_action_type_states[i] or selected_action_type
            button.right_click_spell_states[i] = button.right_click_spell_states[i] or selected_spell
            button.right_click_target_states[i] = button.right_click_target_states[i] or selected_target
            button.right_click_search_inputs[i] = button.right_click_search_inputs[i] or { "" }
            button.right_click_delays[i] = button.right_click_delays[i] or { tostring(button.right_click_commands[i].delay or 0) }
            button.right_click_equipset_states[i] = button.right_click_equipset_states[i] or {0}
        end

        -- Loop over each command to ensure all relevant states are initialized for middle-click commands
        for i = 1, #button.middle_click_commands do
            button.middle_click_search_inputs[i] = button.middle_click_search_inputs[i] or { "" }
            button.middle_click_delays[i] = button.middle_click_delays[i] or { tostring(button.middle_click_commands[i].delay or 0) }
        end

        PushStyles(darkBluePfStyles)

        if imgui.Begin('Edit Button', true, ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoTitleBar) then
            -- Save and Close Buttons
            if imgui.Button('Save', { 50, 25 }) then
                button.name = seacom.name_buffer[1]
                save_job_settings(clicky.settings, last_job_id)
                edit_mode = false
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
            
            -- Button Name
            imgui.Text('Button Name:')
            if imgui.Button('DEL', { 50, 25 }) then
                table.remove(window.buttons, editing_button_index)
                save_job_settings(clicky.settings, last_job_id)
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end
            imgui.SameLine()
            if imgui.InputText('##EditButtonName', seacom.name_buffer, seacom.name_buffer_size) then
                button.name = seacom.name_buffer[1]
            end

            imgui.Separator()
            imgui.NewLine()

            -- Left Click Commands
            imgui.Text('Left Click:')
            for cmdIndex, cmdInfo in ipairs(button.commands) do
                local filtered_spells_or_abilities = {}
                local action_type = action_types[button.action_type_states[cmdIndex]]
            
                -- Populate the appropriate list based on action type
                if action_type == "Magic" or action_type == "Alt Magic" then
                    for _, spell in ipairs(combined_spells) do
                        if button.search_inputs[cmdIndex][1] == "" or string.find(spell:lower(), button.search_inputs[cmdIndex][1]:lower()) then
                            table.insert(filtered_spells_or_abilities, spell)
                        end
                    end
                elseif action_type == "Abilities" or action_type == "Alt Abilities" then
                    for _, ability in ipairs(combined_abilities) do
                        if button.search_inputs[cmdIndex][1] == "" or string.find(ability:lower(), button.search_inputs[cmdIndex][1]:lower()) then
                            table.insert(filtered_spells_or_abilities, ability)
                        end
                    end
                elseif action_type == "Weapon Skills" or action_type == "Alt Weapon Skills" then
                    for _, weaponskill in ipairs(combined_weaponskills) do
                        if button.search_inputs[cmdIndex][1] == "" or string.find(weaponskill:lower(), button.search_inputs[cmdIndex][1]:lower()) then
                            table.insert(filtered_spells_or_abilities, weaponskill)
                        end
                    end
                elseif action_type == "Equipset" then
                    for _, equipset in ipairs(equipsets) do
                        table.insert(filtered_spells_or_abilities, equipset)
                    end
                end
            
                -- Determine the spell or ability name based on the selected index
                local spell_or_ability_name = filtered_spells_or_abilities[button.spell_states[cmdIndex]]
            
                if action_type == "Equipset" then
                    local equipset_number = button.equipset_states[cmdIndex] and button.equipset_states[cmdIndex][1]
                    if equipset_number then
                        button.commands[cmdIndex].command = string.format('/equipset %d', equipset_number)
                    else
                        print(string.format("Equipset number is not set or is invalid for command %d.", cmdIndex))
                    end
                elseif action_type == "Attack" or action_type == "Alt Attack" or action_type == "Ranged" then
                    button.commands[cmdIndex].command = string.format('%s %s', action_type_map[action_type], target_map[targets[button.target_states[cmdIndex]]] or "")
                else
                    button.commands[cmdIndex].command = string.format('%s "%s" %s', action_type_map[action_type], spell_or_ability_name or "", target_map[targets[button.target_states[cmdIndex]]])
                end

                -- Dropdown to select Action Type
                imgui.SetNextItemWidth(150)
                if imgui.BeginCombo("##ActionType"..cmdIndex, action_types[button.action_type_states[cmdIndex]] or "") then
                    for i = 1, #action_types do
                        local is_selected = (i == button.action_type_states[cmdIndex])
                        if imgui.Selectable(action_types[i], is_selected) then
                            button.action_type_states[cmdIndex] = i
                            if action_types[i] == "Equipset" then
                                cmdInfo.command = string.format('/equipset %d', button.equipset_states[cmdIndex][1])
                            else
                                cmdInfo.command = action_type_map[action_types[i]] .. " " .. (cmdInfo.spell or "") .. " " .. (cmdInfo.target or "")
                            end
                        end
                        if is_selected then
                            imgui.SetItemDefaultFocus()
                        end
                    end
                    imgui.EndCombo()
                end

                -- Equipset Dropdown
                if action_type == "Equipset" then
                    imgui.SetNextItemWidth(150)
                    imgui.SameLine()
                    if imgui.BeginCombo("##EquipsetNumber"..cmdIndex, tostring(button.equipset_states[cmdIndex][1] or 0)) then
                        for i = 1, #equipsets do
                            local is_selected = (tostring(button.equipset_states[cmdIndex][1]) == equipsets[i])
                            if imgui.Selectable(equipsets[i], is_selected) then
                                button.equipset_states[cmdIndex] = {tonumber(equipsets[i])}
                                cmdInfo.command = string.format('/equipset %d', button.equipset_states[cmdIndex][1])
                            end
                            if is_selected then
                                imgui.SetItemDefaultFocus()
                            end
                        end
                        imgui.EndCombo()
                    end
                elseif action_type == "Attack" or action_type == "Alt Attack" or action_type == "Ranged" then
                    -- Do not show spell/ability dropdown for Attack
                else
                    -- Spell/Ability Dropdown
                    imgui.SetNextItemWidth(150)
                    imgui.SameLine()
                    if imgui.BeginCombo("##Spell"..cmdIndex, spell_or_ability_name or "") then
                        for i = 1, #filtered_spells_or_abilities  do
                            local is_selected = (i == button.spell_states[cmdIndex])
                            if imgui.Selectable(filtered_spells_or_abilities [i], is_selected) then
                                button.spell_states[cmdIndex] = i
                                cmdInfo.spell = filtered_spells_or_abilities [i]
                                cmdInfo.command = action_type_map[action_types[button.action_type_states[cmdIndex]]] .. " \"" .. cmdInfo.spell .. "\" " .. target_map[targets[button.target_states[cmdIndex]]]
                            end
                            if is_selected then
                                imgui.SetItemDefaultFocus()
                            end
                        end
                        imgui.EndCombo()
                    end
                end

                -- Target Dropdown
                imgui.SetNextItemWidth(150)
                imgui.SameLine()
                if imgui.BeginCombo("##Target"..cmdIndex, targets[button.target_states[cmdIndex]] or "") then
                    for i = 1, #targets do
                        local is_selected = (i == button.target_states[cmdIndex])
                        if imgui.Selectable(targets[i], is_selected) then
                            button.target_states[cmdIndex] = i
                            cmdInfo.target = target_map[targets[i]]
                            cmdInfo.command = action_type_map[action_types[button.action_type_states[cmdIndex]]] .. " " .. (cmdInfo.spell or 1) .. " " .. cmdInfo.target
                        end
                        if is_selected then
                            imgui.SetItemDefaultFocus()
                        end
                    end
                    imgui.EndCombo()
                end

                -- Display delay input next to the command
                imgui.SetNextItemWidth(50)
                imgui.SameLine()
                if imgui.InputText('##EditButtonDelay' .. cmdIndex, button.delays[cmdIndex], 5) then
                    button.commands[cmdIndex].delay = tonumber(button.delays[cmdIndex][1]) or 0
                end
            end

            -- Add and Remove Buttons
            imgui.NewLine()
            if imgui.Button('+Add', { 110, 40 }) then
                imgui.NewLine()
                table.insert(button.commands, { command = "", delay = 0 })
                table.insert(button.action_type_states, {""})
                table.insert(button.spell_states, selected_spell)
                table.insert(button.target_states, selected_target)
                table.insert(button.search_inputs, { "" })
                table.insert(button.delays, { "0" })
                table.insert(button.equipset_states, {0})
            end
            imgui.SameLine()
            if imgui.Button('-Remove', { 110, 40 }) then
                if #button.commands > 0 then
                    table.remove(button.commands, #button.commands)
                    table.remove(button.action_type_states, #button.action_type_states)
                    table.remove(button.spell_states, #button.spell_states)
                    table.remove(button.target_states, #button.target_states)
                    table.remove(button.search_inputs, #button.search_inputs)
                    table.remove(button.delays, #button.delays)
                    table.remove(button.equipset_states, #button.equipset_states)
                end
            end
            imgui.SameLine()
            if imgui.Button('Execute', { 110, 40 }) then
                -- Reset and update button commands
                for cmdIndex, cmdInfo in ipairs(button.commands) do
                    -- Check if the action type is Equipset and update the command accordingly
                    update_command(button, false)
                end
                -- Execute the updated commands
                execute_commands(button.commands)
            end

            imgui.Separator()
            imgui.NewLine()

            -- Right Click Commands Section
            imgui.Separator()
            imgui.Text('Right Click:')
            for cmdIndex, cmdInfo in ipairs(button.right_click_commands) do
                local filtered_spells_or_abilities = {}
                local action_type = action_types[button.right_click_action_type_states[cmdIndex]]

                -- Populate the appropriate list based on action type
                if action_type == "Magic" or action_type == "Alt Magic" then
                    for _, spell in ipairs(combined_spells) do
                        if button.right_click_search_inputs[cmdIndex][1] == "" or string.find(spell:lower(), button.right_click_search_inputs[cmdIndex][1]:lower()) then
                            table.insert(filtered_spells_or_abilities, spell)
                        end
                    end
                elseif action_type == "Abilities" or action_type == "Alt Abilities" then
                    for _, ability in ipairs(combined_abilities) do
                        if button.right_click_search_inputs[cmdIndex][1] == "" or string.find(ability:lower(), button.right_click_search_inputs[cmdIndex][1]:lower()) then
                            table.insert(filtered_spells_or_abilities, ability)
                        end
                    end
                elseif action_type == "Weapon Skills" or action_type == "Alt Weapon Skills" then
                    for _, weaponskill in ipairs(combined_weaponskills) do
                        if button.right_click_search_inputs[cmdIndex][1] == "" or string.find(weaponskill:lower(), button.right_click_search_inputs[cmdIndex][1]:lower()) then
                            table.insert(filtered_spells_or_abilities, weaponskill)
                        end
                    end
                elseif action_type == "Equipset" then
                    for _, equipset in ipairs(equipsets) do
                        table.insert(filtered_spells_or_abilities, equipset)
                    end
                end
                

                -- Determine the spell or ability name based on the selected index
                local spell_or_ability_name = filtered_spells_or_abilities[button.right_click_spell_states[cmdIndex]]

                -- Ensure the right_click_equipset_states is initialized before accessing
                if not button.right_click_equipset_states[cmdIndex] then
                    button.right_click_equipset_states[cmdIndex] = {0}  -- or any default value you expect
                end


                 -- Dropdown to select Action Type
                imgui.SetNextItemWidth(150)
                if imgui.BeginCombo("##RightClickActionType"..cmdIndex, action_types[button.right_click_action_type_states[cmdIndex]] or "") then
                    for i = 1, #action_types do
                        local is_selected = (i == button.right_click_action_type_states[cmdIndex])
                        if imgui.Selectable(action_types[i], is_selected) then
                            button.right_click_action_type_states[cmdIndex] = i
                            if action_types[i] == "Equipset" then
                                cmdInfo.command = string.format('/equipset %d', button.right_click_equipset_states[cmdIndex][1])
                            elseif action_type[i] == "Attack" or action_type[i] == "Alt Attack" or action_type[i] == "Ranged" then
                                button.commands[cmdIndex].command = string.format('%s %s', action_type_map[action_type[i]], target_map[targets[button.target_states[cmdIndex]]] or "")
                            else
                                cmdInfo.command = action_type_map[action_types[i]] .. " " .. (cmdInfo.spell or "") .. " " .. (cmdInfo.target or "")
                            end
                        end
                        if is_selected then
                            imgui.SetItemDefaultFocus()
                        end
                    end
                    imgui.EndCombo()
                end

                -- Equipset Dropdown
                if action_type == "Equipset" then
                    imgui.SetNextItemWidth(150)
                    imgui.SameLine()
                    if imgui.BeginCombo("##RightClickEquipsetNumber"..cmdIndex, tostring(button.right_click_equipset_states[cmdIndex][1] or 0)) then
                        for i = 1, #equipsets do
                            local is_selected = (tostring(button.right_click_equipset_states[cmdIndex][1]) == equipsets[i])
                            if imgui.Selectable(equipsets[i], is_selected) then
                                button.right_click_equipset_states[cmdIndex] = {tonumber(equipsets[i])}
                                cmdInfo.command = string.format('/equipset %d', button.right_click_equipset_states[cmdIndex][1])
                            end
                            if is_selected then
                                imgui.SetItemDefaultFocus()
                            end
                        end
                        imgui.EndCombo()
                    end
                elseif action_type == "Attack" or action_type == "Alt Attack" or action_type == "Ranged" then
                        -- Do not show spell/ability dropdown for Attack
                else
                    -- Spell/Ability Dropdown
                    imgui.SetNextItemWidth(150)
                    imgui.SameLine()
                    if imgui.BeginCombo("##RightClickSpell"..cmdIndex, spell_or_ability_name or "") then
                        for i = 1, #filtered_spells_or_abilities do
                            local is_selected = (i == button.right_click_spell_states[cmdIndex])
                            if imgui.Selectable(filtered_spells_or_abilities[i], is_selected) then
                                button.right_click_spell_states[cmdIndex] = i
                                cmdInfo.spell = filtered_spells_or_abilities[i]
                                cmdInfo.command = action_type_map[action_types[button.right_click_action_type_states[cmdIndex]]] .. " \"" .. cmdInfo.spell .. "\" " .. target_map[targets[button.right_click_target_states[cmdIndex]]]
                            end
                            if is_selected then
                                imgui.SetItemDefaultFocus()
                            end
                        end
                        imgui.EndCombo()
                    end
                end

                -- Target Dropdown
                imgui.SetNextItemWidth(150)
                imgui.SameLine()
                if imgui.BeginCombo("##RightClickTarget"..cmdIndex, targets[button.right_click_target_states[cmdIndex]] or "") then
                    for i = 1, #targets do
                        local is_selected = (i == button.right_click_target_states[cmdIndex])
                        if imgui.Selectable(targets[i], is_selected) then
                            button.right_click_target_states[cmdIndex] = i
                            cmdInfo.target = target_map[targets[i]]
                            cmdInfo.command = action_type_map[action_types[button.right_click_action_type_states[cmdIndex]]] .. " " .. (cmdInfo.spell or 1) .. " " .. cmdInfo.target
                        end
                        if is_selected then
                            imgui.SetItemDefaultFocus()
                        end
                    end
                    imgui.EndCombo()
                end

                -- Display delay input next to the command
                imgui.SetNextItemWidth(50)
                imgui.SameLine()
                if imgui.InputText('##RightClickEditButtonDelay' .. cmdIndex, button.right_click_delays[cmdIndex], 5) then
                    button.right_click_commands[cmdIndex].delay = tonumber(button.right_click_delays[cmdIndex][1]) or 0
                end
            end

            imgui.NewLine()
            if imgui.Button('+Add ', { 110, 40 }) then
                imgui.NewLine()
                table.insert(button.right_click_commands, { command = "", delay = 0 })
                table.insert(button.right_click_action_type_states, selected_action_type)
                table.insert(button.right_click_spell_states, selected_spell)
                table.insert(button.right_click_target_states, selected_target)
                table.insert(button.right_click_search_inputs, { "" })
                table.insert(button.right_click_delays, { "0" })
            end
            imgui.SameLine()
            if imgui.Button('-Remove ', { 110, 40 }) then
                if #button.right_click_commands > 0 then
                    table.remove(button.right_click_commands, #button.right_click_commands)
                    table.remove(button.right_click_action_type_states, #button.right_click_action_type_states)
                    table.remove(button.right_click_spell_states, #button.right_click_spell_states)
                    table.remove(button.right_click_target_states, #button.right_click_target_states)
                    table.remove(button.right_click_search_inputs, #button.right_click_search_inputs)
                    table.remove(button.right_click_delays, #button.right_click_delays)
                end
            end
            imgui.SameLine()
            if imgui.Button('Execute ', { 110, 40 }) then
                -- Reset and update button commands
                for cmdIndex, cmdInfo in ipairs(button.right_click_commands) do
                    update_command(button,true)
                end
                -- Execute the updated commands
                execute_commands(button.right_click_commands)
            end

            imgui.Separator()
            imgui.NewLine()

            -- Middle Click Commands Section
            imgui.Separator()
            imgui.Text('Middle Click Commands: (!ADVANCED!)')
            for cmdIndex, cmdInfo in ipairs(button.middle_click_commands) do
                local cmdBuffer = { cmdInfo.command }  -- Wrapping the string in a table
                local delayBuffer = { tostring(cmdInfo.delay) }  -- Wrapping the string in a table
                if imgui.InputText('##EditMiddleClickCommand' .. cmdIndex, cmdBuffer, seacom.command_buffer_size) then
                    button.middle_click_commands[cmdIndex].command = cmdBuffer[1]
                end
                imgui.SameLine()
                imgui.SetNextItemWidth(50)
                if imgui.InputText('##EditMiddleClickDelay' .. cmdIndex, delayBuffer, 5) then
                    button.middle_click_commands[cmdIndex].delay = tonumber(delayBuffer[1]) or 0
                end
            end

            imgui.NewLine()
            if imgui.Button('+Add   ', { 110, 40 }) then
                imgui.NewLine()
                table.insert(button.middle_click_commands, { command = "", delay = 0 })
                table.insert(button.middle_click_search_inputs, { "" })
                table.insert(button.middle_click_delays, { "0" })
            end
            imgui.SameLine()
            if imgui.Button('-Remove   ', { 110, 40 }) then
                if #button.middle_click_commands > 1 then
                    table.remove(button.middle_click_commands, #button.middle_click_commands)
                    table.remove(button.middle_click_search_inputs, #button.middle_click_search_inputs)
                    table.remove(button.middle_click_delays, #button.middle_click_delays)
                end
            end
            imgui.SameLine()
            if imgui.Button('Execute   ', { 110, 40 }) then
                execute_commands(button.middle_click_commands)
            end

            imgui.Separator()
            imgui.NewLine()

            -- Movement Buttons
            if imgui.Button('<', { 50, 50 }) then
                if button.pos.x > 0 then
                    local newButtonPos = { x = button.pos.x - 1, y = button.pos.y }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        button.pos = newButtonPos
                        save_job_settings(clicky.settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('>', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x + 1, y = button.pos.y }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    button.pos = newButtonPos
                    save_job_settings(clicky.settings, last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('^', { 50, 50 }) then
                if button.pos.y > 0 then
                    local newButtonPos = { x = button.pos.x, y = button.pos.y - 1 }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        button.pos = newButtonPos
                        save_job_settings(clicky.settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('v', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x, y = button.pos.y + 1 }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    button.pos = newButtonPos
                    save_job_settings(clicky.settings, last_job_id)
                end
            end

            -- New Button Creation
            if imgui.Button('+<', { 50, 50 }) then
                if button.pos.x > 0 then
                    local newButtonPos = { x = button.pos.x - 1, y = button.pos.y }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                        save_job_settings(clicky.settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('+>', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x + 1, y = button.pos.y }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    save_job_settings(clicky.settings, last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('+^', { 50, 50 }) then
                if button.pos.y > 0 then
                    local newButtonPos = { x = button.pos.x, y = button.pos.y - 1 }
                    if not button_exists_at_position(window.buttons, newButtonPos) then
                        table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                        save_job_settings(clicky.settings, last_job_id)
                    end
                end
            end

            imgui.SameLine()
            if imgui.Button('+v', { 50, 50 }) then
                local newButtonPos = { x = button.pos.x, y = button.pos.y + 1 }
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    save_job_settings(clicky.settings, last_job_id)
                end
            end

            imgui.End()
        end

        PopStyles(darkBluePfStyles)
    end
end



-- Add a new window
local function add_new_window()
    local new_id = #clicky.settings.windows + 1
    -- Create a new window with proper button initialization
    table.insert(clicky.settings.windows, {
        id = new_id,
        visible = true,
        opacity = 1.0,
        window_pos = { x = 350 + (new_id - 1) * 20, y = 700 + (new_id - 1) * 20 },
        buttons = {
            {
                name = 'New',
                commands = {},             -- Initialize as an empty table
                right_click_commands = {}, -- Initialize as an empty table
                middle_click_commands = {},-- Initialize as an empty table
                pos = { x = 0, y = 0 }
            }
        },
        requires_target = false,
        job = nil
    })
    save_job_settings(clicky.settings, last_job_id)
end

local prev_window_pos = { x = nil, y = nil }

-- Render the buttons window
local function render_buttons_window(window)
    if not window.visible then return end
    if not edit_mode and window.requires_target and not has_target() then return end
    local player_job = get_player_main_job()
    if window.job and window.job ~= player_job then return end

    local set_pos_cond = edit_mode and ImGuiCond_Once or ImGuiCond_Always
    imgui.SetNextWindowPos({ window.window_pos.x, window.window_pos.y }, set_pos_cond)

    local windowFlags = bit.bor(
        ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoNav,
        ImGuiWindowFlags_NoBringToFrontOnFocus, (edit_mode and 0 or ImGuiWindowFlags_NoMove)
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
                if not button_exists_at_position(window.buttons, newButtonPos) then
                    
                    table.insert(window.buttons, { name = 'New', commands = { { command = "", delay = 0 } }, pos = newButtonPos })
                    
                    save_job_settings(clicky.settings, last_job_id)
                end
            end

            imgui.SameLine()
            if imgui.Button('x', { 25, 25 }) then
                window.visible = false
                save_job_settings(clicky.settings, last_job_id)
            end

            imgui.SameLine()
            settings_buffers.requires_target[1] = window.requires_target or false
            if imgui.Checkbox('Requires Target', settings_buffers.requires_target) then
                window.requires_target = settings_buffers.requires_target[1]
                save_job_settings(clicky.settings, last_job_id)
            end
        end

        for i, button in ipairs(window.buttons) do
            if button.pos == nil then button.pos = { x = 0, y = i } end
            if not button.commands then button.commands = {} end

            imgui.SetCursorPosX(button.pos.x * 80)
            imgui.SetCursorPosY((button.pos.y + 1) * 55)

            if imgui.Button(button.name, { 70, 50 }) then
                if edit_mode then
                    -- In edit mode, left-click to open command/wait menu
                    editing_button_index = i
                    seacom.name_buffer[1] = button.name
                    isEditWindowOpen = true
                    editing_window_id = window.id
                else
                    --Normal mode: execute left-click commands 
                    for cmdIndex, cmdInfo in ipairs(button.commands) do
                        update_command(button,false)
                    end

                    execute_commands(button.commands)
                end
            elseif imgui.IsItemClicked(1) and not edit_mode then
                -- Normal mode: execute right-click commands
                for cmdIndex, cmdInfo in ipairs(button.commands) do
                    update_command(button, cmdIndex,true)
                end

                execute_commands(button.right_click_commands)
            elseif imgui.IsItemClicked(2) and not edit_mode then
                -- Normal mode: execute middle-click commands
                execute_commands(button.middle_click_commands)
            end

            if imgui.IsItemHovered() and edit_mode then
                if imgui.IsMouseClicked(1) then
                    editing_button_index = i
                    seacom.name_buffer[1] = button.name
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
        else
            -- If exiting edit mode, close the command editor window
            if isEditWindowOpen then
                isEditWindowOpen = false
                editing_button_index = nil
                editing_window_id = nil
            end
        end

        imgui.End()
    end

    PopStyles(darkBluePfStyles)
end

local function update_window_positions()
    for _, window in ipairs(clicky.settings.windows) do
        imgui.SetNextWindowPos({ window.window_pos.x, window.window_pos.y }, ImGuiCond_Always)
    end
end

local last_main_job_id = nil  -- Track the last main job ID
local last_sub_job_id = nil   -- Track the last subjob ID
local job_zero_handled = false

local function job_change_cb()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    if not player then
        print('Error: Unable to get player memory manager')
        return
    end

    local main_job_id = player:GetMainJob()
    local sub_job_id = player:GetSubJob()

    -- If job ID is 0, do nothing and retain the current settings
    if main_job_id == 0 then
        if not job_zero_handled then
            print("Job ID is 0, retaining previous settings.")
            job_zero_handled = true  -- Set the flag to true after handling the first time
        end
        return
    end

    -- Reset the flag when a valid job ID is detected
    job_zero_handled = false

    -- Check if the main job has changed
    if main_job_id ~= last_job_id then
        if last_job_id then
            save_job_settings(clicky.settings, last_job_id)
        end
        -- Update spells and abilities
        clicky.settings = load_job_settings(main_job_id)
        last_job_id = main_job_id
        update_window_positions()
        update_spells_and_abilities()
    end
    -- Check if either the main job or subjob has changed
    if main_job_id ~= last_job_id or sub_job_id ~= last_sub_job_id then
        -- Update the last known subjob ID
        last_sub_job_id = sub_job_id
        last_job_id = main_job_id

        -- Update spells and abilities
        update_spells_and_abilities()
    end
end

local function onload()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    if not player then
        print('Error: Unable to get player memory manager')
        return
    end

    local main_job_id = player:GetMainJob()
    local sub_job_id = player:GetSubJob()

    -- If job ID is 0, do nothing and retain the current settings
    if main_job_id == 0 then
        if not job_zero_handled then
            print("Job ID is 0 during load, retaining default or previous settings.")
            job_zero_handled = true  -- Set the flag to true after handling the first time
        end
        return
    end

    -- Reset the flag when a valid job ID is detected
    job_zero_handled = false

    -- Load the settings for the current main job
    clicky.settings = load_job_settings(main_job_id)
    
    -- Update the last known job IDs
    last_main_job_id = main_job_id
    last_sub_job_id = sub_job_id
    last_job_id = main_job_id

    -- Update spells and abilities
    update_spells_and_abilities()
end

-- Initialize last time for delta time calculation
local last_time = os.clock()

-- Initialize the addon by loading current job settings and updating spells and abilities
onload()

ashita.events.register('d3d_present', 'present_cb', function()
    job_change_cb()
    
    -- Calculate delta time
    local current_time = os.clock()
    local dt = current_time - last_time
    last_time = current_time

    timer.Check(dt)
    if isRendering then
        for _, window in ipairs(clicky.settings.windows) do
            render_buttons_window(window)
        end
        render_info_window()
        render_edit_window()
    end
end)

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args()
    if #args == 0 or not args[1]:any('/clicky') then
        return
    end

    e.blocked = true

    -- Check if additional arguments are provided
    if #args == 1 then
        show_info_window = not show_info_window
        return
    end

    if #args >= 2 and args[2]:any('show') then
        UpdateVisibility(tonumber(args[3]) or 1, true)
        isRendering = true
        return
    end

    if #args >= 2 and args[2]:any('hide') then
        UpdateVisibility(tonumber(args[3]) or 1, false)
        isRendering = false
        return
    end

    if #args >= 2 and args[2]:any('addnew') then
        add_new_window()
        return
    end

    if #args >= 2 and args[2]:any('edit') and args[3]:any('on') then
        edit_mode = true
        for _, window in ipairs(clicky.settings.windows) do
            window.opacity = 1.0
        end
        save_job_settings(clicky.settings, last_job_id)
        return
    end

    if #args >= 2 and args[2]:any('edit') and args[3]:any('off') then
        edit_mode = false
        for _, window in ipairs(clicky.settings.windows) do
            window.opacity = 0.0
        end
        save_job_settings(clicky.settings, last_job_id)
        return
    end

    if #args >= 2 and args[2]:any('save') then
        save_job_settings(clicky.settings, last_job_id)
        print('Settings saved manually.')
        return
    end

    print(chat.header(addon.name):append(chat.error('Usage: /clicky [show|hide|addnew|edit] [on|off] [window_id]')))
end)

ashita.events.register('unload', 'unload_cb', function ()
    if last_job_id then
        save_job_settings(clicky.settings, last_job_id)
    end
end)

for _, window in ipairs(clicky.settings.windows) do
    UpdateVisibility(window.id, window.visible)
end
isRendering = true


