local mtmq = {}

-- class Thing
local Thing = {}
local router =

function Thing:new(thingId, options)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  options = options or {}

  local keepalive = options.keepalive or 10
  local username = options.username or nil
  local password = options.password or nil
  local cleansession = options.cleansession or 1

  self.thingId = thingId
  self.client = mqtt.Client(thingId, keepalive, username, password, cleansession)

  return o
end

function Thing:connect(host, options)
  options = options or {}

  local port = options.port or 1883
  local secure = options.secure or 0
  local autoreconnect = options.autoreconnect or 0
  local onConnect = options.onConnect or function() end
  local onError = options.onError or function() end

  self.client:on("connect", function(client)
      self.client:subscribe(self.thingId.."/$suback/#")
      self.client:subscribe(self.thingId.."/$callack/#")
    end)

  return self.client:connect(host, port, secure, autoreconnect, onConnect, onError)
end

function Thing:subscribe(name, ...)
  local length = table.getn(arg)
  local callback = function() end

  if(type(arg[length]) == "function") then
    callback = arg[length]
    table.remove(arg, length)
  end

  self.client:subscribe(self.thingId.."/"..name.."/#")
end
-- class Thing end

function mtmq.Thing(thingId, options)
  return Thing:new(thingId, options)
end

return mtmq
