-- This simply reports the GPS position of the user to the main server

local modem = peripheral.find("modem")
local enc = require("libraries.encryption")
local sha=require("libraries.sha256")
local keyf = fs.open(".key","r")
local key = {keyf.readAll():byte(1,-1)}
keyf.close()
local ni = peripheral.wrap("back")

local uuid = sha.digest(ni.getMetaOwner().id)

while true do
  local x,y,z = gps.locate()
  local packet = {
    sender=uuid,
    type="gps",
    data = {
      x=x,
      y=y,
      z=z
    }
  }
  local tPacket = textutils.serialize(packet)
  local encData = enc.encrypt(tPacket,key)
  local realPacket = textutils.serialize(
    {
      target="server",
      data=encData
    }
  )
  modem.transmit(61312,61312,realPacket)
end