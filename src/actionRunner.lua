local ActionRunner = {}
local ActionControl = {}

function ActionControl:new(msgId, thing)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  self.msgId = msgId
  self.thing = thing

  return o
end

function ActionControl:done(...)
	self.thing:call("_metemq_applied", self.msgId, unpack(arg))
end

function ActionRunner:new(msgId, name, thing)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  self.msgId = msgId
  self.name = name
  self.thing = thing

  return o
end

function ActionRunner:run(params)
  local action = self.thing._actions[self.name]
  action(ActionControl:new(self.msgId, self.thing), unpack(params))
end

return ActionRunner
