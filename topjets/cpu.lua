local wibox = require('wibox')
local utility = require('utility')
local iconic = require('iconic')
local scheduler = require('scheduler')

-- Module topjets.cpu
local cpu = {}

local cpu_usage  = {}
local cpu_total  = {}
local cpu_active = {}

local iconic_args = { preferred_size = "24x24" }
local icons

function cpu.new()

   local cpu_temp = wibox.widget.textbox()
   local cpu_load = wibox.widget.textbox()


   local _widget = wibox.layout.fixed.horizontal()
   _widget:add (cpu_temp)
   _widget:add (cpu_load)

   _widget.cpu_temp = cpu_temp
   _widget.cpu_load = cpu_load

   scheduler.register_recurring("cpu_update", 5,
                                function() cpu.update(_widget) end)
   return _widget
end


function cpu.update(w)
   local cpu_lines = {}

   -- Get CPU stats
   local f = io.open("/proc/stat")
   for line in f:lines() do
      if string.sub(line, 1, 3) ~= "cpu" then break end

      cpu_lines[#cpu_lines+1] = {}

      for i in string.gmatch(line, "[%s]+([^%s]+)") do
         table.insert(cpu_lines[#cpu_lines], i)
      end
   end
   f:close()

   -- Ensure tables are initialized correctly
   for i = #cpu_total + 1, #cpu_lines do
      cpu_total[i]  = 0
      cpu_usage[i]  = 0
      cpu_active[i] = 0
   end

   for i, v in ipairs(cpu_lines) do
      -- Calculate totals
      local total_new = 0
      for j = 1, #v do
         total_new = total_new + v[j]
      end
      local active_new = total_new - (v[4] + v[5])

      -- Calculate percentage
      local diff_total  = total_new - cpu_total[i]
      local diff_active = active_new - cpu_active[i]

      if diff_total == 0 then diff_total = 1E-6 end
      cpu_usage[i]      = math.floor((diff_active / diff_total) * 100)

      -- Store totals
      cpu_total[i]   = total_new
      cpu_active[i]  = active_new
   end

   local temp = utility.slurp("/sys/class/thermal/thermal_zone0/temp", "*line")
   temp = tonumber(temp) / 1000

   local line = string.format(" %d°C", temp)

   
   if string.len(cpu_usage[1]) == 1 then    
       w.cpu_temp:set_markup("0" .. cpu_usage[1] .. "%")
   else
       w.cpu_temp:set_markup("" .. cpu_usage[1] .. "%")
   end
   

   --w.cpu_temp:set_markup("☢" .. cpu_usage[1] .. "%")
   w.cpu_load:set_markup(line)

end

return setmetatable(cpu, { __call = function(_, ...) return cpu.new(...) end})
