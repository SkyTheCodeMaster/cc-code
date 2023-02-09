-- Will queue events for network messages
local enc = require("libraries.encryption")
local keyf = fs.open("/.key")
local key = fs.readAll()
keyf.close()

-- Event template
-- "network_message","subtype","client",...

local modem = peripheral.find("modem",function(k,v) return v.isWireless() end)
modem.open(61312)

while true do
  local e = {os.pullEvent("modem_message")}
  local msg = e[5]
  local data = enc.decrypt(msg,key)
  ---@diagnostic disable-next-line: undefined-field
  os.queueEvent("network_message",data.type,data.sender,data.data)
end