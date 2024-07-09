-- timer.lua
timer = {
    namedTimers = {},
    simpleTimers = {},
}

function timer.Adjust(identifier, delay, repetitions, func)
    if timer.namedTimers[identifier] then
        timer.namedTimers[identifier].delay = delay
        timer.namedTimers[identifier].repetitions = repetitions
        timer.namedTimers[identifier].func = func
        return true
    else
        return false
    end
end

function timer.Check(dt)
    for k, v in pairs(timer.namedTimers) do
        if v.active then
            v.delayTimer = v.delayTimer + dt
            if v.delayTimer >= v.delay then
                v.func()
                v.repetitionsDone = v.repetitionsDone + 1
                if v.repetitions ~= 0 and v.repetitionsDone >= v.repetitions then
                    timer.namedTimers[k] = nil
                else
                    v.delayTimer = v.delayTimer - v.delay
                end
            end
        end
    end
    for k, v in pairs(timer.simpleTimers) do
        v.delayTimer = v.delayTimer + dt
        if v.delayTimer >= v.delay then
            v.func()
            timer.simpleTimers[k] = nil
        end
    end
end

function timer.Create(identifier, delay, repetitions, func)
    if delay <= 0 then return false end
    timer.namedTimers[identifier] = {
        active = false,
        delay = delay,
        delayTimer = delay,
        repetitions = repetitions or 0,
        repetitionsDone = 0,
        func = func
    }
end

function timer.Destroy(identifier)
    timer.namedTimers[identifier] = nil
end

function timer.Exists(identifier)
    return timer.namedTimers[identifier] ~= nil
end

function timer.Pause(identifier)
    if timer.namedTimers[identifier] and timer.namedTimers[identifier].active then
        timer.namedTimers[identifier].active = false
        return true
    else
        return false
    end
end

function timer.Remove(identifier)
    timer.namedTimers[identifier] = nil
end

function timer.RepsLeft(identifier)
    if timer.namedTimers[identifier] then
        return timer.namedTimers[identifier].repetitionsLeft
    end
end

function timer.Simple(delay, func)
    table.insert(timer.simpleTimers, { delay = delay, delayTimer = 0, func = func })
end

function timer.Start(identifier)
    if timer.namedTimers[identifier] then
        timer.namedTimers[identifier].active = true
        timer.namedTimers[identifier].delayTimer = 0
        timer.namedTimers[identifier].repetitionsDone = 0
        return true
    else
        return false
    end
end

function timer.Stop(identifier)
    if timer.namedTimers[identifier] and timer.namedTimers[identifier].active then
        timer.namedTimers[identifier].active = false
        timer.namedTimers[identifier].delayTimer = 0
        timer.namedTimers[identifier].repetitionsDone = 0
        return true
    else
        return false
    end
end

function timer.TimeLeft(identifier)
    if timer.namedTimers[identifier] then
        return timer.namedTimers[identifier].delay - timer.namedTimers[identifier].delayTimer
    else
        return 0
    end
end

function timer.Toggle(identifier)
    if timer.namedTimers[identifier] then
        if timer.namedTimers[identifier].active then
            timer.Pause(identifier)
        else
            timer.UnPause(identifier)
        end
        return timer.namedTimers[identifier].active
    end
end

function timer.UnPause(identifier)
    if timer.namedTimers[identifier] and not timer.namedTimers[identifier].active then
        timer.namedTimers[identifier].active = true
        return true
    else
        return false
    end
end

return timer
