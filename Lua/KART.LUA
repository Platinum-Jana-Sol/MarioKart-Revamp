if (emptykarts_initialized) then return end -- Check if the script has already been run

/* Freeslots */
freeslot(
	"MT_EMPTYKART",
	"MT_EMPTYKARTSPAWNER"
)

/* ALL CREDIT TO CHAOBROTHER FOR THIS MASSIVE FUNCTION 
   I HAVE NO IDEA HOW IT WORKS LOL */

-- Ported form of K_KartBouncing and K_GetMobjWeight used for empty kart interactions.
local function KartBounce(mobj1, mobj2, bounce, solid, objweight)
	local momdifx, momdify
	local distx, disty
	local dot, force
	local mass1 
	local mass2
	
	if (not mobj1 or not mobj2)
		return
	end
	
	-- Don't bump when you're being reborn
	if ((mobj1.player and mobj1.player.playerstate != PST_LIVE)
		or (mobj2.player and mobj2.player.playerstate != PST_LIVE)) then
		return
	end

	if ((mobj1.player and mobj1.player.kartstuff[k_respawn])
		or (mobj2.player and mobj2.player.kartstuff[k_respawn])) then
		return
	end
	
	-- Don't bump if you're flashing
	local flash
	if(mobj1.player)
		flash = K_GetKartFlashing(mobj1.player);
		if (mobj1.player and mobj1.player.powers[pw_flashing] > 0 and mobj1.player.powers[pw_flashing] < flash) then
			if (mobj1.player.powers[pw_flashing] < flash-1)
				mobj1.player.powers[pw_flashing] = $1 + 1
				return
			end
		end
	end
	
	if(mobj2.player)
		flash = K_GetKartFlashing(mobj2.player);
		if (mobj2.player and mobj2.player.powers[pw_flashing] > 0 and mobj2.player.powers[pw_flashing] < flash) then
			if (mobj2.player.powers[pw_flashing] < flash-1) then
				mobj2.player.powers[pw_flashing] = $1 + 1
				return
			end
		end
	end
	
	if (mobj1.player and mobj1.player.kartstuff[k_justbumped]) then
		mobj1.player.kartstuff[k_justbumped] = 6
		return
	end
	
	if (mobj2.player and mobj2.player.kartstuff[k_justbumped]) then
		mobj2.player.kartstuff[k_justbumped] = 6
		return
	end

	if (mobj1.player) then
			if (mobj1.player.kartstuff[k_spinouttimer] > 0) then
				mass1 = 0
			else
				mass1 = (mobj1.player.kartweight)<<FRACBITS
				if (mobj1.player.speed > K_GetKartSpeed(mobj1.player, false)) then
					mass1 = $1 + (mobj1.player.speed - K_GetKartSpeed(mobj1.player, false))/8
				end
			end
	else
		mass1 = objweight
	end
	
	if (solid == true and mass1 > 0) then
		mass2 = mass1
	else
		if (mobj2.player) then
			if (mobj2.player.kartstuff[k_spinouttimer] > 0) then
				mass2 = 0
			else
				mass2 = (mobj2.player.kartweight)<<FRACBITS
				if (mobj2.player.speed > K_GetKartSpeed(mobj2.player, false)) then
					mass2 = $1 + (mobj2.player.speed - K_GetKartSpeed(mobj2.player, false))/8
				end
			end
		else
			mass2 = objweight
		end
	end
	
	momdifx = mobj1.momx - mobj2.momx
	momdify = mobj1.momy - mobj2.momy
	
	-- Adds the OTHER player's momentum times a bunch, for the best chance of getting the correct direction
	-- possibly Edit so it affects collided object.
	distx = (mobj1.x + mobj2.momx*3) - (mobj2.x + mobj1.momx*3)
	disty = (mobj1.y + mobj2.momy*3) - (mobj2.y + mobj1.momy*3)

	if (distx == 0 and disty == 0) then
		-- If there's no distance between the 2, they're directly on top of each other, don't run this
		return
	end

	-- Normalize distance to the sum of the two objects' radii, since in a perfect world that would be the distance at the point of collision...
		local dist = FixedHypot(distx, disty)
		local nx = FixedDiv(distx, dist)
		local ny = FixedDiv(disty, dist)
		
		-- dist = dist ? dist : 1;
		if not dist == dist
			dist = 1
		end
		
		distx = FixedMul(mobj1.radius+mobj2.radius, nx)
		disty = FixedMul(mobj1.radius+mobj2.radius, ny)

		if (momdifx == 0 and momdify == 0) then
			-- If there's no momentum difference, they're moving at exactly the same rate. Pretend they moved into each other.
			momdifx = -nx
			momdify = -ny
		end

	-- If the speed difference is less than this let's assume they're going proportionately faster from each other
	if (FixedHypot(momdifx, momdify) < (25*mapobjectscale)) then
		local momdiflength = FixedHypot(momdifx, momdify)
		local normalisedx = FixedDiv(momdifx, momdiflength)
		local normalisedy = FixedDiv(momdify, momdiflength)
		momdifx = FixedMul((25*mapobjectscale), normalisedx)
		momdify = FixedMul((25*mapobjectscale), normalisedy)
	end

	dot = FixedMul(momdifx, distx) + FixedMul(momdify, disty)

	if (dot >= 0)
		-- They're moving away from each other
		return
	end

	force = FixedDiv(dot, FixedMul(distx, distx)+FixedMul(disty, disty))
	if (bounce == 1 and mass2 > 0) -- Perform a Goomba Bounce.
		mobj1.momz = -mobj1.momz
	else
		local newz = mobj1.momz
		if (mass2 > 0) then
			mobj1.momz = mobj2.momz
		elseif (mass1 > 0 and solid == false) then
			mobj2.momz = newz
		end
	end

	if (mass2 > 0) then
		mobj1.momx = mobj1.momx - FixedMul(FixedMul(FixedDiv(2*mass2, mass1 + mass2), force), distx)
		mobj1.momy = mobj1.momy - FixedMul(FixedMul(FixedDiv(2*mass2, mass1 + mass2), force), disty)
	end

	if (mass1 > 0 and solid == false) then
		mobj2.momx = mobj2.momx - FixedMul(FixedMul(FixedDiv(2*mass1, mass1 + mass2), force), -distx)
		mobj2.momy = mobj2.momy - FixedMul(FixedMul(FixedDiv(2*mass1, mass1 + mass2), force), -disty)
	end
	
	S_StartSound(mobj1, sfx_s3k49)
	-- S_StartSound(mobj1, sfx_alarm) -- Debug
	local fx = P_SpawnMobj(mobj1.x/2 + mobj2.x/2, mobj1.y/2 + mobj2.y/2, mobj1.z/2 + mobj2.z/2, MT_BUMP);
	-- print(fx.type) -- Debug
	if (mobj1.eflags & MFE_VERTICALFLIP) then
		fx.eflags = $1 | MFE_VERTICALFLIP
	else
		fx.eflags = $1 & ~MFE_VERTICALFLIP
	end
	-- Because this is done during collision now, rmomx and rmomy need to be recalculated
	-- so that friction doesn't immediately decide to stop the player if they're at a standstill
	-- Also set justbumped here
	if (mobj1.player) then
		mobj1.player.rmomx = mobj1.momx - mobj1.player.cmomx
		mobj1.player.rmomy = mobj1.momy - mobj1.player.cmomy
		mobj1.player.kartstuff[k_justbumped] = 6 -- bumptime
		if (mobj1.player.kartstuff[k_spinouttimer])
			mobj1.player.kartstuff[k_wipeoutslow] = 20+1 -- wipeoutslowtime
			mobj1.player.kartstuff[k_spinouttimer] = max(20+1, mobj1.player.kartstuff[k_spinouttimer])
		end
	end
		
	if (mobj2.player) then
		mobj2.player.rmomx = -(mobj2.momx - mobj2.player.cmomx)
		mobj2.player.rmomy = -(mobj2.momy - mobj2.player.cmomy)
		mobj2.player.kartstuff[k_justbumped] = 6 -- bumptime
		if (mobj2.player.kartstuff[k_spinouttimer])
			mobj2.player.kartstuff[k_wipeoutslow] = 20+1 -- wipeoutslowtime
			mobj2.player.kartstuff[k_spinouttimer] = max(20+1, mobj2.player.kartstuff[k_spinouttimer])
		end
	end
	-- print("M1: "..mass1) -- Debug
	-- print("M2: "..mass2) -- Debug
