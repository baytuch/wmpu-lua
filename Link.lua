-- WMPU
-- module Link

m = nil
Link_status = false
function Link_init(host, port, id, user, password)
  m = mqtt.Client(id, 120, user, password)
  m:on("connect", function(client) print ("Link: connected") end)
  m:on("offline", function(client)
    Link_status = false
    print ("Link: offline")
  end)
  m:on("message", function(client, topic, data) 
    print(topic .. ":" ) 
    if data ~= nil then
      print(data)
    end
  end)
  m:connect(host, port, 0, 1, function(conn) 
    print("Link: connected")
    m:subscribe("/#", 0, function(conn)
      print("Link: subscribed!")
    end)
    Link_status = true
  end)
end

function Link_publish(path, body)
  local publish_t = false
  m:publish(path, body, 0, 0, function(conn)
    publish_t = true
  end)
  tmr.alarm(2, 2000, 0, function()
    if publish_t == false then
      Link_status = false
      print("Link: failure!")
    end
  end)
end

function Link_disconnect()
  m:close()
end