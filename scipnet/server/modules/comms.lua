-- Will queue events for network messages
local enc = require("libraries.encryption")
local keyf = fs.open("/.key","r")
local key = {keyf.readAll():byte(1,-1)}
keyf.close()

-- Event template
-- "network_message","subtype","client",...

local modem = peripheral.find("modem",function(k,v) return v.isWireless() end)
modem.open(61312)

while true do
  local e = {os.pullEvent("modem_message")}
  local msg = textutils.unserialize(e[5])
  if msg.target == "server" then
    local ok,data = enc.decrypt(msg.data,key)
    if ok then
    ---@diagnostic disable-next-line: undefined-field
      os.queueEvent("network_message",data.type,data.sender,data.data)
    end
  end
end