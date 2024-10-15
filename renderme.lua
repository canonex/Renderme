-- License: GPLv3 or any later version
--
-- Authors: Lsyncd devs and Riccardo Gagliarducci
-- From the idea in: https://lsyncd.github.io/lsyncd/manual/examples/auto-image-magic/
--
-- require "config"


package.path = '*.lua;' .. package.path
require "config"
log("Normal", "Watching  " .. general.watchdir)


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

				log("Normal", "filename ".. base)

				-- Retrieve the hostname
				local machinehostname = io.popen('hostname'):read('*l')

				-- Name to check to start process
				local machinehostnamestart = machinehostname .. ".start"

				-- Check if the file base contains the "hostname-start" command
				if string.match(base, machinehostnamestart) then

					-- Rename the file to remove "machinehostname"
					local new_filename = string.gsub(filename, machinehostnamestart, "")
					os.rename(baseDir .. filename, baseDir .. new_filename)

					local today = os.date('%Y-%m-%d_%H-%M-%S')

					local logContent = today .. ' - Queued or processed by ' .. machinehostname .. ' - file ' .. new_filename

					-- Write the processing status in lprocessing.txt, in the same source folder
					os.execute('echo "' .. logContent .. '" >> "' .. sourcePathdir .. 'lprocessing.txt"')


					-- Run the Blender command with the new file name
					local command = 'blender -b "' .. baseDir .. new_filename .. '" -a'
					os.execute(command)

					log("Normal", "Rendering ".. baseDir .. new_filename)
				end

		end

		if event.etype == "Delete" then
		-- Todo kill process

		end

		-- ignores other events.
		inlet.discardEvent(event)
	end,


}

sync{render, source=general.watchdir}
