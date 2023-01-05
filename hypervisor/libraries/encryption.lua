--- Encryption libraries, provides a single `crypt` function that takes a key file, and automatically handles nonces and stuff behind the scenes.

local cha = require("libraries.chacha20")

local f = fs.open("/.key","r")
local key = {(f.readAll()):byte(1,-1)}
f.close()

local function crypt(message,nonce)
  if type(message) == "table" then message = textutils.serialize(message) end
  nonce = nonce or cha.genNonce(12)
  local out = cha.crypt(message,key,nonce)
  return out,nonce
end

return setmetatable({
  crypt = crypt
},{
  __call = function(self,...) return crypt(...) end
})