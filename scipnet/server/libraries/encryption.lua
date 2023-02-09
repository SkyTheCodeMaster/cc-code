local comms = {}
local sha = require("sha256")
local chacha = require("chacha20")

local sentBadNonces = {}
local recvBadNonces = {}

local function generateNonce()
  local bytes = {}
  for _=1,12 do
    table.insert(bytes,math.random(0,255))
  end
  local nonce = string.char(table.unpack(bytes))
  if sentBadNonces[nonce] then
    return generateNonce()
  else
    sentBadNonces[nonce] = true
    return nonce
  end
end

--- Split a message into it's 3 parts, the nonce, the data, and the HMAC
-- @tparam message string The encrypted message.
-- @treturn string The nonce of the message, should be validated against bad nonces.
-- @treturn string The encrypted data, should be unencrypted.
-- @treturn string The HMAC of the message.
local function split(message)
  local nonce = message:sub(0,12)
  local data = message:sub(13,-33)
  local hmac = message:sub(-32,-1)
  return nonce,data,hmac
end

--- Encrypts some data with a specified key
-- @tparam data string The data to be encrypted.
-- @tparam key string The key to encrypt the data with.
-- @treturn string Encrypted data with nonce and HMAC.
function comms.encrypt(data,key)
  local nonce = generateNonce()
  local tblNonce = {nonce:byte(1,-1)}
  local encData = chacha.crypt(data,key,tblNonce)
  local hmac = sha.hmac(encData,key)
  return nonce .. encData:toHex() .. hmac
end

--- Decrypts some data with a specified key
-- @tparam message string The data to be decrypted.
-- @tparam key string The key to decrypt the data with.
-- @treturn bool Whether or not the data was successfully decrypted.
-- @treturn string The decrypted data, or the reason why it couldn't be decrypted. (`"invalid nonce"`, `"invalid hmac"`)
function comms.decrypt(message,key)
  local nonce,encData,hmac = split(message)
  local msgHMAC = sha.hmac(encData,key)
  if hmac ~= msgHMAC then
    return false,"invalid hmac"
  elseif recvBadNonces[nonce] then
    return false,"invalid nonce"
  end
  recvBadNonces[nonce] = true
  local tblNonce = {nonce:byte(1,-1)}
  local data = chacha.crypt(encData,key,tblNonce)
  return true,data
end

return comms