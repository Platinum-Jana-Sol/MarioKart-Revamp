-- IMPORTANT!! NEWER VERSION WILL OVERRIDE OLDER VERSIONS
local PARAGLIDERLINEDEFSVERSION	= 4
if jglider == nil then
	rawset(_G, "jglider", {})
end

if jglider.linedefsVer == nil or jglider.linedefsVer < PARAGLIDERLINEDEFSVERSION then
-- start

local FRACUNIT 		= FRACUNIT

local IMMEDIATEGLIDE			= ML_NOKNUX 	-- no knuckles flag
local CANNOTDESTROYGLIDE		= ML_NOTAILS 	-- no tails flag

jglider.enableParagliding = function(line, playerMo, sector)
	if jglider.isMobjValidPlayer(playerMo) == false then return end

	if playerMo.willParaglide or
		playerMo.paragliding == true then return end

	--[[ -- This can come later...
	local customSprite = nil
	if line.backside ~= nil then
		local backsideText = line.backside.text

		if backsideText ~= nil and
			backsideText ~= "" then
			
			customSprite = backsideText
		end
	end
	]]

	if ((line.flags & IMMEDIATEGLIDE) == IMMEDIATEGLIDE) then
		jglider.createParaglider(playerMo)
		jglider.initParaglider(playerMo)
		playerMo.paragliding = true
	else
		jglider.spawnParagliderWithStartup(playerMo)
	end

	playerMo.allowedToLetGoOfGlider =
		not ((line.flags & CANNOTDESTROYGLIDE) == CANNOTDESTROYGLIDE)

	playerMo.ticsUntilLettingGoOfGlider =
		leveltime + (line.frontside.textureoffset / FRACUNIT)
end

jglider.removeParaglide = function(line, playerMo, sector)
	if jglider.isMobjValidPlayer(playerMo) == false then return end

	-- will not deploy
	if playerMo.willParaglide then
		playerMo.willParaglide = 0
	end

	-- if already active...
	-- act as if player touched the ground
	-- also play a different sound
	if playerMo.paragliding == true then
		jglider.createDeadGlider(playerMo)
		jglider.resetGliderStuff(playerMo)

		local cheeseSound = sfx_s224

		if line.backside ~= nil then
			local soundName = line.backside.text

			if soundName ~= nil and
				soundName ~= "" then

				cheeseSound = jglider.GetSoundOrFreeslotFromString(soundName:lower())
			end
		end

		S_StartSound(playerMo, cheeseSound)
	end
end

jglider.paragliderOptions = function(line, playerMo, sector)
	if jglider.isMobjValidPlayer(playerMo) == false then return end

	if playerMo.paragliding == false then return end

	playerMo.allowedToLetGoOfGlider =
		not ((line.flags & CANNOTDESTROYGLIDE) == CANNOTDESTROYGLIDE)

	playerMo.ticsUntilLettingGoOfGlider =
		leveltime + (line.frontside.textureoffset / FRACUNIT)

	local changeSound = sfx_s3kd2s

	if line.backside ~= nil then
		local soundName = line.backside.text

		if soundName ~= nil and
			soundName ~= "" then
				
			changeSound = jglider.GetSoundOrFreeslotFromString(soundName:lower())
		end
	end

	S_StartSound(playerMo, changeSound)
end

if jglider.linedefsVer == nil then
	-- see Jug_GliderLogic over why I do it like this.
	addHook("LinedefExecute",
	function(line, playerMo, sector)
		jglider.enableParagliding(line, playerMo, sector)
	end, "PARAGLIDENABLE")
	addHook("LinedefExecute", 
	function(line, playerMo, sector)
		jglider.removeParaglide(line, playerMo, sector)
	end, "PARAGLIDREMOVE")
	addHook("LinedefExecute",
	function(line, playerMo, sector)
		jglider.paragliderOptions(line, playerMo, sector)
	end, "PARAGLIDOPTIONS")
end

-- end
jglider.linedefsVer = PARAGLIDERLINEDEFSVERSION

else
	if jglider.CVar_ParagliderDebug ~= nil and jglider.CVar_ParagliderDebug.value == 1 then
		print("\130GLIDER WARNING:\128 An older/same paraglider LINEDEFS version ("..PARAGLIDERLINEDEFSVERSION..") is being loaded, "..
				"current is "..jglider.linedefsVer..", skipping...")
	end
end