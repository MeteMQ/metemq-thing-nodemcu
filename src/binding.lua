local Binding = {}

function Binding:new(name, func, thing)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  self.name = name
  self.func = func or function(input) return input end
  self.thing = thing

  return o
end

function Binding:set(value)
  local ok, payload = pcall(cjson.encode, self.func(value))
  self.thing:publish("$bind/"..self.name, payload)
end

return Binding
