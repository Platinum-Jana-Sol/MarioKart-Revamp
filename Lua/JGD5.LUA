-- IMPORTANT!! NEWER VERSION WILL OVERRIDE OLDER VERSIONS
local PARAGLIDERCONFIGVERSION	= 6
if jglider == nil then
	rawset(_G, "jglider", {})
end

if jglider.configVer == nil or jglider.configVer < PARAGLIDERCONFIGVERSION then

local isLoaded = false
local fileName = "paraglider.cfg"

jglider.loadConfigFile = function()
	if leveltime < 0 		then return end
	if not consoleplayer 	then return end
	if isLoaded 			then return end

	local configFile = io.open(fileName, "r")

	if configFile == nil then -- we have no file
		-- we are creating a file to prevent halting looking for it
		-- then we are letting the player know
		configFile = io.open(fileName, "w")

		-- somehow this messes up when luafiles or the file is read-only.
		-- if this happens, just consider it loaded and stop immediately.
		if configFile == nil then 
			isLoaded = true
			-- print("paraglider.cfg could not be created. This could be because the luafiles folder or file is set to read only.")
			return
		end

		print("You have entered a server with levels using paragliders!")
		print("Use paraglider_invert on/off to keep the vertical axis inverted/normal. It's inverted by default.")
		print("We have created a " + fileName + " file just to store your settings permanently.")
		print("You will only see this once. Have fun!")

		configFile:write("// Invert your controls with paraglider_invert on/off (\"on\" is default)")
		configFile:close()
	else -- we have a file
		print("We are loading your Paraglider config!")

		-- read the config, load the lines
		local line = configFile:read()

		while line ~= nil do
			COM_BufInsertText(consoleplayer, line)
			line = configFile:read()
		end

		configFile:close()
	end

	isLoaded = true
end

addHook("ThinkFrame", function()
	if PARAGLIDERCONFIGVERSION < jglider.configVer then
		return
	end

	jglider.loadConfigFile()
end)
addHook("NetVars", function()
	if PARAGLIDERCONFIGVERSION < jglider.configVer then
		return
	end
	if replayplayback then return end

	-- reload config if player disconnected
	isLoaded = false
end)

jglider.configVer = PARAGLIDERCONFIGVERSION

else
	if jglider.CVar_ParagliderDebug ~= nil and jglider.CVar_ParagliderDebug.value == 1 then
		print("\130GLIDER WARNING:\128 An older/same paraglider CONFIG version ("..PARAGLIDERCONFIGVERSION..") is being loaded, "..
				"current is "..jglider.configVer..", skipping...")
	end
end