end -- Close Function

/* Empty Kart Spawner */
local function SpawnEmptyKart(thing)
	if (thing.spawnpoint.valid and thing.angle != 0) then -- Check spawnpoint validity
		if (leveltime % (AngleFixed(thing.angle)/FRACUNIT) == 0 and leveltime > 35) then -- Check how often to spawn Empty Karts
			local SpawnedObject = P_SpawnMobj(thing.x, thing.y, thing.z, MT_EMPTYKART)
			SpawnedObject.spawnpoint = thing.spawnpoint
		end
	end
end -- Close function

/* Randomize object color */
local function RandomizeColor(thing)
	thing.color = P_RandomRange(1,MAXSKINCOLORS-1)
end -- Close function

/* Randomize object angle */
local function RandomizeAngle(thing)
	local SnapToAngle = ANGLE_45
	local ANGLE_360 = 4294967295 -- ANGLE_MAX returns -1 in Lua
	thing.angle = P_RandomRange(1, 360) * ANG1 -- Randomize Angle between 0 and 360 degrees
	thing.angle = $ % (ANGLE_360 / SnapToAngle) * SnapToAngle -- Snap to <SnapToAngle> degree increments
end -- Close function

/* Set object variables */
local function SetObjectVars(thing)
	thing.flagsassigned = false	-- Set to true after 1 tic when object flags are changed
	thing.hornassigned  = false	-- Value determines if horn has been selected for a specific Object
	thing.spinouttimer  = 0 -- Spinout timer for karts
	thing.fuse = 12
end -- Close Function

