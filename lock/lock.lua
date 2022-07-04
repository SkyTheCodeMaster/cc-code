-- Simple lock, uses a hashed password (in `/passwd` file). If file is not found it will prompt for creation.

local SIDE = "right" -- Side that door or mechanism is on.
local DELAY = 5 -- Length of time redstone is output for.

-- If sha256 is not available then download it.
if not fs.exists("sha256.lua") then
  local h = assert(http.get("https://pastebin.com/raw/6UV4qfNF"))
  local f = assert(fs.open("sha256.lua","w"))
  f.write(h.readAll())
  f.close()
  h.close()
end
-- If bigfont is not available then download it.
if not fs.exists("bigfont.lua") then
  local h = assert(http.get("https://pastebin.com/raw/3LfWxRWh"))
  local f = assert(fs.open("bigfont.lua","w"))
  f.write(h.readAll())
  f.close()
  h.close()
end

local sha256 = require("sha256")
local bf = require("bigfont")

-- If passwd is not available create it.
term.setTextColour(colours.white)
term.setBackgroundColour(colours.blue)
term.clear()
if not fs.exists("passwd") then
  term.setTextColour(colours.white)
  term.setBackgroundColour(colours.blue)
  term.clear()
  term.setCursorPos(1,1)
  term.write("Please enter a new password:")
  term.setCursorPos(1,2)
  local newPassword = read("*")
  local hashword = sha256.pbkdf2(newPassword,"skylock",5)
  local f = assert(fs.open("passwd","w"))
  f.write(hashword:toHex())
  f.close()
end

local f = assert(fs.open("passwd","r"))
local hash = f.readAll()
f.close()

local function centerWrite(txt,y,t)
  t = t or term
  local width = t.getSize()

  t.setCursorPos(math.ceil((width / 2) - (txt:len() / 2)), y)
  t.write(txt)
end

local function draw(bg)
  term.setTextColour(colours.white)
  term.setBackgroundColour(bg or colours.blue)
  term.clear()

  centerWrite("Lock v1.0 - Skynet Systems",1)

  term.setCursorPos(1,2)
  term.write(("-"):rep(51))
end

while true do
  draw()

  term.setCursorPos(1,3)
  term.write("Enter password:")

  term.setCursorPos(1,4)
  local pw = read("*")
  local userHash = sha256.pbkdf2(pw,"skylock",5)
  if userHash:toHex() == hash then
    draw(colours.green)
    bf.writeOn(term,1,"Accepted")
    rs.setOutput(SIDE,true)
    sleep(DELAY)
    rs.setOutput(SIDE,false)
  else
    draw(colours.red)
    bf.writeOn(term,1,"Denied")
    sleep(DELAY)
  end
end