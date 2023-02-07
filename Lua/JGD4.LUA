-- IMPORTANT!! NEWER VERSION WILL OVERRIDE OLDER VERSIONS
local PARAGLIDERHELPERSVERSION	= 4
if jglider == nil then
	rawset(_G, "jglider", {})
end

if jglider.helpersVer == nil or jglider.helpersVer < PARAGLIDERHELPERSVERSION then
-- start

local FRACUNIT 		= FRACUNIT
local ANG1			= ANG1
local ITEMTIME		= 8 * TICRATE

jglider.ParagliderZPos = 24

jglider.isMobjValidPlayer = function(mobj)
	if mobj == nil 			then return false end
	if mobj.player == nil 	then return false end
	
	return true
end

jglider.FindSoundByName = function(sfxName)
	-- if _G[sfxName] == nil then return nil end
	return _G[sfxName] -- GOD it was so simple all along
end

jglider.GetSoundOrFreeslotFromString = function(soundName)
	soundName = "sfx_"..soundName
	local sound = jglider.FindSoundByName(soundName)

	if sound == nil then
		sound = freeslot(soundName)
	end

	return sound
end

jglider.spawnParagliderWithStartup = function(playerMo, useDefaults)
	playerMo.willParaglide = 1
	S_StartSound(playerMo, sfx_ddash)

	if playerMo.paraglideMobj == nil or
	playerMo.paraglideMobj.valid == false then				
		-- transformMomentumToLook(player)
		jglider.createParaglider(playerMo)
	end

	if not useDefaults then return end
	
	playerMo.allowedToLetGoOfGlider = true
	playerMo.ticsUntilLettingGoOfGlider = 0
end

jglider.createParaglider = function(playerMo)
	local initialPos = FixedMul(jglider.ParagliderZPos * FRACUNIT, playerMo.scale) * P_MobjFlip(playerMo)

	local paraglideMobj 	= P_SpawnMobj(playerMo.x, playerMo.y, playerMo.z + initialPos,
		MT_JUG_PARAGLIDER)
	
	--[[ -- some other day...
	customSprite = customSprite or nil
	if customSprite ~= nil and 
		customSprite ~= "" then

		print(customSprite)
		customSprite = sprnames[customSprite]
		-- if zero, could be not freeslotted, we could do that. 
		customSprite =
			(customSprite == 0) and freeslot("SPR_" + customSprite) or customSprite

		paragliderMobj.skin = customSprite
	end
	]]
	
	paraglideMobj.color		= playerMo.player.skincolor
	paraglideMobj.target 	= playerMo
	paraglideMobj.angle 	= playerMo.angle

	paraglideMobj.scale		= 0
	paraglideMobj.destscale = playerMo.destscale
	paraglideMobj.scalespeed = FRACUNIT/6

	playerMo.paraglideMobj 	= paraglideMobj
end

jglider.initParaglider = function(mobj)
	local player = mobj.player

	mobj.paraglideMobj.state = S_PAGL_SPAWN1
	S_StartSound(mobj, sfx_paglgo)

	if player == nil then return end

	-- no waterskip support... for now!
	player.kartstuff[k_waterskip] = 2

	-- prevent items from popping off if item was held
	if (player.cmd.buttons & BT_ATTACK) == BT_ATTACK then
		player.holdingItemBTN = true
	end

	-- local only stuff
	if consoleplayer ~= nil and mobj == consoleplayer.mo then
		jglider.localHoldingBrakeButton = false
	end
end

jglider.resetGliderStuff = function(playerMo)
	jglider.resetGliderValues(playerMo)

	if playerMo.paraglideMobj.valid then
		P_RemoveMobj(playerMo.paraglideMobj)
		playerMo.paraglideMobj = nil
	end
end

