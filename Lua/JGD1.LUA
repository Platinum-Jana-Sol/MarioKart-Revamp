-- IMPORTANT!! NEWER VERSION WILL OVERRIDE OLDER VERSIONS
-- ENHANCED PITCH CONTROL BY MINENICE
-- mine: any changes I make will have comments prefixed with "mn"
--mn: incremented logic to v4, if this already exists inc again before merging
local PARAGLIDERLOGICVERSION	= 5
if jglider == nil then
	rawset(_G, "jglider", {})
end

-- avoid redefiniton on updates
jglider.CVar_ParagliderDebug = $ or nil

if jglider.logicVer == nil or jglider.logicVer < PARAGLIDERLOGICVERSION then

-- OPTIMIZATIONS START
local FRACUNIT 		= FRACUNIT
local TICRATE 		= TICRATE

local ANG1			= ANG1 

local BT_ACCELERATE = BT_ACCELERATE
local BT_BRAKE		= BT_BRAKE
local BT_ATTACK		= BT_ATTACK
local BT_CUSTOM3	= BT_CUSTOM3

local KITEM_SNEAKER			= KITEM_SNEAKER
local KITEM_ROCKETSNEAKER	= KITEM_ROCKETSNEAKER
local KITEM_INVINCIBILITY 	= KITEM_INVINCIBILITY

local WINDSECTOR			= 512
local FANSECTOR				= 20480
local YELLOWSPRINGSECTOR 	= 256
local REDSPRINGSECTOR 		= 768

local STARTTIME 				= 6 * TICRATE + (3 * TICRATE / 4);

--determines how much momz to store
local PG_FALLRATE 				= 4*FRACUNIT/8
local PG_GROWFALLRT				= 2*FRACUNIT
--base falling speed
local PG_MAXFALL				= 3*FRACUNIT
local PG_FALLSPEEDCAPRATE		= 50*FRACUNIT/100

--mn: transition from normal falling to gliding
local PG_UNFALL_KF				= FRACUNIT/2

--mn: maximum "stored" velocity from pitching up/down
-- essentially how high up the player can go again after pitching down
-- the new system will emulate mario kart 7 / tour's systems the most, since 
-- they have the most control
-- to bring closer to mario kart 8, tighten up the margins
local PG_PLAYERMAXSTOREDFALL	= 44*FRACUNIT
-- multiply the "to store" amount by this value, also used in easing player momz
local PG_PLAYERMAXFALLDEGRADE	= 5*FRACUNIT/100
-- terminal falling velocity, replacement for the old MAXFALL since we can go
-- even faster, also used to check when to degrade the stored velocity
local PG_PLAYERTERMINALFALL		= -22*FRACUNIT
-- give stored for some states, up to a limit
-- shroom boost
local PG_VELFORBOOST 		= 4*FRACUNIT
local PG_VELFORBOOST_MAX 	= PG_PLAYERMAXSTOREDFALL/4 + PG_PLAYERMAXSTOREDFALL/10

local PG_VELFORMT	 		= 3*FRACUNIT/2
local PG_VELFORMT_MAX	 	= PG_PLAYERMAXSTOREDFALL/4

local PG_VELFORSTAR		 	= 69*FRACUNIT/10
local PG_VELFORSTAR_MAX	 	= PG_PLAYERMAXSTOREDFALL/5

--spring panels just give some charge directly
local PG_VELFORSPRING_MAX	= 2*PG_PLAYERMAXSTOREDFALL/3

--mega multiplies how far you can pitch up/down
local PG_VELFORMEGA	 	= 2*FRACUNIT

--mn: switch to analogue controls for glide, instead of using timers
-- the following may go unused
local PG_UPPERTICBOUNDS			= FixedDiv(TICRATE, 2*FRACUNIT)
local PG_LOWERTICBOUNDS 		= -PG_UPPERTICBOUNDS
--analogue pitch caps, for lerp sakes
local PG_CONTROLPITCHMAX		= FRACUNIT
local PG_CONTROLPITCHMIN		= -PG_CONTROLPITCHMAX
--mn: for digital controls (eg. kb), use smooth easing (maybe make ease rate a 
--cvar in the future)
local PG_DIGITALPITCHEASE_RT	= 40*FRACUNIT/100
--mn: digital base "wanted" pitch (essentially 0, but exists for completeness)
local PG_DIGITALPITCH_WANT		= 0

local PG_STARTWINGTIMER			= TICRATE/4
local PG_STARTWINGVEL			= 48*FRACUNIT
local PG_STARTWINGSTOREDVEL		= 5*FRACUNIT

