local mqttRegex = require "mqttRegex"

local Router = {}
Router.__index = Router

setmetatable(Router, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Router.new()
  local self = setmetatable({}, Router)

  self.listeners = {}

  return self
end

function Router:emit(topic, data)
  for pattern, listeners in pairs(self.listeners) do
    local params, isMatched = mqttRegex.parse(pattern, topic)
    if isMatched then
      for i, listener in ipairs(listeners) do listener(data, params, topic) end
    end
  end
end

-- listener: (data, params, topic) => void
function Router:on(pattern, listener)
  if self.listeners[pattern] == nil then
    self.listeners[pattern] = {}
  end

  table.insert(self.listeners[pattern], listener)
end

function Router:once(pattern, listener)
  local function onceListener(...)
    listener(unpack(arg))
    self:removeListener(pattern, onceListener)
  end

  self:on(pattern, onceListener)
end

function Router:removeListener(pattern, target)
  if self.listeners[pattern] then
    for i, listener in ipairs(self.listeners[pattern]) do
      if listener == target then
        table.remove(self.listeners[pattern],i)
        
        if #self.listeners[pattern] == 0 then
          self.listeners[pattern] = nil
          collectgarbage()
        end

        return true
      end
    end
  end

  return false
end

return Router
