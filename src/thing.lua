local Router = require "router"
local Subscription = require "subscription"

local Thing = {}

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
  self.router = Router:new()

  collectgarbage()

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
      self.client:subscribe(self.thingId.."/$suback/#", 0)
      self.client:subscribe(self.thingId.."/$callack/#", 0)
    end)

  self.client:on("message", function(client, topic, data)
      self.router:emit(topic, data)
    end)

  collectgarbage()

  return self.client:connect(host, port, secure, autoreconnect, onConnect, onError)
end

-- subscribe(name: string, ...args: any[], callback?: (error) => void)
function Thing:subscribe(name, ...)
  local length = table.getn(arg)
  local callback = function() end

  if(type(arg[length]) == "function") then
    callback = arg[length]
    table.remove(arg, length)
  end

  self.client:subscribe(self.thingId.."/"..name.."/#", 0, function()
      ok, json = pcall(cjson.encode, arg)
      if ok then
        self.client:publish(self.thingId.."/$sub/"..name, json, 0, 0)
        self.router:once(self.thingId.."/$suback/"..name, function(data, params)
            local code = tonumber(data)
            if code ~= 0 then callback(code)
            else callback() end
          end)
      else
        callback(-1) -- JSON encoding error code (-1)
      end
    end)

  collectgarbage()

	return Subscription:new(self, name)
end

function Thing:onTopic(pattern, listener)
	self.router:on(self.thingId.."/"..pattern, listener)
end

return Thing