local PG_SPEEDREDUCTIVEDIVE		= 80*FRACUNIT/100
local PG_SPEEDREDUCTIVESTALL	= 69*FRACUNIT/100
local PG_TOPSTORESPEED			= 169*FRACUNIT/100
local PG_STORESPEEDTHRESHOLD	= 4*PG_PLAYERMAXSTOREDFALL/5

local PG_MAXSPEED				= 120 * FRACUNIT
local PG_MINSPEED				= 20 * FRACUNIT

local SPRING_MOMZTHRESHOLD		= -FRACUNIT * 2

jglider.LETGOGLIDERTIMER		= TICRATE
local SPRINGINFLUENCETIMER		= TICRATE / 4 	-- 8

local PG_COYOTETIMETICS 		= 5

-- only exists for anim purposes
local PG_MINMOMENTUMFORGHOSTS	= PG_STORESPEEDTHRESHOLD/2
local PG_WOOSHCOOLDOWN			= TICRATE
freeslot("sfx_glidcs", "sfx_glidup",
	"sfx_glidc1",
	"sfx_glidc2",
	"sfx_glidc3",
	"sfx_glidc4",
	"sfx_glidc5",
	"sfx_glidc6",
	"sfx_glidc7",
	"sfx_glidc8",
	
	"sfx_glids1",
	"sfx_glids2",
	"sfx_glids3"
)

local wingTipOffX = 38
local wingTipOffY = 28
local wingTipOffZ = 24
local wingTipTiltMult = 16
-- OPTIMIZATIONS END

-- local only variable
jglider.localHoldingBrakeButton = false

-- CVARs and CMDs START
if jglider.CVar_ParagliderDebug == nil then
	jglider.CVar_ParagliderDebug = CV_RegisterVar(
		{
			name = "paraglider_debug",
			defaultvalue = "Off",
			flags = CV_CHEAT,
			PossibleValue = CV_YesNo
		}
	)
end

if jglider.CVar_ParagliderDebugDeployAnywhere == nil then
	jglider.CVar_ParagliderDebugDeployAnywhere = CV_RegisterVar(
		{
			name = "paraglider_debug_deployanywhere",
			defaultvalue = "Off",
			flags = CV_CHEAT|CV_NETVAR,
			PossibleValue = CV_YesNo
		}
	)
end

if jglider.CVar_ParagliderDebugFlapping == nil then
	-- if this breaks in a future update i don't care, thank you
	jglider.CVar_ParagliderDebugFlapping = CV_RegisterVar(
		{
			name = "paraglider_debug_faytwantedthis",
			defaultvalue = "Off",
			flags = CV_CHEAT|CV_NETVAR,
			PossibleValue = CV_YesNo
		}
	)
end

local SINGLEPLAYERINVERTED 	= "Your vertical paraglider controls have been inverted."
local SINGLEPLAYERNORMAL	= "Your vertical paraglider controls are now normal."
local INVALIDPARAM			= "This is not a valid parameter. Try 'yes', 'no', 'on' or 'off' instead."

local LOCALMPPLAYERINVERTED	= "The vertical paraglider controls for %s have been inverted."
local LOCALMPPLAYERNORMAL	= "The vertical paraglider controls for %s are now normal."
local LOCALMPPLAYERNOTFOUND	= "We couldn't find this splitscreen player. Check if your parameters are correct."
local LOCALMPPLAYEROUTOFRANGE	= "This splitscreen player is out of range. Check if your parameters are correct."


jglider.invertGliderControlsPlayer = function(player, arg1, caller)
	if caller == nil then
		caller = player
	end

	if arg1 == nil then
		-- toggle behaviour
		if player.invertParaglider == nil then
			player.invertParaglider = -1
			CONS_Printf(caller, SINGLEPLAYERINVERTED)
		else
			player.invertParaglider = $ * -1

			-- ternary operators don't work with this, bear with me here.
			if player.invertParaglider == 1 then
				CONS_Printf(caller, SINGLEPLAYERNORMAL)
			else 
				CONS_Printf(caller, SINGLEPLAYERINVERTED)
			end
		end
	elseif arg1 ~= nil
		-- set behaviour
		if (arg1 == 1 or
			arg1:lower() == "on" or
			arg1:lower() == "yes") then

			player.invertParaglider = -1
			CONS_Printf(caller, SINGLEPLAYERINVERTED)

		elseif (arg1 == 0 or
			arg1:lower() == "off" or
			arg1:lower() == "no") then

			player.invertParaglider = 1
			CONS_Printf(caller, SINGLEPLAYERNORMAL)
		else
			CONS_Printf(caller, INVALIDPARAM)
		end
	end
