local mqttRegex = {}

local function tokenize(topic)
  local tokens = {}
  for token in string.gmatch(topic, '([^/]+)') do
      table.insert(tokens, token)
  end
  return tokens
end

local function splitFirst(str)
  return str:sub(1, 1), str:sub(2, -1)
end

function mqttRegex.parse(pattern, topic)
  local patternTokens = tokenize(pattern)
  local topicTokens = tokenize(topic)

  local params = {}

  for i, pToken in ipairs(patternTokens) do
    local tToken = topicTokens[i]
    local first, paramName = splitFirst(pToken)

    if first == "+" then
      params[paramName] = tToken
    elseif first == "#" then
      local rest = {}
      for j = i, #topicTokens do table.insert(rest, topicTokens[j]) end
      params[paramName] = rest
      return params, true
    else
      if pToken ~= tToken then
        return nil, false
      end
    end
  end

  if #patternTokens ~= #topicTokens then
    return nil, false
  end

  return params, true
end

return mqttRegex
