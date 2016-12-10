local Router = require "router"
local Subscription = require "subscription"
local Binding = require "binding"
local ActionRunner = require "actionRunner"

local Thing = {}
Thing.__index = Thing

setmetatable(Thing, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Thing.new(thingId, options)
  local self = setmetatable({}, Thing)

  options = options or {}

  local keepalive = options.keepalive or 10
  local username = options.username or nil
  local password = options.password or nil
  local cleansession = options.cleansession or 1

  self.thingId = thingId
  self.client = mqtt.Client(thingId, keepalive, username, password, cleansession)
  self.router = Router()
  self._actions = {}
  self.inbox = nil

  collectgarbage()

  return self
end

function Thing:connect(host, options)
  options = options or {}

  local port = options.port or 1883
  local secure = options.secure or 0
  local autoreconnect = options.autoreconnect or 0
  local onConnect = options.onConnect or function() end
  local onError = options.onError or function() end

  local function onConnectWrapper()
    self:log("MQTT connected")

    self.client:subscribe({
        [self.thingId.."/$suback/#"] = 0,
        [self.thingId.."/$callack/#"] = 0
      }, function() self:listenActions(onConnect) end)
  end

  self.client:on("message", function(client, topic, data)
      self.router:emit(topic, data)
    end)

  collectgarbage()

  return self.client:connect(host, port, secure, autoreconnect, onConnectWrapper, onError)
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
      local ok, json = pcall(cjson.encode, arg)
      if ok then
        self:publish("$sub/"..name, json, 0, 0)
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

  return Subscription(self, name)
end

-- call(method: string [, ...args] [, callback: (err, result) => void])
function Thing:call(method, ...)
  local callback = function() end
  local msgId = tostring(math.random(100000000)) -- 8-digit integer

  if(type(arg[arg.n]) == "function") then
    callback = arg[arg.n]
    table.remove(arg, arg.n)
  end

  arg.n = nil

  local ok, payload = pcall(cjson.encode, arg)

  self:onceTopic("$callack/"..msgId.."/+code", function(data, params)
      local code = tonumber(params.code)
      if code ~= 0 then callback(code)
      else callback(nil, cjson.decode(data)) end
    end)

  self:publish("$call/"..method.."/"..msgId, payload)

  collectgarbage()
end

-- bind(name: string): Binding
function Thing:bind(name, func)
  return Binding(name, func, self)
end

-- actions(actions: {[name]: function})
function Thing:actions(actions)
  for name, action in pairs(actions) do
    self._actions[name] = action
  end
end

function Thing:listenActions(callback)
  self.inbox = self:subscribe("$inbox", callback)
  self.inbox:onAdded(function(msgId, name, params) self:runAction(msgId, name, params) end)
end

function Thing:runAction(msgId, name, params)
  if self._actions[name] == nil then
    print("ERROR: There is no such action called "..name)
  end

  ActionRunner(msgId, name, self):run(params)
end

-- Publish MQTT message on the name of thing
function Thing:publish(topic, payload, callback)
  self.client:publish(self.thingId.."/"..topic, payload, 0, 0, callback)
end

function Thing:onTopic(pattern, listener)
  self.router:on(self.thingId.."/"..pattern, listener)
end

function Thing:onceTopic(pattern, listener)
  self.router:once(self.thingId.."/"..pattern, listener)
end

function Thing:log(msg)
  if(self.logging) then print(msg) end
end

function Thing:setupLogger()
  self.logging = true
  self.router:on(self.thingId.."/#path", function(data, params, topic)
      print(topic.."->"..(data or ""))
    end)
end

return Thing