end

jglider.invertGliderControlsCMD = function(player, arg1, arg2)
	if splitscreen and not netgame then -- splitscreen, not netgame
		-- arg1 is the player to choose, arg2 is the preferred setting.
		-- arg1 should be player 1, 2, 3 or 4
		local localPlayer = tonumber(arg1)
		local splitPlayer = nil

		if localPlayer == nil then
			CONS_Printf(player, LOCALMPPLAYERNOTFOUND)
			return
		else
			local index = localPlayer - 1
			if index < 0 or index >= #displayplayers then
				CONS_Printf(player, LOCALMPPLAYEROUTOFRANGE)
				return
			end

			splitPlayer = displayplayers[index]

			if splitPlayer 			== nil or
				splitPlayer.valid 	== false then

				CONS_Printf(player, LOCALMPPLAYERNOTFOUND)
				return
			end
		end

		jglider.invertGliderControlsPlayer(splitPlayer, arg2)
	else -- singleplayer
		-- arg1 is the preferred setting.
		jglider.invertGliderControlsPlayer(player, arg1)
	end
end

COM_AddCommand("paraglider_invert", 		jglider.invertGliderControlsCMD)
-- CVARs and CMDs END

--This is the function used for handling the paraglider's unique movement mechanics.
jglider.handleParaglide = function(playerMo)
	local player = playerMo.player
	local pks = player.kartstuff
	
	--added maximum storable velocity
	local maxStore = FixedMul(PG_MAXFALL, PG_PLAYERMAXFALLDEGRADE)
	local addStore = 0
	local cappedStore = 0
	if pks[k_sneakertimer] then
		addStore = $ + PG_VELFORBOOST
		cappedStore = max($, PG_VELFORBOOST_MAX)
	end
	if pks[k_driftboost] then
		addStore = $ + PG_VELFORMT
		cappedStore = max($, PG_VELFORMT_MAX)
	end
	if pks[k_invincibilitytimer] then
		addStore = $ + PG_VELFORSTAR
		cappedStore = max($, PG_VELFORSTAR_MAX)
	end
	
	-- STEP 1: HANDLING HORIZONTAL MOVEMENT

	-- handling sideways movement	
	local playerAngle = playerMo.angle

	-- naturally correct this momentum angle to the player's
	local thrustAngle = R_PointToAngle2(0, 0, playerMo.momx, playerMo.momy)
	
	-- turn rate calc
	local angleCorrectRate = jglider.getTurnRateGlider(player)

	local angleMovementResult = angleCorrectRate
	local angleSidewaysMovementDiff = thrustAngle - playerAngle
	local angleAbsSidewaysMovement = abs(angleSidewaysMovementDiff)

	if angleAbsSidewaysMovement < angleCorrectRate then
		angleMovementResult = angleAbsSidewaysMovement
		-- print("angle less than one, correcting.")
	end

	if angleSidewaysMovementDiff > 0 then
		thrustAngle = $ - angleMovementResult
	elseif angleSidewaysMovementDiff < 0 then
		thrustAngle = $ + angleMovementResult
	end

	local thrustForce = R_PointToDist2(0, 0, playerMo.momx, playerMo.momy)

	-- bounds checking
	thrustForce = min(thrustForce, PG_MAXSPEED)

	-- let the player control the paraglider horizontally
	playerMo.momx = FixedMul(thrustForce, cos(thrustAngle))
	playerMo.momy = FixedMul(thrustForce, sin(thrustAngle))

	-- STEP 2: AIRBORN ACCELERATION
	-- don't allow this at the start of levels to allow epic synchonized starts
	if leveltime > STARTTIME then
		--[[
			This is accelcode from hardcode.
			This allows paragliding players to benefit from miniturbos, sneakers
			and what not, when they're paragliding.
		]]

		local accelMax		= 4000
		local ORIG_FRICTION	= 62914

		local accelValue 	= K_GetKartAccel(player)
		local speedValue	= K_GetKartSpeed(player, false)
		if playerMo.glideVerticalMovement > 0 and playerMo.storedGlideMomz >= PG_STORESPEEDTHRESHOLD then
			local increase = jglider.lerp(playerMo.storedGlideMomz, PG_PLAYERMAXSTOREDFALL + maxStore, FRACUNIT, PG_TOPSTORESPEED)
			speedValue = FixedMul(FixedMul($, player.kartstuff[k_boostpower] + player.kartstuff[k_speedboost]), increase)
		else
			local reductive = jglider.lerp(abs(playerMo.glideVerticalMovement),
				FRACUNIT, FRACUNIT,
				FixedMul(((playerMo.glideVerticalMovement > 0) and PG_SPEEDREDUCTIVESTALL or PG_SPEEDREDUCTIVEDIVE),
				player.kartstuff[k_boostpower] + player.kartstuff[k_speedboost]))
			--print(reductive)
			speedValue = FixedMul(FixedMul($, player.kartstuff[k_boostpower] + player.kartstuff[k_speedboost]), reductive)
		end
		
		local oldSpeed		= R_PointToDist2(0, 0, player.rmomx, player.rmomy)

		local newSpeed = FixedDiv(FixedDiv(FixedMul(oldSpeed, accelMax - accelValue) +
			FixedMul(speedValue, accelValue), accelMax), ORIG_FRICTION)

		local finalSpeed = newSpeed - oldSpeed
		
		-- finalSpeed = $ / 8

		if finalSpeed < 0 then
			finalSpeed = 0
		end

		playerMo.momx = $ + P_ReturnThrustX(thrustAngle, finalSpeed)
		playerMo.momy = $ + P_ReturnThrustY(thrustAngle, finalSpeed)

		playerMo.momx = FixedMul(playerMo.momx, playerMo.friction)
		playerMo.momy = FixedMul(playerMo.momy, playerMo.friction)
	
	end


	-- STEP 3.1 - GETTING SPECIALS OF INTEREST
	local playerFoF		= P_ThingOnSpecial3DFloor(playerMo)
	local playerSpecial = playerMo.subsector.sector.special
	--print(playerSpecial)

	-- String Panels
	local isPlayerTouchingSpringPanel =
		-- ground sectors
		(P_IsObjectOnGround(playerMo) == true and
		(playerSpecial 	& YELLOWSPRINGSECTOR == YELLOWSPRINGSECTOR or
		playerSpecial 	& REDSPRINGSECTOR == REDSPRINGSECTOR))
		or
		-- FoFs
		(playerFoF ~= nil and
		(playerFoF.special & YELLOWSPRINGSECTOR == YELLOWSPRINGSECTOR or
		playerFoF.special & REDSPRINGSECTOR == REDSPRINGSECTOR))

	-- reset spring influence if we touch a spring
	if isPlayerTouchingSpringPanel then
		playerMo.springInfluence = 0
	end

	-- Fan FoF
	local playerinFanFoF = playerFoF

	if playerinFanFoF ~= nil then
		playerinFanFoF = ($.special & FANSECTOR) == FANSECTOR
		-- print("touching fan? " + isPlayerInsideFanFoF)
	end
	
	local playerinFanSector = (playerSpecial & FANSECTOR == FANSECTOR)
	local playerinWindSector = (playerSpecial & WINDSECTOR == WINDSECTOR)

	-- Handling both fan and wind sectors
	local isPlayerInsideFanOrWindSector =
		playerinFanSector or
		playerinWindSector
	
	-- STEP 3.2 - HANDLING VERTICAL MOMENTUM
	-- The player's vertical momentum inside fan or springs is untouched.
	--mn: TODO: actually touch vertical momentum in horizontal wind
	-- Springs are handled below.
	if not (playerinFanFoF or playerinFanSector) and 
			player.kartstuff[k_pogospring] == 0 then
		
		--mn: we rewriting this completely
		if playerMo.glideVerticalMovement <= 0 then
			--pitch down / neutral
			local momzToStore = FixedMul(PG_FALLRATE, abs(playerMo.glideVerticalMovement))
			local terminalFall = PG_PLAYERTERMINALFALL
			if pks[k_growshrinktimer] > 0 then
				momzToStore = FixedMul($, PG_GROWFALLRT)
				terminalFall = FixedMul($, PG_GROWFALLRT)
			end
			momzToStore = $ + min(addStore, max(cappedStore - 2*playerMo.storedGlideMomz/3, 0))
			playerMo.storedGlideMomz = min($ + momzToStore + (gravity/4), PG_PLAYERMAXSTOREDFALL + maxStore)
			--cap falling speed
			playerMo.targetFallRt = jglider.lerp(abs(playerMo.glideVerticalMovement), FRACUNIT, max(playerMo.momz - PG_MAXFALL, PG_MAXFALL), terminalFall)
		else
			--pitch up
			playerMo.targetFallRt = playerMo.storedGlideMomz
			local momzToStore = min(addStore, max(cappedStore - playerMo.storedGlideMomz, 0))
			if pks[k_growshrinktimer] > 0 then
				playerMo.targetFallRt = FixedMul($, PG_GROWFALLRT)
			end
			playerMo.storedGlideMomz = max(min($ - gravity, PG_PLAYERMAXSTOREDFALL + maxStore), PG_MAXFALL + PG_MAXFALL/2 + maxStore) + momzToStore
		end
		--mobjscale and flip target fall rate
		playerMo.targetFallRt = FixedMul($, mapobjectscale) * P_MobjFlip(playerMo)
		--ease from starting vel to gliding vel
		if playerMo.startFallVel > 0 then
			playerMo.startFallVel = max($ - PG_UNFALL_KF, 0)
		end
		playerMo.momz = jglider.lerp(PG_PLAYERMAXFALLDEGRADE, FRACUNIT, $, playerMo.targetFallRt + playerMo.startFallVel)
	else
		-- Handle cases where the player is in spring state.
		if player.kartstuff[k_pogospring] > 0 then
			playerMo.springInfluence = $ + 1

			-- Remove pogo spring status when going down.
			if playerMo.momz < SPRING_MOMZTHRESHOLD and
				playerMo.springInfluence >= SPRINGINFLUENCETIMER then
				
				playerMo.storedGlideMomz = max($, PG_VELFORSPRING_MAX)
				
				S_StartSound(playerMo, sfx_paglgo)
				player.kartstuff[k_pogospring] = 0
				playerMo.springInfluence = 0
			end
		else
			--give players stored momz for fan sectors
			local momzToStore = FixedMul(PG_FALLRATE, abs(playerMo.glideVerticalMovement)) + FRACUNIT
			if pks[k_growshrinktimer] > 0 then
				momzToStore = FixedMul($, PG_GROWFALLRT)
			end
			--print("in fan, storing " + momzToStore)
			playerMo.storedGlideMomz = max(min($ + momzToStore, PG_PLAYERMAXSTOREDFALL + maxStore), maxStore)
		end
	end
