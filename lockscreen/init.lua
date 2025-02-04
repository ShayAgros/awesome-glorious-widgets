local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local naughty = require('naughty')
local beautiful = require('beautiful')
local filesystem = gears.filesystem
local config_dir = filesystem.get_configuration_dir()
local dpi = beautiful.xresources.apply_dpi
--local widget_icon_dir = config_dir .. 'configuration/user-profile/'

-- Add paths to package.cpath
package.cpath = package.cpath .. ';' .. config_dir .. '/library/?.so'
local pam = require('liblua_pam')

-- Configuration table
local config = {
	-- Fallback Password
	-- THIS EXIST TO PREVENT THE ERROR CAUSED BY THE DIFFERENCE OF LUA VERSIONS USED ON COMPILING THE LUA_PAM LIB
	-- READ THE WIKI - ABOUT MODULE SECTION; TO FIX THE LIBRAY ERROR IF YOU HAVE ONE
	-- ONLY USE THIS AS A TEMPORARY SUBSTITUTE TO LUA_PAM
	fallback_password = function()
		-- Set your password here
		return '123456'
	end,

	fakepassword = 'password',

	-- General Configuration
	-- Capture a picture using webcam
	capture_intruder = true,

	-- Save location, auto creates
	face_capture_dir = '/tmp/Intruders/',

	-- Background Mode Configuration
	-- True to blur the background
	blur_background = false,

	wallparer_path = '/home/ANT.AMAZON.COM/shayagr/Downloads/wallpapers/the-wisdom-of-the-cheshire-puss-1920×1080.jpg',
	-- Wallpaper directory
	wall_dir = '/home/ANT.AMAZON.COM/shayagr/Downloads/wallpapers/',

	-- Default wallpaper
	default_wall_name = 'ice-amp-fire-1920x1080.jpg',

	-- /tmp directory
	tmp_wall_dir = '/tmp/awesomewm/' .. os.getenv('USER') .. '/'
}

-- Useful variables (DO NOT TOUCH THESE)
local input_password = ''
local lock_again = nil
local type_again = true
local capture_now = config.capture_intruder
local locked_tag = nil

