local ActionRunner = {}
local ActionControl = {}

function ActionControl:new(thing)
  local o = {}
  self.__index = self
  setmetatable(o, self)

	self.thing = thing

  return o
end

function ActionControl:done(...)
	self.thing:call("_metemq_applied", arg)
end

function ActionRunner:new(msgId, name, thing)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  self.id = msgId
  self.name = name
  self.thing = thing

  return o
end

function ActionRunner:run(params)
  local action = self.thing.actions[self.name]
  action(ActionControl:new(), unpack(params))
end

return ActionRunner
