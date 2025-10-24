-- If bigfont is not available then download it.
if not fs.exists("bigfont.lua") then
  local h = assert(http.get("https://pastebin.com/raw/3LfWxRWh"))
  local f = assert(fs.open("bigfont.lua","w"))
  f.write(h.readAll())
  f.close()
  h.close()
end

if not fs.exists("config.lua") then
  local f = fs.open("config.lua", "w")
  -- Default config
  f.write([[-- config.lua
local cfg = {}

cfg.alarm_relay = "redstone_relay_0"
cfg.alarm_side = "right"

cfg.door_relay = "redstone_relay_1"
cfg.door_side = "top"

cfg.door_open_time = 33
cfg.door_close_time = 33
cfg.launch_window = 30
cfg.safety_window = 15

cfg.launch_monitor = "monitor_0"
cfg.launch_monitor_background = colours.blue
cfg.launch_monitor_foreground = colours.white
cfg.launch_monitor_bigfont_size = 3

cfg.button_monitor = "top"
cfg.button_monitor_background = colours.blue
cfg.button_monitor_foreground = colours.white

return cfg]])
  f.close()
end

local config = require("config") -- Config is a Lua module that provides the necessary options
local bigfont = require("bigfont")

local alarm_relay = peripheral.wrap(config.alarm_relay)
local door_relay = peripheral.wrap(config.door_relay)
local launch_monitor = peripheral.wrap(config.launch_monitor)
local button_monitor = peripheral.wrap(config.button_monitor)

launch_monitor.setTextScale(0.5)
local launch_window = window.create(launch_monitor, 1, 1, launch_monitor.size())

local function countdown_to_str(time)
  -- Take a float, return a padded string.
  if time < 1 then
    -- Less than 1 second left, pad a 0 onto the end.
    return "0" .. tostring(time)
  end
  if time < 10 then
    -- Less than 10 seconds left, pad a 0 onto the end
    return "0" .. tostring(time)
  end
  return tostring(time)
end

local function display_countdown(time, text)
  -- Given the time should never be more than 99 seconds, force it into the
  -- format "00.0", and pad the first digits.

  local target_time = (os.epoch("utc")/1000) + time

  local function handle_display()
    while true do
      -- Draw the text and number on the display
      local remaining_time = (os.epoch("utc")/1000) / target_time
      local display_time = countdown_to_str(tonumber(string.format("%.1f", remaining_time)))
      local width, height = launch_monitor.size()
      local text_y = math.floor((height*0.33)+0.5)
      local number_y = math.floor((height*0.66)+0.5)
      launch_window.setVisible(false)
      launch_window.setBackgroundColour(config.launch_monitor_background)
      launch_window.setTextColour(config.launch_monitor_foreground)
      launch_window.clear()
      bigfont.writeOn(launch_window, config.launch_monitor_bigfont_size, text, nil, text_y)
      bigfont.writeOn(launch_window, config.launch_monitor_bigfont_size, display_time, nil, number_y)
      launch_window.setVisible(true)

      sleep(0.1)
    end
  end

  parallel.waitForAny(handle_display, function() sleep(time) end)
end

local function launch_rocket()
  --[[
  Launching a rocket:
  1) Open the silo door (Sound alarm)
  2) Wait the door time
  3) Start the rocket launch window
  4) Wait the rocket launch window, and the safety window
  5) Close the door
  6) Wait the door time
  7) Turn off alarm, clear monitor.
  ]]

  -- Open the door
  door_relay.setOutput(config.door_relay_side, true)
  alarm_relay.setOutput(config.alarm_relay_side, true)
  display_countdown(config.door_open_time, "Opening Silo")
  display_countdown(config.launch_window, "Launch Rocket")
  display_countdown(config.safety_window, "Safety Window")
  door_relay.setOutput(config.door_relay_side, false)
  display_countdown(config.door_close_time, "Closing Silo")
  alarm_relay.setOutput(config.alarm_relay_side, false)
end

local function middle_write(str, y, t)
  local width, height = t.getSize()
  local ox, oy = t.getCursorPos()
  local x = (width/2) - (#str/2)
  t.setCursorPos(x, y)
  t.write(str)
  t.setCursorPos(ox, oy)
end

local function display_button()
  -- Show a simple screen on the button monitor that says "Press here to launch".
  button_monitor.setTextScale(0.5)
  local width, height = button_monitor.getSize()
  local monitor_middle = math.floor(height/2)
  button_monitor.setBackgroundColour(config.button_monitor_background)
  button_monitor.setTextColour(config.button_monitor_foreground)
  button_monitor.clear()
  middle_write("Press Here", monitor_middle-1, button_monitor)
  middle_write("To Launch", monitor_middle, button_monitor)
end

local function main()
  -- Event loop is simple, wait for `monitor_touch`, make sure it matches the button monitor
  -- If it does, run the `launch_rocket` function.

  -- Set up the monitors
  launch_window.setVisible(false)
  launch_window.setBackgroundColour(config.launch_monitor_background)
  launch_window.setTextColour(config.launch_monitor_foreground)
  launch_window.clear()
  bigfont.writeOn(launch_window, config.launch_monitor_bigfont_size, "Idle")
  launch_window.setVisible(true)

  display_button()

  while true do
    local _, mon = os.pullEvent("monitor_touch")
    if mon == config.button_monitor then
      launch_rocket()
      launch_window.setVisible(false)
      launch_window.setBackgroundColour(config.launch_monitor_background)
      launch_window.setTextColour(config.launch_monitor_foreground)
      launch_window.clear()
      bigfont.writeOn(launch_window, config.launch_monitor_bigfont_size, "Idle")
      launch_window.setVisible(true)
      display_button()
    end
  end
end

main()