jglider.resetGliderValues = function(playerMo)
	playerMo.paragliding 			= false
	playerMo.willParaglide 			= 0
	playerMo.glideVerticalMovement 	= 0
	playerMo.letGoGliderTimer 		= 0
	playerMo.springInfluence 		= 0
	playerMo.storedGlideMomz 		= 0
	playerMo.targetFallRt 			= 0
	playerMo.startFallVel			= 0
	-- vfx/sfx stuff
	playerMo.visonlyStoredStates	= -1
	playerMo.wooshSoundCD			= 0
	--finish buffer
	playerMo.glideFinBuffer			= 0
end

jglider.createDeadGlider = function(playerMo)
	local oldGlider = playerMo.paraglideMobj

	if oldGlider == nil or not oldGlider.valid then return end

	local deadgliderMobj = P_SpawnMobj(oldGlider.x, oldGlider.y, oldGlider.z,
		MT_JUG_DEADGLIDER)

	-- inherit various properties of the previous glider.
	deadgliderMobj.color	= playerMo.player.skincolor
	deadgliderMobj.angle 	= oldGlider.angle
	deadgliderMobj.scale	= oldGlider.scale
	deadgliderMobj.scalespeed = mapobjectscale/105
	deadgliderMobj.destscale = 0
	
	-- Inherit the player's momentum
	P_Thrust(deadgliderMobj,
		FixedAngle(P_RandomFixed() * 180) + playerMo.angle + ANGLE_90,
		(playerMo.momx + playerMo.momy) / 4)
	deadgliderMobj.momz		= P_MobjFlip(oldGlider) * (mapobjectscale * 15)
end

jglider.getTurnRateGlider = function(player)

	local fractionAng = FixedDiv(ANG1, FRACUNIT * 35)	
	local angleCorrectRate = ANG1 + (fractionAng * 5) -- 40 degrees per sec.
	-- speed 1 goes 39 degrees.
	-- speed 5 goes 35.
	-- speed 9 goes 30.
	local angleLoss	= fractionAng * player.kartweight
	angleCorrectRate = $ - angleLoss

	if player.kartstuff[k_driftboost] > 0 or
		player.kartstuff[k_sneakertimer] > 0 or
		player.kartstuff[k_invincibilitytimer] > 0 then

		angleCorrectRate = $ * 2
	end

	return angleCorrectRate
end

--mn: lerp function for new functionality, taken from my other mods
jglider.lerp = function(num, denum, minimum, maximum)
	local p = FixedDiv(num, denum)
	local a = FixedMul((maximum - minimum), p)
	local v = minimum + a
	return v
end

jglider.createRocketSneakers = function(playerMo)
	K_PlayBoostTaunt(playerMo)
	S_StartSound(playerMo, sfx_s3k3a)

	local player = playerMo.player

	player.kartstuff[k_rocketsneakertimer] = ITEMTIME * 3
	player.kartstuff[k_itemamount] = $ - 1
	
	-- We have to create the rocket sneakers ourselves.
	local prev = playerMo
	for i = 0,1 do
		local rocketSneakerMo = P_SpawnMobj(playerMo.x, playerMo.y, playerMo.z, MT_ROCKETSNEAKER)
		K_MatchGenericExtraFlags(rocketSneakerMo, playerMo)
		rocketSneakerMo.flags		= $ + MF_NOCLIPTHING
		rocketSneakerMo.angle 		= playerMo.angle
		rocketSneakerMo.threshold 	= 10 
		rocketSneakerMo.movecount 	= i % 2
		rocketSneakerMo.movedir		= i + 1
		rocketSneakerMo.lastlook 	= i + 1
		rocketSneakerMo.target 		= playerMo
		rocketSneakerMo.hprev 		= prev
		prev.hnext 					= rocketSneakerMo

		prev 						= rocketSneakerMo
	end
end

-- end
jglider.helpersVer = PARAGLIDERHELPERSVERSION

else
	if jglider.CVar_ParagliderDebug ~= nil and jglider.CVar_ParagliderDebug.value == 1 then
		print("\130GLIDER WARNING:\128 An older/same paraglider HELPERS version ("..PARAGLIDERHELPERSVERSION..") is being loaded, "..
				"current is "..jglider.helpersVer..", skipping...")
	end
end