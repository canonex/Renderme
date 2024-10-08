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

renderstop = {
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

				log("Normal", "filename is ".. base)


				-- Retrieve the hostname
				local machinehostname = io.popen('hostname'):read('*l')

				-- Name to check to stop process
				local machinehostnamestop = machinehostname .. ".stop"

				-- Check if the file base contains the "hostname-stop" command
				if string.match(base, machinehostnamestop) then

					-- Rename the file to remove "machinehostnamestop"
					local new_filename = string.gsub(filename, machinehostnamestop, "")
					os.rename(baseDir .. filename, baseDir .. new_filename)

					local basename = string.match(new_filename, '([^/]+)%.%w+$')

					-- Sigterm the rendering process

					-- subdivided execution to avoid Unterminated quoted string error
					-- discover process by name and pid
					local ca = "ps -ae -o 'pid' -o 'cmd'"
					-- find process containing basename
					local cb = "grep '" .. basename .. "'"
					-- avoid himself grep -v 'grep' or...
					local cc = "grep 'blender'"
					-- select the first part
					local cd = "awk '{print $1}'"
					-- SIGTERM process
					local ce = "xargs -I % kill -s 15 %"

					local kommand = ca .. " | " .. cb .. " | " .. cc .. " | " .. cd .. " | " .. ce


					-- Like os.execute but with return values
					local handlec = io.popen( kommand )
					local resultc = handlec:read("*a")
					handlec:close()

					-- Write the processing status in lprocessing.txt, in the same source folder
					os.execute('echo $(date "+%Y-%m-%d") - Rendering stopped by user on $(hostname) ' .. new_filename .. '" >> ' .. sourcePathdir .. 'lprocessing.txt')

					log("Normal", "Rendering stopped ".. baseDir .. new_filename)


				end
		end

		if event.etype == "Delete" then
		-- Todo kill process

		end

		-- ignores other events.
		inlet.discardEvent(event)
	end,


}

sync{renderstop, source=general.watchdir}
