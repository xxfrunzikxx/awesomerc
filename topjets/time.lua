local wibox = require('wibox')
local utility = require('utility')
local iconic = require('iconic')
local scheduler = require('scheduler')


-- Module topjets.time
local time = {}


function time.new()
  local datetime = wibox.widget.textbox()
  local ltime = wibox.layout.fixed.horizontal()

  ltime:add (datetime)
  ltime.datetime = datetime
     
   scheduler.register_recurring("topjets.clock", 60,
                                function()
                                   ltime.datetime:set_markup(os.date("%H:%M "))
                                end)
   
   utility.add_hover_tooltip(ltime,
                                function()
                                   return { text = os.date("%d %B  %Y \n    %A")}
                                end)

   return ltime
end








return setmetatable(time, { __call = function(_, ...) return time.new(...) end})
