local iconic = require('iconic')
local wibox = require('wibox')
local scheduler = require('scheduler')
local naughty = require('naughty')
local utility = require('utility')

local volume = {}

local icons
local widget_opts = { preferred_size = '16x16' }

local function get_master_infos(f)
  -- local f=io.popen("amixer get Master")
  for line in f:lines() do
    if string.match(line, "%s%[%d+%%%]%s") ~= nil then
      volume=string.match(line, "%s%[%d+%%%]%s")
      volume=string.gsub(volume, "[%[%]%%%s]","")
    end
    if string.match(line, "%s%[[%l]+%]$") then
      state=string.match(line, "%s%[[%l]+%]$")
      state=string.gsub(state,"[%[%]%%%s]","")
    end
  end
  f:close()
  return state, volume
end

local function notify_volume(w, state, volume, icon)
   local n = naughty.notify({ title = "Volume: " .. volume .. "%",
                              text = "State: " .. state,
                              icon = icon, icon_size = 32, timeout = 3,
                              replaces_id = w.notification_id})
   w.notification_id = n.id
end

local function update_volume(w, f, to_notify)
   local state, vol = get_master_infos(f)
   local naughty_icon
   vol = tonumber(vol)
   if state == "off" then
      w:set_image(icons.muted)
      naughty_icon = icons.muted_big
   elseif vol >= 75 then
      w:set_image(icons.high)
      naughty_icon = icons.high_big
   elseif vol >= 50 then
      w:set_image(icons.medium)
      naughty_icon = icons.medium_big
   elseif vol >= 25 then
      w:set_image(icons.low)
      naughty_icon = icons.low_big
   else
      w:set_image(icons.zero)
      naughty_icon = icons.zero_big
   end
   if to_notify then
      notify_volume(w, state, vol, naughty_icon)
   end
end

function volume.inc(w)
   update_volume(w, io.popen("amixer -c 0 set Master 1dB+"), true)
end

function volume.dec(w)
   update_volume(w, io.popen("amixer -c 0 set Master 1dB-"), true)
end

local function mute(w)
   update_volume(w, io.popen("amixer -c 0 set Speaker mute"), true)
   update_volume(w, io.popen("amixer -c 0 set Headphone mute"), true)
   update_volume(w, io.popen("amixer -c 0 set Master mute"), true)
end

function unmute(w)
   update_volume(w, io.popen("amixer -c 0 set Speaker unmute"), true)
   update_volume(w, io.popen("amixer -c 0 set Headphone unmute"), true)
   update_volume(w, io.popen("amixer -c 0 set Master unmute"), true)
end

function volume.mute(w)
  mute(w)
end

function volume.unmute(w)
  unmute(w)
end

function volume.toggle(w)

  local state, vol = get_master_infos(io.popen("amixer -c 0 get Master"))
  if state == "off" then
    unmute(w)
  else
    mute(w)
  end
end

function volume.new()
   icons = { high       = iconic.lookup_status_icon('audio-volume-high-panel'   , widget_opts),
             medium     = iconic.lookup_status_icon('audio-volume-medium-panel' , widget_opts),
             low        = iconic.lookup_status_icon('audio-volume-low-panel'    , widget_opts),
             zero       = iconic.lookup_status_icon('audio-volume-zero-panel'   , widget_opts),
             muted      = iconic.lookup_status_icon('audio-volume-muted-panel'  , widget_opts),
             high_big   = iconic.lookup_status_icon('audio-volume-high-panel')  ,
             medium_big = iconic.lookup_status_icon('audio-volume-medium-panel'),
             low_big    = iconic.lookup_status_icon('audio-volume-low-panel')   ,
             zero_big   = iconic.lookup_status_icon('audio-volume-zero-panel')  ,
             muted_big  = iconic.lookup_status_icon('audio-volume-muted-panel')   }

   local w = wibox.widget.imagebox()
   w.inc = volume.inc
   w.dec = volume.dec
   w.mute = volume.mute
   w.unmute = volume.unmute
   w.toggle = volume.toggle
   scheduler.register_recurring("topjets_volume", 10,
                                function()
                                   update_volume(w, io.popen("amixer sget Master"), false)
                                end)
   return w
end

return setmetatable(volume, { __call = function(_, ...) return volume.new(...) end})
