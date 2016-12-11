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

function Binding:set(value, callback)
  local ok, payload = pcall(cjson.encode, self.func(value))
  self.thing:publish("$bind/"..self.name, payload)

  self.thing:onceTopic("$bindack/"..self.name, function(data, params)
      local code = tonumber(data)
      if code ~= 0 then callback(code)
      else callback(nil) end
    end)
end

return Binding
