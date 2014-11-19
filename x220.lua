-- Standard awesome library
local wibox       = require("wibox")
local gears       = require("gears")
local awful       = require("awful")
      scheduler   = require('scheduler')
      -- private     = require('private')
      awful.rules = require("awful.rules")
      require("awful.autofocus")
-- Theme handling library
local beautiful   = require('beautiful')
-- Notification library
      naughty     = require("naughty")
-- Logging library
      log         = require("log")
-- Quake console
local quake       = require("quake")
-- Menubar
local menubar     = require("menubar")
-- Utility
local utility     = require("utility")
-- Dictionary
local dict        = require("dict")
local statusbar   = require('statusbar')


-- Map useful functions outside
calc = utility.calc
notify_at = utility.notify_at

userdir = utility.pslurp("echo $HOME", "*line")


-- Autorun programs
autorunApps = {
  "setxkbmap -layout 'us, ua' -variant ',winkeys,winkeys' -option grp:alt_shift_toggle -option compose:ralt -option terminate:ctrl_alt_bksp"
}

runOnceApps = {
      'kbdd',
      'skype',
      'firefox'
}

utility.autorun(autorunApps, runOnceApps)



--Enabling numlockdo
awful.util.spawn("numlockx on")



-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/constellation/theme.lua")
-- beautiful.onscreen.init()


-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end