end

jglider.handleMomentumGhostsAndSFX = function(playerMo)
	-- print(playerMo.visonlyStoredStates)
	if playerMo.storedGlideMomz < PG_MINMOMENTUMFORGHOSTS then
		-- not generating ghosts at all
		playerMo.chargeSoundStart = 0
		playerMo.visonlyStoredStates = -1
		
		if playerMo.storedGlideMomz < 8*FRACUNIT and playerMo.glideVerticalMovement > 0 then
			if leveltime % 8 == 0 then
				S_StartSoundAtVolume(playerMo, sfx_glids1 + P_RandomKey(2), 3*255/4, playerMo.player)
			end
		end
		return
	end

	-- there's 3 intervals:
	-- the slowest one, which makes a ghost spawn every second (half of max stored mom.)
	-- the normal one, which makes a ghost spawn every half a second (3/4 of max stored mom.)
	-- the fastest one, which makes a ghost spawn every quarter of a second (max stored mom.)
	--local interval = 2
	local soundInterval = 8
	local transparency = TR_TRANS70
	local duration = TICRATE/7
	local chargeStatus = 0
	local chargeSound = 0

	-- this exists for the sake of creating sounds to indicate different charges
	-- also it's like this because when init like "$ or -1", and $ is 0, it will choose -1,
	-- which isn't what we want
	if playerMo.visonlyStoredStates == nil then
		playerMo.visonlyStoredStates = -1
	end	
	-- CD stuff for the WOOSH sound
	playerMo.wooshSoundCD = $ or 0
	playerMo.chargeSoundStart = $ or 0
	
	transparency = jglider.lerp(playerMo.storedGlideMomz - PG_MINMOMENTUMFORGHOSTS, PG_STORESPEEDTHRESHOLD, 7, 0) << FF_TRANSSHIFT
	chargeSound = jglider.lerp(playerMo.storedGlideMomz - PG_MINMOMENTUMFORGHOSTS, PG_STORESPEEDTHRESHOLD, 0, 8)
	
	if playerMo.storedGlideMomz >= PG_STORESPEEDTHRESHOLD then -- 1.00
		duration = TICRATE/2
		chargeStatus = 2
	elseif playerMo.storedGlideMomz >= (PG_MINMOMENTUMFORGHOSTS + PG_MINMOMENTUMFORGHOSTS/2) -- 0.75
		duration = TICRATE/3
		chargeStatus = 1
	else
		chargeStatus = 0
	end

	-- play a sound when these change
	if playerMo.visonlyStoredStates ~= chargeStatus then
		-- play a sound when it's less than before, big boy gliding up
		-- and wait until until CD expires
		if playerMo.wooshSoundCD == 0 	and
			chargeStatus >= 0 			and
			chargeStatus < playerMo.visonlyStoredStates then
				S_StartSound(playerMo, sfx_glidup, playerMo.player)
				playerMo.wooshSoundCD = PG_WOOSHCOOLDOWN
		end
		playerMo.visonlyStoredStates = chargeStatus
	elseif playerMo.wooshSoundCD > 0 then
		playerMo.wooshSoundCD = $ - 1
	end

	--if leveltime % interval ~= 0 then return end

	-- accomanying sound
	if leveltime % soundInterval == 0 and playerMo.startFallVel <= 0 then
		if playerMo.chargeSoundStart == 0 then
			S_StartSound(playerMo, sfx_glidcs, playerMo.player)
			playerMo.chargeSoundStart = 1
		else
			S_StartSound(playerMo, sfx_glidc1 + chargeSound, playerMo.player)
		end
	end

	--mn: trail spawning here
	local gliderMo = playerMo.paraglideMobj
	if not gliderMo.valid then return end -- stop processing from here if the glider's dead.
	local a = gliderMo.angle
	local turnDifference = max(min(gliderMo.angle - playerMo.angle, 90*ANG1), -90*ANG1)
	
	local offsX = FixedMul(-wingTipOffY * gliderMo.scale, cos(a)) + FixedMul(wingTipOffX * FixedMul(gliderMo.scale, cos(turnDifference)), -sin(a))
	local offsY = FixedMul(-wingTipOffY * gliderMo.scale, sin(a)) + FixedMul(wingTipOffX * gliderMo.scale, cos(a))
	local offsZ = (wingTipOffZ * gliderMo.scale) + (wingTipTiltMult * FixedMul(gliderMo.scale, sin(turnDifference)))
	
	local ghost = P_SpawnMobj(gliderMo.x + offsX, gliderMo.y + offsY, gliderMo.z + offsZ * P_MobjFlip(gliderMo), MT_JUG_GLIDERTRAIL)
	ghost.scale = gliderMo.scale
	ghost.health 		= duration
	ghost.extravalue1 	= duration
	ghost.color			= gliderMo.color
	ghost.frame = $|transparency
	ghost.momx = 6 * (playerMo.momx / 7) 
	ghost.momy = 6 * (playerMo.momy / 7)
	ghost.momz = 6 * (playerMo.momz / 7)
	-- ghost.anim_duration = duration
	
	offsX = FixedMul(-wingTipOffY * gliderMo.scale, cos(a)) + FixedMul(-wingTipOffX * FixedMul(gliderMo.scale, cos(turnDifference)), -sin(a))
	offsY = FixedMul(-wingTipOffY * gliderMo.scale, sin(a)) + FixedMul(-wingTipOffX * gliderMo.scale, cos(a))
	offsZ = (wingTipOffZ * gliderMo.scale) + (wingTipTiltMult * FixedMul(gliderMo.scale, sin(-turnDifference)))
	
	ghost = P_SpawnMobj(gliderMo.x + offsX, gliderMo.y + offsY, gliderMo.z + offsZ * P_MobjFlip(gliderMo), MT_JUG_GLIDERTRAIL)
	ghost.scale = gliderMo.scale
	ghost.health 		= duration
	ghost.extravalue1 	= duration
	ghost.color			= gliderMo.color
	ghost.frame = $|transparency
	ghost.momx = 6 * (playerMo.momx / 7) 
	ghost.momy = 6 * (playerMo.momy / 7)
	ghost.momz = 6 * (playerMo.momz / 7)
	-- ghost.anim_duration = duration
	
	offsX = nil
	offsY = nil
	offsZ = nil
