-- timer.lua
local Timer = {}

function Timer.new()
    local self = {}
    self.timers = {}

    self.update = function(deltaTime)
        for i = #self.timers, 1, -1 do
            local timer = self.timers[i]
            timer.timeLeft = timer.timeLeft - deltaTime
            if timer.timeLeft <= 0 then
                timer.callback()
                table.remove(self.timers, i)
            end
        end
    end

    self.addTimer = function(duration, callback)
        table.insert(self.timers, {timeLeft = duration, callback = callback})
    end

    return self
end

return Timer
