-- WMPU
-- module DS18B20

DS18B20_status = false
DS18B20_busy = false
DS18B20_data = {}
function DS18B20_init(pin)
  DS18B20_status = false
  DS18B20_busy = true
  -- Base setup
  ow.setup(pin)
  local ds18b20_adr = {}
  ow.reset_search(pin)
  repeat
    local addr = ow.search(pin)
    if (addr ~= nil) then
      -- print(addr:byte(1,8))
      local crc = ow.crc8(string.sub(addr,1,7))
      if crc == addr:byte(8) then
        --print("Address CRC OK")
        if (addr:byte(1) == 0x28) then
          -- print("DS18S20 family")
          table.insert(ds18b20_adr, addr)
        end
      end
    end
  until (addr ~= nil)
  -- print("Sensors "..#ds18b20_adr)
  if #ds18b20_adr > 0 then
    -- Init calculate (default resolution is 12-bit)
    for i = 1, #ds18b20_adr do
      local addr = ds18b20_adr[i];
      ow.reset(pin)
      -- ow.select(DS18B20_PIN, addr)
      ow.write(pin, 0x55, 1)
      for i=1,8 do
        ow.write(pin, addr:byte(i), 1)
      end
      ow.write(pin, 0x44, 1)
    end
    -- Get data
    DS18B20_data = {}
    tmr.alarm(1, 1000, 0, function()
      for i = 1, #ds18b20_adr do
        local addr = ds18b20_adr[i];
        present = ow.reset(pin)
        --ow.select(DS18B20_PIN, addr)
        ow.write(pin, 0x55, 1)
        for i=1,8 do
          ow.write(pin, addr:byte(i), 1)
        end
        ow.write(pin, 0xBE, 1)
        --print("P="..present)
        local data = nil
        data = string.char(ow.read(pin))
        for i = 1, 8 do
          data = data .. string.char(ow.read(pin))
        end
        --print("DATA:")
        --print(data:byte(1,9))
        local crc = ow.crc8(string.sub(data,1,8))
        --print("CRC="..crc)
        if crc == data:byte(9) then
          t = (data:byte(1) + data:byte(2) * 256)
          if t > 0x7FFF then
            t = t - 0x10000
          end
          t1 = (t * 625) / 10000
          table.insert(DS18B20_data, i - 1, t1)
          --print("Temp: "..t1.."°C")
          DS18B20_status = true
        end
      end
      DS18B20_busy = false
    end)
  else
    DS18B20_busy = false
    print("DS18B20: sensors not found!")
  end
end