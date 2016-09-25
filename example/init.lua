metemq = require "metemq"

WIFI_NAME = "WIFI_SSID"
PASSWORD = "WIFI_PASSWORD"
BROKER_HOST = "example.com"
BROKER_PORT = "1883"
THING_ID = "MY_NODEMCU"

function connectThing()
  -- Create Thing
  thing = metemq.Thing(THING_ID)

  -- If you want to see MQTT messages, remove comment below
  -- thing:setupLogger()

  thing:actions({
    print = function(c, str)
        print("action print: ")
        print(str)
        c:done("yes i did it")
    end
  })

  -- Connect to MeteMQ broker
  thing:connect(BROKER_HOST, {
      port = BROKER_PORT,
      onConnect = function()
        sub = thing:subscribe("demo")

        sub:on({
            added = function(name, age)
              print("added", name, age)
            end,
            changed = function(name, age)
              print(name, "->", age)
            end,
            removed = function(id)
              print("removed id")
            end
          })

        thing:call("hello", function(err, result)
            if(err) then return print("there was error") end
            print("hello:", result)
          end)

        local temp = thing:bind("temp")
        temp:set(math.random(1000000))
      end
    })
end

wifi.setmode(wifi.STATION)
wifi.sta.config(WIFI_NAME, PASSWORD)
wifi.sta.connect()
tmr.alarm(1, 1000, 1, function()
    if wifi.sta.getip() == nil then
      print("Connecting...")
    else
      tmr.stop(1)
      print("Connected, IP is "..wifi.sta.getip())
      connectThing()
    end
  end)
