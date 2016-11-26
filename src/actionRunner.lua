local ActionRunner = {}
ActionRunner.__index = ActionRunner

setmetatable(ActionRunner, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local ActionControl = {}
ActionControl.__index = ActionControl

setmetatable(ActionControl, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function ActionControl.new(msgId, thing)
  local self = setmetatable({}, ActionControl)

  self.msgId = msgId
  self.thing = thing

  return self
end

function ActionControl:done(...)
	self.thing:call("_metemq_applied", self.msgId, unpack(arg))
end

function ActionRunner.new(msgId, name, thing)
  local self = setmetatable({}, ActionRunner)

  self.msgId = msgId
  self.name = name
  self.thing = thing

  return self
end

function ActionRunner:run(params)
  local action = self.thing._actions[self.name]
  action(ActionControl(self.msgId, self.thing), unpack(params))
end

return ActionRunner
