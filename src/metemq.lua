local Thing = require "thing"

local mtmq = {}

function mtmq.Thing(thingId, options)
  return Thing:new(thingId, options)
end

return mtmq