local uname_text = wibox.widget {
	id = 'uname_text',
	markup = '$USER',
	font = 'Inter Bold 12',
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local caps_text = wibox.widget {
	id = 'uname_text',
	markup = 'Caps Lock is on',
	font = 'Inter Italic 10',
	align = 'center',
	valign = 'center',
	opacity = 0.0,
	widget = wibox.widget.textbox
}

local profile_imagebox = wibox.widget {
	id = 'user_icon',
	image = config_dir .. 'tux.png',
	resize = true,
	forced_height = dpi(120),
	forced_width = dpi(120),
	--clip_shape = gears.shape.circle,
	widget = wibox.widget.imagebox
}

local time = wibox.widget.textclock(
	'<span font=\'Inter Bold 56\'>%I:%M %p</span>',
	1
)

local wanted_text = wibox.widget {
	markup = 'INTRUDER ALERT!',
	font   = 'Inter Bold 12',
	align  = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local msg_table = {
	'This incident will be reported.',
	'We are watching you.',
	'We know where you live.',
	'RUN!',
	'Yamete, Oniichan~ uwu',
	'This will self-destruct in 5 seconds!',
	'Image successfully sent!',
	'You\'re doomed!',
	'Authentication failed!',
	'I am watching you.',
	'I know where you live.',
	'RUN!',
	'Your parents must be proud of you'
}

local wanted_msg = wibox.widget {
	markup = 'This incident will be reported!',
	font   = 'Inter Regular 10',
	align  = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local wanted_image = wibox.widget {
	image  = config_dir .. 'evil_tux.jpg',
	resize = true,
	forced_height = dpi(120),
	clip_shape = gears.shape.rounded_rect,
	widget = wibox.widget.imagebox
}

local date_value = function()
	local ordinal = nil
	local date = os.date('%d')
	local day = os.date('%A')
	local month = os.date('%B')

	local first_digit = string.sub(date, 0, 1)
	local last_digit = string.sub(date, -1)
	if first_digit == '0' then
	  date = last_digit
	end

	if last_digit == '1' and date ~= '11' then
	  ordinal = 'st'
	elseif last_digit == '2' and date ~= '12' then
	  ordinal = 'nd'
	elseif last_digit == '3' and date ~= '13' then
	  ordinal = 'rd'
	else
	  ordinal = 'th'
	end

	return date .. ordinal .. ' of ' .. month .. ', ' .. day
end

local date = wibox.widget {
	markup = date_value(),
	font = 'Inter Bold 20',
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local password_box = wibox.widget {
	markup = "",
	font = 'Inter Bold 20',
	align = 'left',
	valign = 'center',
	widget = wibox.widget.textbox
}

local circle_container = wibox.widget {
	bg = '#E88282',
	forced_width = dpi(130),
	forced_height = dpi(130),
	shape = gears.shape.circle,
	widget = wibox.container.background,
	visible = true,
}

local rounded_rect = function(cr, width, height)
    return gears.shape.rounded_rect(cr, width, height, 40)
end

-- Rotation direction table
local rotation_direction = {'north', 'west', 'south', 'east'}

-- Red, Green, Yellow, Blue
local red = '#FF0000'
local green = '#00FF00'
local yellow = '#BDB76B'
local blue = '#0000FF'

-- Color table
local arc_color = {red, green, yellow, blue}

-- Processes
local locker = function(s)

	print("lockscreen initial setup is initiated")

	local lockscreen = wibox {
		screen = s,
		visible = false,
		ontop = true,
		type = 'splash',
		width = s.geometry.width,
		height = s.geometry.height,
		bg = beautiful.background,
		fg = beautiful.fg_normal
	}

	-- Update username textbox
	awful.spawn.easy_async_with_shell(
		"whoami",
		function(stdout)
			stdout = stdout:gsub('%\n','')
			uname_text.markup = stdout
		end
	)

	local wanted_poster = awful.popup {
		widget 		   		= {
			{
				{
					wanted_text,
					{
						nil,
						wanted_image,
						nil,
						expand = 'none',
						layout = wibox.layout.align.horizontal
					},
					wanted_msg,
					spacing = dpi(5),
					layout = wibox.layout.fixed.vertical
				},
				margins = dpi(20),
				widget = wibox.container.margin
			},
			bg = beautiful.background,
			shape = gears.shape.rounded_rect,
			widget = wibox.container.background
		},
		bg 					= beautiful.transparent,
		type 				= 'utility',
		ontop 				= true,
		shape          		= gears.shape.rectangle,
		maximum_width  		= dpi(250),
		maximum_height 		= dpi(250),
		hide_on_right_click = false,
		preferred_anchors 	= {'top'},
		visible 	   		= false
	}

	-- Place wanted poster at the bottom of primary screen
	awful.placement.top(
		wanted_poster,
		{
			margins =  {
				top = dpi(10)
			}
		}
	)

	-- Check Capslock state
	local check_caps = function()
		awful.spawn.easy_async_with_shell(
			--'xset q | sed -En "s/.*Caps Lock:\s*(on|off).*/\1/p"',
			'xset q | grep Caps | cut -d: -f3 | cut -d0 -f1 | tr -d \' \'',
			function(stdout)
				if stdout:match('on') then
					caps_text.opacity = 1.0
				else
					caps_text.opacity = 0.0
				end
				caps_text:emit_signal('widget::redraw_needed')
			end
		)
	end

	-- Rotate the color arc on random direction
	local locker_arc_rotate = function()

		local direction = rotation_direction[math.random(#rotation_direction)]
		local color = arc_color[math.random(#arc_color)]
	end

	-- Check webcam
	local check_webcam = function()
		awful.spawn.easy_async_with_shell(
			'ls /dev/video0',
			function(stdout)
				if not config.capture_intruder then
					capture_now = false
					return
				end

				if not stdout:match('/dev/video0') then
					capture_now = false
				else
					capture_now = true
				end
			end
		)
	end

	check_webcam()
	-- Snap an image of the intruder
	local intruder_capture = function()
		local capture_image = [[
		save_dir="]] .. config.face_capture_dir .. [["
		date="$(date +%Y%m%d_%H%M%S)"
		file_loc="${save_dir}SUSPECT-${date}.png"

		if [ ! -d "$save_dir" ]; then
			mkdir -p "$save_dir";
		fi

		if which > /dev/null 2>&1 ; then
			ffmpeg -f video4linux2 -s 800x600 -i /dev/video0 -ss 0:0:2 -frames 1 "${file_loc}"

			canberra-gtk-play -i camera-shutter &
			echo "${file_loc}"

		else
			echo "/home/ANT.AMAZON.COM/shayagr/.config/awesome/evil_tux.jpg"
		fi
		]]

		-- Capture the filthy intruder face
		awful.spawn.easy_async_with_shell(
			capture_image,
			function(stdout)

				-- Humiliate the intruder by showing his/her hideous face
				wanted_image:set_image(stdout:gsub('%\n',''))
				wanted_msg:set_markup(msg_table[math.random(#msg_table)])
				wanted_poster.visible= true

				awful.placement.top(
					wanted_poster,
					{
						margins = {
							top = dpi(10)
						}
					}
				)

				wanted_image:emit_signal('widget::redraw_needed')
				type_again = true
			end
		)
	end

	-- Login failed
	local stoprightthereyoucriminalscum = function()

		circle_container.bg = red .. 'AA'

		if capture_now then
			intruder_capture()
		else
			gears.timer.start_new(
				1,
				function()
					circle_container.bg = beautiful.groups_title_bg
					type_again = true
				end
			)
		end

		input_password = ''
		password_box.markup = ''
	end

	-- Login successful
	local generalkenobi_ohhellothere = function()

		circle_container.bg = green .. 'AA'

		-- Add a little delay before unlocking completely
		gears.timer.start_new(
			1,
			function()
				if capture_now then
					-- Hide wanted poster
					wanted_poster.visible = false
				end

				-- Select old tag
				-- And restore minimized focused client if there's any
				if locked_tag then
					locked_tag.selected = true
					locked_tag = nil
				end

				local c = awful.client.restore()
				if c then
					client.focus = c
					c:raise()
				end

				-- Hide all the lockscreen on all screen
				for s in screen do
					if s.index == 1 then
						s.lockscreen.visible = false
					else
						s.lockscreen_extended.visible = false
					end
				end

				circle_container.bg = beautiful.groups_title_bg

				-- Enable locking again
				lock_again = true

				-- Enable validation again
				type_again = true
			end
		)

		input_password = ''
		password_box.markup = ''
	end

	-- A backdoor
	-- Sometimes I'm too lazy to type so I decided to create this
	-- Sometimes my genius is... it's almost frightening
	local back_door = function()
		generalkenobi_ohhellothere()
	end

	-- Check module if valid
	local module_check = function(name)
		if package.loaded[name] then
			return true
		else
			for _, searcher in ipairs(package.searchers or package.loaders) do
				local loader = searcher(name)
				if type(loader) == 'function' then
					package.preload[name] = loader
					return true
				end
			end
			return false
		end
	end

	-- Password/key grabber
	local password_grabber = awful.keygrabber {
		autostart          = false,
		stop_event          = 'release',
		mask_event_callback = true,
		keybindings = {
			{{'Control', }, 'u', function(self)
					input_password = ''
					password_box.markup = ''
			end},

			{{'Mod4', 'Shift' }, 'Return', function(self)
					if not type_again then
						return
					end
					self:stop()

					-- Call backdoor
					back_door()
			end},
		},
		keypressed_callback = function(self, mod, key, command)

			if not type_again then
				return
			end

			-- Clear input string
			if key == 'Escape' then
				input_password = ''
				password_box.markup = ''

			elseif key == 'BackSpace' then
				-- Clear input threshold
				if input_password and string.len(input_password) > 0 then
					input_password = string.sub(input_password, 0, string.len(input_password) - 1)
				end

			-- Accept only the single charactered key
			-- Ignore 'Shift', 'Control', 'Return', 'F1', 'F2', etc., etc.
			elseif #key == 1 then

				input_password = input_password .. key

			end

			if string.len(input_password) <= string.len(config.fakepassword) then
				password_box.markup = string.sub(config.fakepassword, 0, string.len(input_password))
				--password_box.markup = input_password
			end

		end,
		keyreleased_callback = function(self, mod, key, command)

			if key == 'Caps_Lock' then
				check_caps()
				return
			end

			if not type_again then
				return
			end

			-- Validation
			if key == 'Return' then

				-- Validate password
				local authenticated = false
				if input_password ~= '' then
					-- If lua-pam library is 'okay'
					if module_check('liblua_pam') then
						--local pam = require('liblua_pam')
						authenticated = pam:auth_current_user(input_password)
					else
						-- Library doesn't exist or returns an error due to some reasons (read the manual)
						-- Use fallback password data
						authenticated = input_password == config.fallback_password()

						local rtfm = naughty.action {
							name = 'Read Manual',
							   icon_only = false
						}

						local dismiss = naughty.action {
							name = 'Dismiss',
							   icon_only = false
						}

						rtfm:connect_signal(
							'invoked',
							function()
								awful.spawn(
									[[sh -c "
									xdg-open 'https://github.com/manilarome/the-glorious-dotfiles/wiki/About-Modules#lockscreen-module'
									"]],
									false
								)
							end
						)

						naughty.notification({
							app_name = 'Security',
							title = 'WARNING',
							message = 'You\'re using the fallback password! It\'s better if you fix the library error.',
							urgency = 'critical',
							actions = { rtfm, dismiss }
						})
						--naughty.notify({ preset = naughty.config.presets.critical,
										 --title = "Oops, an error happened!",
										 --text = 'You\'re using the fallback password! It\'s better if you fix the library error.' })
					end
				end

				if authenticated then
					-- Come in!
					self:stop()
					generalkenobi_ohhellothere()
				else
					-- F*ck off, you [REDACTED]!
					stoprightthereyoucriminalscum()
				end

				-- Allow typing again and empty password container
				type_again = false
			end

		end

	}

	lockscreen : setup {
		layout = wibox.container.place,
		halign = "center",
		valign = "top",
		{
			layout = wibox.layout.fixed.vertical,
			expand = 'none',
			spacing = dpi(20),
			{
				time,
				date,
				layout = wibox.layout.fixed.vertical
			},
			{
				layout = wibox.layout.fixed.vertical,
				{
					layout = wibox.layout.align.horizontal,
					{
						markup = 'password: ',
						font = 'Inter Bold 20',
						align = 'center',
						valign = 'center',
						widget = wibox.widget.textbox
					},

					--profile_imagebox,
					{
						layout = wibox.container.margin,
						left = 0,
						right = 2,
						top = 15,
						bottom = 15,
						{
							layout = wibox.container.background,
							--bg = '#ff0000',
							shape_border_color = '#838383ff',
							--shape_border_width = 2,
							shape_border_width = 0,
							shape = rounded_rect,
							{
								layout = wibox.container.margin,
								left = 10,
								right = 3,
								top = 1,
								bottom = 1,
								password_box,
							},
						},
					},
					nil,
				},
				nil,
				--uname_text,
				--caps_text
			},
		},
	}

	local show_lockscreen = function()

		-- Why is there a lock_again variable?
		-- It prevents the user to spam locking while in a process of authentication
		-- Prevents a potential bug/problem
		if lock_again == true or lock_again == nil then

			-- Check capslock status
			check_caps()

			-- Check webcam status
			check_webcam()

			-- Show all the lockscreen on each screen
			for s in screen do
				if s.index == 1 then
					s.lockscreen.visible = true
				else
					s.lockscreen_extended.visible = true
				end
			end

			-- Start keygrabbing, but with a little delay to
			-- give some extra time for the free_keygrab function
			gears.timer.start_new(
				0.5,
				function()
					-- Start key grabbing for password
					password_grabber:start()
				end
			)

			-- Dont lock again
			lock_again = false
		end
	end

	local free_keygrab = function()

		-- Check if there's a keygrabbing instance
		-- If yes, stop it
		local keygrabbing_instance = awful.keygrabber.current_instance
		if keygrabbing_instance then
			keygrabbing_instance:stop()
		end

		-- Unselect all tags and minimize the focused client
		-- These will also fix the problem with virtualbox or
		-- any other program that has keygrabbing enabled
		if client.focus then
			client.focus.minimized = true
		end
		for _, t in ipairs(mouse.screen.selected_tags) do
			locked_tag = t
			t.selected = false
		end
	end

	awesome.connect_signal(
		'module::lockscreen_show',
		function()
			if lock_again == true or lock_again == nil then
				-- Stop all current keygrabbing events
				free_keygrab()

				-- Show lockscreen
				show_lockscreen()
			end
		end
	)
	return lockscreen
end

-- This lockscreen is for the extra/multi monitor
local locker_ext = function(s)
	local extended_lockscreen = wibox {
		screen = s,
		visible = false,
		ontop = true,
		ontype = 'true',
		x = s.geometry.x,
		y = s.geometry.y,
		width = s.geometry.width,
		height = s.geometry.height,
		bg = beautiful.background,
		fg = beautiful.fg_normal
	}

	return extended_lockscreen
end

-- Create lockscreen for each screen
local create_lock_screens = function(s)
	print("called to initiate screen ix:", s.index)
	if s.index == 1 then
		s.lockscreen = locker(s)
	else
		s.lockscreen_extended = locker_ext(s)
	end
end

-- Don't show notification popups if the screen is locked
local check_lockscreen_visibility = function()
	focused = awful.screen.focused()
	if focused.lockscreen and focused.lockscreen.visible then
		return true
	end
	if focused.lockscreen_extended and focused.lockscreen_extended.visible then
		return true
	end
	return false
end

-- Notifications signal
--naughty.connect_signal(
	--'request::display',
	--function(_)
		--if check_lockscreen_visibility() then
			--naughty.destroy_all_notifications(nil, 1)
		--end
	--end
--)

-- Filter background image
local filter_bg_image = function(wall_name, index, ap, width, height)

	-- Checks if the blur has to be blurred
	local blur_filter_param = ''
	if config.blur_background then
		blur_filter_param = '-filter Gaussian -blur 0x10'
	end

	-- Create imagemagick command
	local magic = [[
	sh -c "
	if [ ! -d ]] .. config.tmp_wall_dir ..[[ ]; then mkdir -p ]] .. config.tmp_wall_dir .. [[; fi

	convert -quality 100 ]] .. ' '  .. blur_filter_param .. ' '.. config.wallparer_path ..
	[[ -gravity center -crop ]] .. ap .. [[:1 +repage -resize ]] .. width .. 'x' .. height ..
	[[! ]] .. config.tmp_wall_dir .. index .. wall_name .. [[
	"]]

	return magic
end

-- Apply lockscreen background image
local apply_ls_bg_image = function(s, wall_name)
	-- Iterate through all the screens and create a lockscreen for each of it
	local index = s.index .. '-'

	-- Get screen geometry
	--local screen_width = s.geometry.width
	--local screen_height = s.geometry.height
	local screen_width = s.geometry.width
	local screen_height = s.geometry.height

	-- Get the right resolution/aspect ratio that will be use as the background
	-- TODO: At least until you figure out how to stretch the image, make sure
	-- the aspect ration is always this. Otherwise images get cropped
	--local aspect_ratio = screen_width / screen_height
	local aspect_ratio = 1920 / 1080
	aspect_ratio = math.floor(aspect_ratio * 100) / 100

	-- Create image filter command
	local cmd = nil
	cmd = filter_bg_image(wall_name, index, aspect_ratio, screen_width, screen_height)

	-- Asign lockscreen to each screen
	if s.index == 1 then
		-- Primary screen
		awful.spawn.easy_async_with_shell(
			cmd,
			function()
				s.lockscreen.bgimage = config.tmp_wall_dir .. index .. wall_name

				--for key, value in pairs(s.lockscreen) do
					--print('\t', key, value)
				--end
			end
		)
	else
		-- Multihead screen/s
		awful.spawn.easy_async_with_shell(
			cmd,
			function()
				s.lockscreen_extended.bgimage = config.tmp_wall_dir .. index .. wall_name
			end
		)
	end
end

--awful.screen.connect_for_each_screen(function(s)
		--create_lock_screens(s)
		--apply_ls_bg_image(s, config.default_wall_name)
--end)

-- Create a lockscreen and its background for each screen on start-up
screen.connect_signal(
	'request::desktop_decoration',
	function(s)
		--naughty.notify({ preset = naughty.config.presets.critical,
						 --title = "desktop added",
						 --text = 'desktop_decoration called' })
		-- bug fix, this signal might be called only for some screens.
		-- Reinitialize all screens to be on the safe side
		for s in screen do
			create_lock_screens(s)
			apply_ls_bg_image(s, config.default_wall_name)
		end
	end
)

-- Regenerate lockscreens and its background if a screen was added to avoid errors
screen.connect_signal(
	'added',
	function(s)
		print("added signal called")
		--naughty.notify({ preset = naughty.config.presets.critical,
						 --title = "desktop added",
						 --text = 'added signal called' })
		-- bug fix, this signal might be called only for some screens.
		-- Reinitialize all screens to be on the safe side
		for s in screen do
			create_lock_screens(s)
			apply_ls_bg_image(s, config.default_wall_name)
		end
	end

)

function configure_lockscreen(s)
			create_lock_screens(s)
			apply_ls_bg_image(s, config.default_wall_name)
end

-- Regenerate lockscreens and its background if a screen was removed to avoid errors
screen.connect_signal(
	'removed',
	function(s)
		--naughty.notify({ preset = naughty.config.presets.critical,
						 --title = "desktop removed",
						 --text = 'removed signal called' })
		print("removed signal called")
		for s in screen do
			create_lock_screens(s)
			apply_ls_bg_image(s, config.default_wall_name)
		end
		--create_lock_screens(s)
		--apply_ls_bg_image(config.default_wall_name)
	end
)

return configure_lockscreen
