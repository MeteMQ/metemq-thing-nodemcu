local Subscription = {}

function Subscription:new(thing, name)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  self.thing = thing
  self.name = name

  return o
end

function Subscription:onAdded(handler)
  self.thing:onTopic(self.name.."/$added", function(data, params, topic)
      local args = cjson.decode(data)
      handler(unpack(args))
    end)

  return self
end

function Subscription:onChanged(handler)
  self.thing:onTopic(self.name.."/$changed", function(data, params, topic)
      local args = cjson.decode(data)
      handler(unpack(args))
    end)

  return self
end

function Subscription:onRemoved(handler)
  self.thing:onTopic(self.name.."/$removed", function(data, params, topic)
      local id = nil
      if data:len() > 0 then id = cjson.decode(data) end

      handler(id)
    end)

  return self
end

function Subscription:on(handlers)
  if handlers.added then self:onAdded(handlers.added) end
  if handlers.changed then self:onChanged(handlers.changed) end
  if handlers.removed then self:onRemoved(handlers.removed) end

  return self
end

return Subscription
