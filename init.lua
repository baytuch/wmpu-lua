-- WMPU
-- Core

wifi_ssid = "TP-LINK"
wifi_pass = "pass"
mqtt_id = "wmpu-001"
mqtt_host = "mqtt.host.ua"
mqtt_port = 1883
DS18B20_PIN = 4

-- Modules
require "DS18B20"
require "Link"

-- WIFI init
local function wifi_init()
  wifi.setmode(wifi.STATION)
  wifi.sta.config(wifi_ssid, wifi_pass)
  wifi.sta.connect()
  wifi.sta.autoconnect(0)
end

-- Processor
local init_t = false
local wifi_status = false
local wd_t = 0
tmr.alarm(0, 5000, 1, function()
  print("Free memory: " .. node.heap() .. " bytes")
  -- WIFI controller
  if wifi.sta.status() == 5 then
    if wifi_status == false then
      print("WIFI: connected")
      print(wifi.sta.getip())
    end
    wifi_status = true
  elseif wifi.sta.status() == 2 or wifi.sta.status() == 3 or wifi.sta.status() == 4 then
    wifi_status = false
    print("WIFI: error!")
  else
    wifi_init()
    wifi_status = false
    print("Connecting to WIFI")
  end
  -- Core logic
  if init_t == true then
    -- Send data
    if DS18B20_status == true and wifi_status == true and Link_status == true then
      for i = 0, #DS18B20_data do
        Link_publish("wmpu/001/" .. i, DS18B20_data[i])
      end
    end
    -- Link init
    if wifi_status == true and Link_status == false then
      Link_init(mqtt_host, mqtt_port, mqtt_id, "", "")
    end
  end
  -- WD controller
  if init_t == true then
    if wifi_status == true and DS18B20_status == true and Link_status == true then
      tmr.wdclr()
      wd_t = 0
    else
      wd_t = wd_t + 1
      if wd_t > 20 then
        print("SYS: something wrong. Stop and reboot!")
        init_t = false
        tmr.stop(0)
        node.restart()
      end
      print("SYS: something wrong!")
    end
  end
  -- Memory monitor
  if node.heap() < 10500 then
    print("SYS: not enough memory. Stop and reboot!")
    init_t = false
    tmr.stop(0)
    node.restart()
  end
  -- Non runtime procedures
  if DS18B20_busy == false then
    DS18B20_init(DS18B20_PIN)
  end
  init_t = true
end)