end

-- Handles miscelaneous logic outside of the paraglider itself,
-- such as when it'll deploy, visuals and input.
jglider.glidingLogic = function(playerMo)
	local player = playerMo.player
	local playerButtons = player.cmd.buttons
	local pks = player.kartstuff

	-- Exclusively just for debug and playing around
	-- without having mappers put paraglider triggers
	-- everywhere - allows for quick testing.
	if jglider.CVar_ParagliderDebugDeployAnywhere.value and
		(playerButtons & BT_CUSTOM3) == BT_CUSTOM3 		and
		not P_IsObjectOnGround(playerMo) 				and
		(playerMo.willParaglide == nil or playerMo.willParaglide == 0) and
		(jglider.CVar_ParagliderDebugFlapping.value or not playerMo.paragliding) then

		jglider.spawnParagliderWithStartup(playerMo, true)
	end

	-- Throw sparkles if the player will paraglide.
	-- Finally deploy the paraglider when going down.
	if playerMo.willParaglide then
		if leveltime % 2 then K_SpawnSparkleTrail(playerMo) end
		
		if not (P_IsObjectOnGround(playerMo)) then
			playerMo.willParaglide = $+1
		end
		
		if playerMo.willParaglide == PG_STARTWINGTIMER then
			jglider.resetGliderValues(playerMo)
			playerMo.paragliding = true

			jglider.initParaglider(playerMo)
			
			playerMo.storedGlideMomz 		= abs(playerMo.momz) + FixedMul(PG_STARTWINGSTOREDVEL, mapobjectscale)
			playerMo.targetFallRt 			= abs(playerMo.momz) + FixedMul(PG_STARTWINGVEL, mapobjectscale)
			playerMo.startFallVel			= max(playerMo.momz, 0)
			playerMo.glideFinBuffer			= 0
		end
	end
	
	if not playerMo.paragliding 				then return end
	-- print(playerMo.paragliding == true)

	-- Handling vertical input.
	player.invertParaglider			= $ or -1

	if leveltime < STARTTIME+10 then
		-- lol taken from hardcode as usual
		-- handling the subtle grow effect that is less subtle in midair
		-- on start boosts
		playerMo.scalespeed = mapobjectscale/12;
		P_SetScale(playerMo, mapobjectscale + (pks[k_boostcharge] * 262)) -- MAGIC NUMBERS LOL
		if CV_FindVar("kartdebugshrink").value and !modeattacking and not player.bot then
			P_SetScale(playerMo, 6 * playerMo.scale / 8)
		end
	else
		-- Gets pressing up/down input (for moving the glide up and down)
		-- Better than using the BT_ constants for it.
		local vertDir = (pks[k_throwdir] * P_MobjFlip(playerMo)) * player.invertParaglider
		local targetVMov = PG_CONTROLPITCHMAX * vertDir
		-- mn: psuedo-analogue easing system
		playerMo.glideVerticalMovement = jglider.lerp(PG_DIGITALPITCHEASE_RT, FRACUNIT, $, targetVMov)
	end

	-- Paraglide logic here.
	jglider.handleParaglide(playerMo)

	-- Handle ghost spawning here.
	jglider.handleMomentumGhostsAndSFX(playerMo)

	-- Press item while holding a sneaker to enable the sneaker in mid-air
	-- Holding the button will not use multiple sneakers.
	-- could be extended easily to other items too...
	player.holdingItemBTN = $ or false
	if (playerButtons & BT_ATTACK) == BT_ATTACK and
		player.holdingItemBTN == false then
		
		-- Because you normally cannot use speed items in the air, the
		-- whole behaviour has to be recreated from hardcode to Lua.

		-- Rocket Sneaker behaviour when already deployed.
		if pks[k_rocketsneakertimer] > 1 then
			K_DoSneaker(player, 2) -- taunt
			K_PlayBoostTaunt(playerMo)
			pks[k_rocketsneakertimer] = $ - (2 * TICRATE)
			
			if pks[k_rocketsneakertimer] < 1 then
				pks[k_rocketsneakertimer] = 1
			end
		--Rocket Sneaker behaviour when not deployed.
		elseif pks[k_itemtype] == KITEM_ROCKETSNEAKER then
			jglider.createRocketSneakers(playerMo)
		-- Sneaker behaviour
		elseif pks[k_itemtype] == KITEM_SNEAKER then
			K_DoSneaker(player, 1) -- taunt
			K_PlayBoostTaunt(playerMo)
			pks[k_itemamount] = $ - 1
		end

		-- Make item button holding persist between deaths.
		if player.holdingItemBTN == false then
			player.holdingItemBTN = true
		end
	elseif (playerButtons & BT_ATTACK) ~= BT_ATTACK and
		player.holdingItemBTN == true then -- Let go.
		player.holdingItemBTN = false
	end

	-- Acro interop: overcharge for a sec to destroy your glider.
	-- Hold brake for a sec to let go of the glider
	if leveltime >= playerMo.ticsUntilLettingGoOfGlider and
		playerMo.allowedToLetGoOfGlider == true then

		-- Acrobatic conditionals
		local accountForAcroTricking 	= player.trickactive ~= nil and player.trickactive == true
		local isTrickButtonBrake		= player.trick_button == BT_BRAKE
		local isPlayerOverchargingTrick = player.trickcharge ~= nil and player.trickcharge == 400
	
		if (playerButtons & BT_BRAKE) == BT_BRAKE then
			if accountForAcroTricking == false or
				isTrickButtonBrake == false or
				(isPlayerOverchargingTrick and
				 isPlayerOverchargingTrick) then
	
				-- Increase timer when holding the timer button.
				playerMo.letGoGliderTimer = (playerMo.letGoGliderTimer or 0) + 1
	
				if playerMo.letGoGliderTimer >= jglider.LETGOGLIDERTIMER then
					jglider.createDeadGlider(playerMo)
					jglider.resetGliderStuff(playerMo)
					S_StartSound(playerMo, sfx_paglno)
				end
	
			end
		else
			-- Decrease the timer if not actively holding the button.
			playerMo.letGoGliderTimer = playerMo.letGoGliderTimer or 0
			if playerMo.letGoGliderTimer > 0 then
				playerMo.letGoGliderTimer = (playerMo.letGoGliderTimer or 0) - 1
			end
		end
	else -- Let player know they can't let go
		 -- Sound doesn't get synced, so it's a local variable
		if (playerButtons & BT_BRAKE) == BT_BRAKE then
			if not jglider.localHoldingBrakeButton then
				S_StartSound(playerMo, sfx_s26d, player)
			end
			jglider.localHoldingBrakeButton = true
		else
			jglider.localHoldingBrakeButton = false
		end
		
	end

	-- Is the player gliding but got hurt or fell down? Let's check it.
	if (playerMo.paragliding or playerMo.willParaglide) then
		if
			(
			P_InQuicksand(playerMo)						or 	-- touching quicksand.
			player.playerstate == PST_DEAD				or	-- death (MORTIS)
			P_PlayerInPain(player) 						or	-- just received damage
			pks[k_spinouttimer]  > 0		or	-- in spinout
			pks[k_squishedtimer] > 0		or  -- squished
			playerMo.paraglideMobj.valid == false		-- paraglider got destroyed
			)
		then
			jglider.createDeadGlider(playerMo)
			jglider.resetGliderStuff(playerMo)
			S_StartSound(playerMo, sfx_paglno)
		--landed from gliding will buffer the destruction insead
		elseif (P_IsObjectOnGround(playerMo) and pks[k_pogospring] == 0) then
			playerMo.glideFinBuffer = $ + 1
			if playerMo.glideFinBuffer >= PG_COYOTETIMETICS then
				jglider.createDeadGlider(playerMo)
				jglider.resetGliderStuff(playerMo)
				S_StartSound(playerMo, sfx_paglno)
			end
		elseif playerMo.momz > PG_MAXFALL then
			if playerMo.glideFinBuffer > 0 and playerMo.startFallVel == 0 then
				playerMo.startFallVel = max(playerMo.momz, 1)
				playerMo.glideFinBuffer = max($ - 1, 0)
			end
		end
	end
