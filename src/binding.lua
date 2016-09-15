local Binding = {}

function Binding:new(name, thing)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  self.name = name
  self.thing = thing

  return o
end

function Binding:set(value)
  local ok, payload = pcall(cjson.encode, value)
  self.thing:publish("$bind/"..self.name, payload)
end

return Binding
