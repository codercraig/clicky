local imgui = require('imgui')
local timer = require("timer")
local AshitaCore = require('AshitaCore')

local function execute_commands(commands)
    local index = 1

    local function execute_next_command()
        if index <= #commands then
            local command = commands[index]
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
        end
    end

    execute_next_command()
end

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

return {
    execute_commands = execute_commands,
    has_target = has_target,
    button_exists_at_position = button_exists_at_position,
    get_player_main_job = get_player_main_job
}