end

if jglider.logicVer == nil then
--[[
	This looks strange, but here's the reasoning:
	As the Lua gets loaded multiple times from loaded maps, more and more
	hooks to the same stuff will happen. This is not performant.
	Checking nil here lets us know that we're the first script to load.
	And the functions attached to the hooks are on our jglider table.
	This also means we're not wasting memory defining the same functions.
	As more of the same script loads, only the function 
	changes assuming it's new, and we're not hooking more.
	It's even safer given that maps are usually loaded at the start.
]]
	addHook("MobjThinker", 
		function(playerMo)
			--[[
				Another thing that seemingly makes no sense...
				The thing about hooks is that if you pass a function
				that they use for handling, they make a COPY of the
				function instead of using a REFERENCE to the function.
				So this allows it to be self-updating with higher versions
				that replace it. Lua is a fucking MESS.
			]]
			jglider.glidingLogic(playerMo)
		end,
	MT_PLAYER)
end

jglider.logicVer = PARAGLIDERLOGICVERSION

else
	if jglider.CVar_ParagliderDebug ~= nil and jglider.CVar_ParagliderDebug.value == 1 then
		print("\130GLIDER WARNING:\128 An older/same paraglider LOGIC version ("..PARAGLIDERLOGICVERSION..") is being loaded, "..
				"current is "..jglider.logicVer..", skipping...")
	end
end