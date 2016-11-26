local Thing = require "thing"

local mtmq = {}

function mtmq.Thing(thingId, options)
  return Thing(thingId, options)
end

return mtmq
