local sUtils = require("libraries.sUtils")
local button = require("libraries.button")
local sha256 = require("libraries.sha256")
local bigfont = require("libraries.bigfont")

local image = sUtils.asset.load("keypad-image.skimg")
local password = sUtils.fread(".keypad-password.txt") -- This b hashed. Set it up with `keypad setup`

local tArgs = {...}

local numbers = {["0"]=true,["1"]=true,["2"]=true,["3"]=true,["4"]=true,["5"]=true,["6"]=true,["7"]=true,["8"]=true,["9"]=true}
local function isDigits(str)
  for x in str:gmatch(".") do
    if not numbers[x] then
      return false
    end
  end
  return true
end

if tArgs[1] == "setup" then
  term.setTextColour(colours.black)
  term.setBackgroundColour(colours.white)
  term.clear()
  term.setCursorPos(1,1)
  term.write("Enter the new passcode (Only numeric digits!)")
  term.setCursorPos(1,2)
  local newPassword = read()
  if not isDigits(newPassword) then
    printError("Please enter only digits!")
    error("Restart setup to try again!",0)
  end
  -- Now hash and write the password to file 
  local hash = sha256.pbkdf2(newPassword,"monitor-keypad-salt",25):toHex()
  local f = fs.open(".keypad-password.txt","w")
  f.write(hash)
  f.close()
  return
end

local displayOn = {
  ["monitor_442"] = true,
  ["monitor_441"] = true
}

local function open()
  rs.setOutput("back",true)
  sleep(0.5)
  rs.setOutput("back",false)
end

local function close()
  rs.setOutput("top",true)
  sleep(0.5)
  rs.setOutput("top",false)
end

for k in pairs(displayOn) do
  displayOn[k] = peripheral.wrap(k)
end

local function blit(t,f,g)
  for _,v in pairs(displayOn) do
    v.blit(t,f,g)
  end
end

local function setCursorPos(x,y)
  for _,v in pairs(displayOn) do
    v.blit(x,y)
  end
end

local function write(txt)
  for _,v in pairs(displayOn) do
    v.write(txt)
  end
end

local function setTextColour(col)
  for _,v in pairs(displayOn) do
    v.setTextColour(col)
  end
end

local function setBackgroundColour(col)
  for _,v in pairs(displayOn) do
    v.setBackgroundColour(col)
  end
end

local function clear()
  for _,v in pairs(displayOn) do
    v.clear()
  end
end

local function writeOn(size,str,x,y)
  for _,v in pairs(displayOn) do
    bigfont.writeOn(v,size,str,x,y)
  end
end

local function drawSkimg(img,x,y)
  for _,v in pairs(displayOn) do
    sUtils.asset.drawSkimg(img,x,y,v)
  end
end

drawSkimg(image)

local passCode = {}

-- create buttons
button.newButton(2,3,1,1,function() table.insert(passCode,1) end)
button.newButton(3,3,1,1,function() table.insert(passCode,2) end)
button.newButton(4,3,1,1,function() table.insert(passCode,3) end)
button.newButton(2,4,1,1,function() table.insert(passCode,4) end)
button.newButton(3,4,1,1,function() table.insert(passCode,5) end)
button.newButton(4,4,1,1,function() table.insert(passCode,6) end)
button.newButton(2,5,1,1,function() table.insert(passCode,7) end)
button.newButton(3,5,1,1,function() table.insert(passCode,8) end)
button.newButton(4,5,1,1,function() table.insert(passCode,9) end)
button.newButton(5,5,1,1,function() table.insert(passCode,0) end)


local function cancel()
  passCode = {}
  setCursorPos(1,1)
  blit("     ","00000","80008")
end

local function accept()
  if #passCode == 5 then
    local code = table.concat(passCode)
    local hash = sha256.pbkdf2(code,"monitor-keypad-salt",25):toHex()
    if hash == password then
      clear()
      setTextColour(colours.green)
      setBackgroundColour(colours.white)
      open()
      for i=5,0,-1 do
        clear()
        writeOn(1,tostring(i))
        sleep(1)
      end
      setTextColour(colours.orange)
      for i=9,0,-1 do
        clear()
        writeOn(1,tostring(i))
        sleep(1)
      end
      clear()
      setTextColour(colours.red)
      close()
      for i=5,0,-1 do
        clear()
        writeOn(1,tostring(i))
        sleep(1)
      end
      clear()
      drawSkimg(image)
    else

    end
    passCode = {}
  end
end

local buttonAccept = button.newButton(5,4,1,1,accept)
local buttonCancel = button.newButton(5,3,1,1,cancel)

while true do
  local e = {os.pullEvent()}
  if e[1] == "monitor_touch" then
    e[1] = "mouse_click"
  end
  button.executeButtons(e)
  local currentCode = table.concat(passCode)
  if #passCode <= 5 then
    setCursorPos(2,1)
    setTextColour(colours.black)
    setBackgroundColour(colours.grey)
    write(currentCode)
  else
    cancel()
  end
end