--{{{ Tag Wallpapers
--         for s = 1, screen.count() do
--             for t = 1, 6 do
--           awful.tag.gettags(s)[t]:connect_signal("property::selected", function (tag)
--            if not tag.selected then 
--             return 
--           end
--            theme.bg_normal = '#333333'
--              gears.wallpaper.maximized(beautiful.wallpaper, s, true)
--   end)
--     end
-- end



-- Top statusbar
for s = 1, screen.count() do
   statusbar.create(s)
end


-- Default system software
software = { terminal = "urxvt",
             terminal_cmd = "urxvt -e ",
             terminal_quake = "urxvt -pe tabbed",
             editor = "ec",
             editor_cmd = "ec ",
             browser = "firefox",
             browser_cmd = "firefox " }


-- Default modkey.
modkey = "Mod4"


-- Table of layouts to cover with awful.layout.inc, order matters.
layouts = {
   awful.layout.suit.floating, 	      -- 1
   awful.layout.suit.tile.left,       -- 2
   awful.layout.suit.max,		          -- 3
   awful.layout.suit.tile.bottom,             -- 3
}



-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
do
   local f, t, m = layouts[1], layouts[2], layouts[3]
   for s = 1, screen.count() do
      -- Each screen has its own tag table.
      tags[s] = awful.tag({ "/dev", "/net", "/im", "/doc", "/mov", "/oth"}, s,
                          {  f,  f ,  f ,  f ,  f ,  f })
   end
end


        for s = 1, screen.count() do
            for t = 1, 6 do

tags[s][t]:connect_signal("property::selected", function(t)
        statusbar.redraw(beautiful.bg_normal)
      if utility.is_empty(t,c) then
        statusbar.redraw(beautiful.bg_normal_free_tag)
      end

end)
end
end



-- Configure menubar
menubar.cache_entries = true
menubar.app_folders = { "/usr/share/applications/" }
menubar.show_categories = true
menubar.prompt_args = { bg_cursor = beautiful.bg_cursor }
menubar.geometry.height = 24;
menubar.refresh()


-- Interact with snap script

function snap ( filename )
   naughty.notify { title = "Screenshot captured: " .. filename:match ( ".+/(.+)" ),
                    text = "Left click to upload",
                    timeout = 10,
                    icon_size = 200,
                    icon = filename,
                    run = function (notif)
                       asyncshell.request ( "imgurbash " .. filename,
                                            function (f)
                                               local t = f:read()
                                               f:close()
                                               naughty.notify { title = "Image uploaded",
                                                                text = t,
                                                                run = function (notif)
                                                                   os.execute ( "echo " .. t .. " | xclip " )
                                                                   naughty.destroy(notif)
                                                                end }
                                            end )
                       naughty.destroy(notif)
                    end }
end





-- Smart Move a client to a screen. Default is next screen, cycling.
-- @param c The client to move.scripts/switch-d``isplay
-- @param s The screen number, default to current + 1.
function smart_movetoscreen(c, s)
  local was_maximized = { h = false, v = false }
  if c.maximized_horizontal then
     c.maximized_horizontal = false
     was_maximized.h = true
  end
  if c.maximized_vertical then
     c.maximized_vertical = false
     was_maximized.v = true
  end

  local sel = c or client.focus
  local current_tag = awful.tag.getidx()
  if sel then
     local sc = screen.count()
     if not s then
        s = sel.screen + 1
     end
     if s > sc then s = 1 elseif s < 1 then s = sc end
     sel.screen = s
     awful.client.movetotag(tags[s][current_tag])
     awful.tag.viewonly( tags[s][current_tag] )
     mouse.coords(screen[s].geometry)
  end

  if was_maximized.h then
     c.maximized_horizontal = true
  end
  if was_maximized.v then
     c.maximized_vertical = true
  end
end

function autoscreenenable()
  local dmode = utility.pslurp("cat /sys/class/drm/card0-VGA-1/status", "*line");                        
  local info = utility.pslurp("xrandr | grep VGA1", "*all");
  local position = "--right-of"
   if not info or string.len(info) == 0 then
      return false
   end


   local _, _, status = string.find(info, "VGA1 (%w+)");
   local _, _, _, mode, rest = string.find(info, "VGA1 (%w+) (%w+%+%d+%+%d+)");

  if (status == "connected") then
    if (mode == nil) then
      utility.spawn_in_terminal("xrandr --output VGA1 --auto "..position.." LVDS1"); 
    else
      utility.spawn_in_terminal("xrandr --output VGA1 --off");
    end 
  else
      utility.spawn_in_terminal("xrandr --output VGA1 --off");
  end
  -- if (dmode == "connected" ) then                             
    -- utility.spawn_in_terminal("xrandr --output VGA1 --auto --right-of LVDS1");       
  -- end
end




-- {{{ Key bindings
globalkeys = awful.util.table.join(
   awful.key({ modkey, "Control" }, "r", awesome.restart),	
   awful.key({                   }, "XF86MonBrightnessUp",    function() awful.util.spawn("xbacklight -inc 1") end),
   awful.key({                   }, "XF86MonBrightnessDown",  function() awful.util.spawn("xbacklight -dec 1") end),
   awful.key({         "Shift"   }, "XF86MonBrightnessUp",    function() awful.util.spawn("xbacklight -inc 5") end),
   awful.key({         "Shift"   }, "XF86MonBrightnessDown",  function() awful.util.spawn("xbacklight -dec 5") end),
   -- awful.key({                   }, "XF86Launch1",            function() utility.spawn_in_terminal("ncmpc") end),
   awful.key({                   }, "Scroll_Lock",            function() utility.spawn_in_terminal("scripts/omniscript") end),
   awful.key({                   }, "XF86Battery",            function() utility.spawn_in_terminal("sudo scripts/flashmanager") end),
   awful.key({                   }, "XF86Display",            function() utility.spawn_in_terminal("scripts/switch-display") end),
   awful.key({                   }, "XF86AudioLowerVolume",   function() statusbar.widgets.vol:dec() end),
   awful.key({                   }, "XF86AudioRaiseVolume",   function() statusbar.widgets.vol:inc() end),
   awful.key({                   }, "XF86AudioMute",   function() statusbar.widgets.vol:mute() end),
   awful.key({         "Shift"   }, "XF86AudioLowerVolume",   function() statusbar.widgets.vol:mute() end),
   awful.key({         "Shift"   }, "XF86AudioRaiseVolume",   function() statusbar.widgets.vol:unmute() end),
   -- awful.key({ modkey,           }, "e",      function() run_or_raise("pcmanfm", { class = "pcmanfm" }) end),
   awful.key({ modkey,           }, "e",      function() awful.util.spawn("pcmanfm")    end),
   -- awful.key({ modkey,           }, "d",      function()  utility.view_first_empty()    end ),
   awful.key({ modkey,           }, "=",      dict.lookup_word),
   awful.key({ modkey,           }, "Left",   function() utility.view_non_empty(-1)     end),
   awful.key({ modkey,           }, "Right",  function() utility.view_non_empty(1)      end),
   --awful.key({ modkey,           }, "Tab",    awful.tag.history.restore),

   awful.key({ modkey,           }, "Tab",   function () awful.client.focus.byidx( 1) if client.focus then client.focus:raise() end end),
   awful.key({ modkey, "Shift"   }, "Tab",   function () awful.client.focus.byidx(-1) if client.focus then client.focus:raise() end end),
   --awful.key({ modkey,           }, "j",    function () awful.client.focus.byidx( 1) if client.focus then client.focus:raise() end end),
   --awful.key({ modkey,           }, "k",    function () awful.client.focus.byidx(-1) if client.focus then client.focus:raise() end end),
   awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

   -- Layout manipulation
   awful.key({ modkey, "Shift"   }, "Up",   function () awful.client.swap.byidx(  1)       end),
   awful.key({ modkey, "Shift"   }, "Down",  function () awful.client.swap.byidx( -1)       end),
   awful.key({ modkey, "Control" }, "j",    function () awful.screen.focus_relative( 1)    end),
   awful.key({ modkey, "Control" }, "k",    function () awful.screen.focus_relative(-1)    end),
   awful.key({ modkey,           }, "u",    awful.client.urgent.jumpto),
   awful.key({ modkey,           }, "i",    function () awful.screen.focus_relative( 1)    end),
   awful.key({ modkey,        }, "s",    autoscreenenable ),
   --awful.key({ modkey,           }, "Tab",  function () awful.client.focus.history.previous() if client.focus then client.focus:raise() end end),

   -- Standard program
   awful.key({ modkey,           }, "`", function () quake.toggle({ terminal = software.terminal_quake,
                                                                         name = "URxvt",
                                                                         height = 0.5,
                                                                         skip_taskbar = false,
                                                                         ontop = true })
                                              end),



   awful.key({ modkey,            }, "p",     function () menubar.show()                end),
   -- awful.key({ modkey, "Shift"    }, "h",     function () awful.tag.incnmaster( 1)      end),
   -- awful.key({ modkey, "Shift"    }, "l",     function () awful.tag.incnmaster(-1)      end),
   awful.key({ modkey, "Control"  }, "h",     function () awful.tag.incncol( 1)         end),
   awful.key({ modkey, "Control"  }, "l",     function () awful.tag.incncol(-1)         end),
   awful.key({ modkey,            }, "space", function () awful.layout.inc(layouts,  1) end),
   awful.key({ modkey, "Shift"    }, "space", function () awful.layout.inc(layouts, -1) end),
   awful.key({ modkey, "Control"  }, "n", awful.client.restore),
   -- awful.key({                    }, "Print",  function () awful.util.spawn_with_shell("scrot -e 'mv $f ~/Pictures/screenshots/ 2>/dev/null'") end),
   awful.key({                    }, "Print", function () awful.util.spawn("snap " .. os.date("%d%m%Y_%H%M%S")) end ),
   -- awful.key({ modkey             }, "Print", function () utility.spawn_in_terminal("scripts/snappy") end),
   awful.key({ modkey             }, "Print", function () utility.spawn("file=/home/frunzik/Pictures/Screenshot_$(date '+%Y%m%d-%H%M%S').png && gnome-screenshot -a --file=$file && imgurbash $file") end),
   awful.key({ modkey             }, "b", function ()
                                 statusbar.wiboxes[mouse.screen].visible = not statusbar.wiboxes[mouse.screen].visible
                                 local clients = client.get()
                                 local curtagclients = {}
                                 local tags = screen[mouse.screen]:tags()
                                 for _, c in ipairs(clients) do
                                    for k, t in ipairs(tags) do
                                       if t.selected then
                                          local ctags = c:tags()
                                          for _, v in ipairs(ctags) do
                                             if v == t then
                                                table.insert(curtagclients, c)
                                             end
                                          end
                                       end
                                    end
                                 end
                                 for _, c in ipairs(curtagclients) do
                                    if c.maximized_vertical then
                                       c.maximized_vertical = false
                                       c.maximized_vertical = true
                                    end
                                 end
                              end),
   -- Prompt
   awful.key({ modkey }, "r", function ()
                                 local promptbox = statusbar.widgets.prompt[mouse.screen]
                                 awful.prompt.run({ prompt = promptbox.prompt,
                                                    bg_cursor = beautiful.bg_cursor },
                                                  promptbox.widget,
                                                  function (...)
                                                     local result = awful.util.spawn(...)
                                                     if type(result) == "string" then
                                                        promptbox.widget:set_text(result)
                                                     end
                                                  end,
                                                  awful.completion.shell,
                                                  awful.util.getdir("cache") .. "/history")
                              end)
   )


clientkeys = awful.util.table.join(
   awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
   awful.key({ modkey,           }, "k",      function (c) c:kill()                         end),
   awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
   awful.key({ modkey,           }, "o",      smart_movetoscreen                        ),
   awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
   awful.key({ modkey,           }, "n",
             function (c)
                -- The client currently has the input focus, so it cannot be
                -- minimized, since minimized clients can't have the focus.
                c.minimized = true
             end),
   awful.key({ modkey,           }, "m",
             function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c.maximized_vertical   = not c.maximized_vertical
             end)
)




-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
   globalkeys = awful.util.table.join(globalkeys,
                                      awful.key({ modkey }, "#" .. i + 9,
                                                function ()
                                                   local screen = mouse.screen
                                                   if tags[screen][i] then
                                                      awful.tag.viewonly(tags[screen][i])
                                                   end
                                                end),
                                      awful.key({ modkey, "Control" }, "#" .. i + 9,
                                                function ()
                                                   local screen = mouse.screen
                                                   if tags[screen][i] then
                                                      awful.tag.viewtoggle(tags[screen][i])
                                                   end
                                                end),
                                      awful.key({ modkey, "Shift" }, "#" .. i + 9,
                                                function ()
                                                   if client.focus and tags[client.focus.screen][i] then
                                                      awful.client.movetotag(tags[client.focus.screen][i])
                                                   end
                                                end),
                                      awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                                                function ()
                                                   if client.focus and tags[client.focus.screen][i] then
                                                      awful.client.toggletag(tags[client.focus.screen][i])
                                                   end
                                                end))
end

clientbuttons = awful.util.table.join(
   awful.button({        }, 1, function (c) client.focus = c; c:raise() end),
   awful.button({ modkey }, 1, awful.mouse.client.move),
   awful.button({ modkey }, 3, awful.mouse.client.resize))


-- Set keys
-- statusbar.widgets.mpd:append_global_keys()
root.keys(globalkeys)


-- {{{ Rules
awful.rules.rules = {
   -- All clients will match this rule.
   { rule = { },
     properties = { border_width = beautiful.border_width,
                    border_color = beautiful.border_normal,
                    size_hints_honor = false,
                    focus = awful.client.focus.filter, 
                    keys = clientkeys,
                    sticky = false,
                    buttons = clientbuttons
                  }},
    --/dev Screen
    { rule = { class = "idea"       },  properties = { tag = tags[1][1], maximized_vertical = true, maximized_horizontal = true} },
    { rule = { class = "rubymine"   },  properties = { tag = tags[1][1], maximized_vertical = true, maximized_horizontal = true} },
    { rule = { class = "subl"       },  properties = { tag = tags[1][1], switchtotag = true  } },
    { rule = { class = "Emacs"      },  properties = { tag = tags[1][1], switchtotag = true  } },

     --/net Screen
    { rule = { class = "Firefox"   },   properties = { tag = tags[1][2], maximized_vertical = true, maximized_horizontal = true }, callback = awful.titlebar.add },
    { rule = { class = "Chromium"  },   properties = { tag = tags[1][2] } },

     --/im Screen
    { rule = { class = "Skype"     },   properties = { tag = tags[1][3] } },
    
    { rule = { class = "Viber"     },   properties = { tag = tags[1][3]  } },
    
     --/doc Screen
    { rule = { class = "Pcmanfm"   },   properties = {  tag = tags[1][4], switchtotag = true,
                                                        maximized_vertical = true,
                                                        maximized_horizontal = true } },
    
    { rule = { class = "Evince"    },   properties = {  tag = tags[1][4], 
                                                        maximized_vertical = true,
                                                        maximized_horizontal = true
                                                        } },
    
     --/mov Screen
    { rule = { class = "Vlc"       },   properties = {  tag = tags[1][5] , switchtotag = true
                                                        
                                                        } },

    { rule = { class = "MPlayer"   },   properties = {  tag = tags[1][5] ,
                                                        maximized_vertical = true,
                                                        maximized_horizontal = true } },

                                                   
     --/oth Screen
    { rule = { class = "Transmission"       },  properties = { tag = tags[1][6] } },

     --every Screen
    { rule = { class = "Gpicview"  },   properties = {  -- maximized_vertical = true,
                                                        -- maximized_horizontal = true,
                                                        -- fullscreen = true 
                                                        } },     
    { rule = { class = "urxvt"  },   properties = {  focus = true
                                                        -- maximized_horizontal = true,
                                                        -- fullscreen = true 
                                                        } },  

}


-- Signals
--Signal function to execute when a new client appears.
client.connect_signal("manage",
                      function (c, startup)

                         if not startup then
                            -- Set the windows at the slave,
                            -- i.e. put it at the end of others instead of setting it master.
                            awful.client.setslave(c)

                            -- Put windows in a smart way, only if they does not set an initial position.
                            if not c.size_hints.user_position and not c.size_hints.program_position then
                               awful.placement.no_overlap(c)
                               awful.placement.no_offscreen(c)
                            end
                         end

                            statusbar.redraw(beautiful.bg_normal)
                              if utility.is_empty(tag,c) then
                             statusbar.redraw(beautiful.bg_normal_free_tag)
                            end


                         local titlebars_enabled = false
                         if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
                            -- Widgets that are aligned to the left
                            local left_layout = wibox.layout.fixed.horizontal()
                            left_layout:add(awful.titlebar.widget.iconwidget(c))

                            -- Widgets that are aligned to the right
                            local right_layout = wibox.layout.fixed.horizontal()
                            right_layout:add(awful.titlebar.widget.floatingbutton(c))
                            right_layout:add(awful.titlebar.widget.maximizedbutton(c))
                            right_layout:add(awful.titlebar.widget.stickybutton(c))
                            right_layout:add(awful.titlebar.widget.ontopbutton(c))
                            right_layout:add(awful.titlebar.widget.closebutton(c))

                            -- The title goes in the middle
                            local title = awful.titlebar.widget.titlewidget(c)
                            title:buttons(awful.util.table.join(
                                             awful.button({ }, 1, function()
                                                             client.focus = c
                                                             c:raise()
                                                             awful.mouse.client.move(c)
                                                                  end),
                                             awful.button({ }, 3, function()
                                                             client.focus = c
                                                             c:raise()
                                                             awful.mouse.client.resize(c)
                                                                  end)
                                                               ))

                            -- Now bring it all together
                            local layout = wibox.layout.align.horizontal()
                            layout:set_left(left_layout)
                            layout:set_right(right_layout)
                            layout:set_middle(title)

                            awful.titlebar(c):set_widget(layout)
                         end
                      end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus      end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal   end)



-- awful.util.spawn_with_shell("wmname LG3D")

scheduler.start()
-- }}}
