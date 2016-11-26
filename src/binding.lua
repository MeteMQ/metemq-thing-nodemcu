local Binding = {}
Binding.__index = Binding

setmetatable(Binding, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Binding.new(name, func, thing)
  local self = setmetatable({}, Binding)

  self.name = name
  self.func = func or function(input) return input end
  self.thing = thing

  return self
end

function Binding:set(value)
  local ok, payload = pcall(cjson.encode, self.func(value))
  self.thing:publish("$bind/"..self.name, payload)
end

return Binding
