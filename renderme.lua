-- License: GPLv3 or any later version
--
-- Authors: Lsyncd devs and Riccardo Gagliarducci
-- From the idea in: https://lsyncd.github.io/lsyncd/manual/examples/auto-image-magic/
--
-- Start a Blender render each time a file with "renderme" appears
--
-- Prerequisites
-- Lua 5.3 and liblua5.3-dev
-- Lsyncd version 2.3.1. Check using $lsyncd -version. You need cmake to compile.
-- Blender, better if linked ex. sudo ln -s /home/user/blender-4.2.0-linux-x64/blender /usr/local/bin
--
-- Usage
-- Configure your params
-- Copy this file in a folder, ex. /etc/lsyncd/renderme.lua
-- Launch the rendering service ex. lsyncd /etc/lsyncd/renderme.lua
-- use lsyncd -nodaemon /etc/lsyncd/lsyncd.lua to debug...
--
-- Nerd config
-- If you customize the "renderme" string in different machines you can distribuite jobs...
--
-- Todo
-- Make easy to edit variables

-- require "config"
local config = require "config"

log("Normal", "Watching  " .. config.general.watchdir)


settings {
    logfile    = "/var/log/lsyncd.log",
    statusFile = "/var/log/lsyncd-status.log",
    nodaemon   = false
}

local formats = { blend = true }

render = {
	delay = 0,

	maxProcesses = 1,

	action = function(inlet)
		local event = inlet.getEvent()

		if event.isdir then
			-- ignores events on dirs
			inlet.discardEvent(event)
			return
		end

		-- extract extension and basefilename
		local filename = event.pathname
		local ext      = string.match(filename, ".*%.([^.]+)$")
		local base     = string.match(filename, "(.*)%.[^.]+$")

		if not formats[ext] then
			-- an unknown extension
			inlet.discardEvent(event)
			return
		end


		-- the path, more on lsyncd.lua source
		-- the baseDir as in config file
		local baseDir    = event.source

		-- the base dir of the current file, can be subdir
		local sourcePathdir = event.sourcePathdir
		-- fix double slash in path
		local sourcePathdir = string.gsub(sourcePathdir, "//", "/")

		-- render on create and modify
		if event.etype == "Create" or event.etype == "Modify" then

				-- Retrieve the hostname
				local machinehostname = io.popen('hostname'):read('*l')

				-- Name to check to stop process
				local machinehostnamestop = machinehostname .. "-stop"


                                -- Check if the file base contains the "hostname-stop"
                                if string.match(base, machinehostnamestop) then

                                                -- Rename the file to remove "machinehostnamestop"
                                                local new_filename = string.gsub(filename, machinehostnamestop, "")
                                                os.rename(baseDir .. filename, baseDir .. new_filename)
                                                
                                                -- Sigterm the rendering process
                                                os.execute('ps -a -o "cmd" -o "|%p" | grep "' .. new_filename .. '" | grep -v "grep" | cut -d"|" -f2- | xargs -I % kill -s 15 %')

						-- Write the processing status in lprocessing.txt, in the same source folder
						os.execute('echo $(date "+%Y-%m-%d") - Rendering stopped by user on $(hostname) ' .. new_filename .. '" >> ' .. sourcePathdir .. 'lprocessing.txt')

                                                log("Normal", "Rendering stopped ".. baseDir .. new_filename)
                                                os.execute(command)

				-- Check if the file base contains the hostname of the machine
				elseif string.match(base, machinehostname) then

						-- Rename the file to remove "machinehostname"
						local new_filename = string.gsub(filename, machinehostname, "")
						os.rename(baseDir .. filename, baseDir .. new_filename)

						-- Write the processing status in lprocessing.txt, in the same source folder
						os.execute('echo $(date "+%Y-%m-%d") - Queued or processed by $(hostname) ' .. new_filename .. '" >> ' .. sourcePathdir .. 'lprocessing.txt')

						-- Run the Blender command with the new file name
						local command = 'blender -b "' .. baseDir .. new_filename .. '" -a'
						log("Normal", "Rendering ".. baseDir .. new_filename)
						os.execute(command)
				end

		end

		if event.etype == "Delete" then
		-- Todo kill process

		end

		-- ignores other events.
		inlet.discardEvent(event)
	end,


}

sync{render, source=config.general.watchdir}