/* Handle collision with another object */
local function BumpCode(thing, other)
	local bumpfuse = 6
	local objweight = thing.spawnpoint.extrainfo
	thing.shouldcollide = false
	if (thing.z <= other.z + other.height and other.z <= thing.z + thing.height) then -- Height check
		if (thing.state != S_KARTSQUISHED) then -- Squished karts never collide
			/* Check for players */
			if (other.player and not other.player.spectator and (other.player.kartstuff[k_justbumped] == 0) and (other.player.powers[pw_flashing] == 0) and not (thing.spawnpoint.options & (MTF_AMBUSH))) then
				if (objweight > 9) then -- Constrain weight to vanilla limits
					objweight = 9
				elseif (objweight < 1) then
					objweight = 1
				end
				/* Check for Grow */
				if (other.player.kartstuff[k_growshrinktimer] > 0) then
					thing.state = S_KARTSQUISHED
				/* Check for Invinc */
				elseif (other.player.kartstuff[k_invincibilitytimer] > 0)
					thing.spinouttimer = 36
					KartBounce(other, thing, 0, false, 0<<FRACBITS)
					KartBounce(thing, other, 0, false, 9<<FRACBITS)
				/* Player has no powers */
				else
					KartBounce(other, thing, 0, false, objweight<<FRACBITS)
					KartBounce(thing, other, 0, false, other.player.kartweight<<FRACBITS)
				end
				
				/* Play Horn */
				if (other.player.nethornenabled) then -- Check if player has HORNMOD enabled
					if (thing.hornassigned == false) then -- Check if random horn has been selected
						if (thing.spawnpoint.options & (MTF_OBJECTSPECIAL)) then
							thing.extravalue1 = P_RandomRange(_G["sfx_hbdbrk"], _G["sfx_hbdbrk"]) -- Get *funny* horn
						else
							thing.extravalue1 = P_RandomRange(_G["sfx_hbdcap"], _G["sfx_hbdbrk"]) -- Get random horn
						end
						thing.hornassigned = true -- A random horn has been selected
					end
					S_StartSound(thing, thing.extravalue1) -- Play Horn sound
				end
				
				thing.fuse = bumpfuse -- Set Kart unable to collide for another <bumpfuse> tics
				thing.shouldcollide = true
			
			/* Check for solid karts */
			elseif (thing.spawnpoint.options & (MTF_AMBUSH)) then
				KartBounce(other, thing, 0, true, objweight<<FRACBITS) -- Only bounce *colliding* object– Object should remain stationary
				/* Play Horn */
				if (other.player and other.player.nethornenabled) then -- Check if player has HORNMOD enabled
					if (thing.hornassigned == false) then -- Check if random horn has been selected
						if (thing.spawnpoint.options & (MTF_OBJECTSPECIAL)) then
							thing.extravalue1 = P_RandomRange(_G["sfx_hbdbrk"], _G["sfx_hbdbrk"]) -- Get *funny* horn
						else
							thing.extravalue1 = P_RandomRange(_G["sfx_hbdcap"], _G["sfx_hbdbrk"]) -- Get random horn
						end
						thing.hornassigned = true -- A random horn has been selected
					end
					S_StartSound(thing, thing.extravalue1) -- Play Horn sound
				end
				thing.fuse = bumpfuse
				thing.shouldcollide = true
			
			/* Check for other objects */
			elseif (not other.player and other.flags & (MF_SOLID) and thing.fuse == 0)
				KartBounce(thing, other, 0, true, 5<<FRACBITS)
				KartBounce(other, thing, 0, true, 5<<FRACBITS)
				
				thing.fuse = bumpfuse -- Set Kart unable to collide for another <bumpfuse> tics
				thing.shouldcollide = true
			end
		end
	end
	return thing.shouldcollide -- Check if objects should collide
end -- Close function

/* Add functions to hooks */
addHook("MobjCollide",	BumpCode,		MT_EMPTYKART)
addHook("MobjSpawn",	RandomizeColor,	MT_EMPTYKART)
addHook("MobjSpawn",	RandomizeAngle,	MT_EMPTYKART)
addHook("MobjSpawn",	SetObjectVars,	MT_EMPTYKART)
/* Override functions that potentially kill the Kart */
addHook("MobjFuse",		do return true end,	MT_EMPTYKART)
addHook("TouchSpecial",	do return true end,	MT_EMPTYKART)

addHook("MobjThinker",	SpawnEmptyKart,	MT_EMPTYKARTSPAWNER)

addHook("MobjThinker", function(thing)
	/* Assign flags on first tic spawned */
	if (thing.flagsassigned == false) then
		if (thing.spawnpoint.options & (MTF_AMBUSH)) then
			thing.flags = $ & ~(MF_SPECIAL)
			thing.flags = $ & ~(MF_PUSHABLE)
		end
	thing.flagsassigned = true
	end
	/* Spin kart on invinc bump */
	if thing.spinouttimer then
		thing.angle = $ + ANG10
		thing.spinouttimer = max($ - 1, 0)
	end
	/* PEOPLE DIE WHEN THEY ARE KILLED */
	if P_CheckDeathPitCollide(thing)
		P_RemoveMobj(thing)
	end
end -- Close Function
,MT_EMPTYKART)

rawset(_G, "emptykarts_initialized", true) -- The script ran, don't run it again