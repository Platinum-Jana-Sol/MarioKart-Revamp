-- This lua file defines the paraglider object

-- this action is visual only!
-- actor.target     indicates the player it is attached to

-- if paraglide angle == player angle, idle state.
-- if not, then it is moving.
-- > 0 means it is moving to the right.
-- < 0 means it is moving to the left.
-- 1 - 5    = B frame, slight   turn
-- 5 - 10   = C frame, moderate turn
-- 10 - 15  = D frame, strong   turn
-- 15 - 20  = E frame, forceful turn

-- IMPORTANT!! NEWER VERSION WILL OVERRIDE OLDER VERSIONS
local PARAGLIDERVISUALSVERSION	= 7
if jglider == nil then
	rawset(_G, "jglider", {})
end

if jglider.visualsVer == nil or jglider.visualsVer < PARAGLIDERVISUALSVERSION then
-- start

local ANG1			        = ANG1
local ANGLE_180				= ANGLE_180
local FRACUNIT				= FRACUNIT

local paraglideSlightTurn   = ANG1
local paraglideModerateTurn = ANG1 * 15
local paraglideStrongTurn   = ANG1 * 30
local paraglideForcefulTurn = ANG1 * 45

function A_JugParaglideMovement(actor, var1, var2)

	if 	actor				== nil		or
		actor.valid			== false	or
		actor.target 		== nil 		or
		actor.target.valid 	== false 	then
		P_RemoveMobj(actor)
		return
	end

	local playerMo = actor.target

	-- position the glider above the player at all times.
	local initialPos = FixedMul(jglider.ParagliderZPos * FRACUNIT, playerMo.scale) * P_MobjFlip(playerMo)

	P_TeleportMove(actor, playerMo.x, playerMo.y, playerMo.z + initialPos)

	-- handle that rotation
	local isNegative = false

	local turnDifference = actor.angle - playerMo.angle
	if turnDifference < 0 then
		isNegative = true
	end

	turnDifference = abs(turnDifference)

	-- set angle to the playerMo's momentum
	local thrustAngle = R_PointToAngle2(0, 0, playerMo.momx, playerMo.momy)

	local angleCorrectRate = jglider.getTurnRateGlider(playerMo.player)

	if thrustAngle > playerMo.angle then
		thrustAngle = $ - angleCorrectRate
	elseif thrustAngle < playerMo.angle then
		thrustAngle = $ + angleCorrectRate
	end

	-- the glider will spin if the player is pogoing
	if playerMo.player.kartstuff[k_pogospring] >= 1 then
		actor.angle = playerMo.player.frameangle
	else
		actor.angle = thrustAngle

		if actor.state == S_PAGL_IDLE then
			if turnDifference > (ANG1 * 2) then
				
				if turnDifference > paraglideForcefulTurn       then
					actor.frame = E
				elseif turnDifference > paraglideStrongTurn     then
					actor.frame = D
				elseif turnDifference > paraglideModerateTurn   then
					actor.frame = C
				elseif turnDifference > paraglideSlightTurn     then
					actor.frame = B
				end
				
				if isNegative then
					actor.frame = $ + E
				end
			else
				actor.frame = A
			end
		end
	end

	-- handling flipping and color matching from the playerMo
	K_MatchGenericExtraFlags(actor, playerMo)

	if playerMo.player.kartstuff[k_invincibilitytimer] or
		playerMo.player.kartstuff[k_growshrinktimer] then

		actor.color = playerMo.color

		if playerMo.colorized then
			actor.colorized = true
		end

		if playerMo.player.kartstuff[k_invincibilitytimer] == 1 or
			playerMo.player.kartstuff[k_growshrinktimer] == 1 then
			actor.color = playerMo.player.skincolor
			actor.colorized = false
		end
	end

	-- handling scale
	if actor.destscale != playerMo.destscale then
		actor.destscale = playerMo.destscale
	end

	-- print(turnDifference)

end

function A_JugParaglideDeadMovement(actor, var1, var2)

end

freeslot("MT_JUG_PARAGLIDER", "MT_JUG_DEADGLIDER", "MT_JUG_GLIDERTRAIL", "SPR_PAGL", "SPR_PAGM", "S_PAGL_SPAWNIDLE", "S_PAGL_IDLE", "sfx_paglgo", "sfx_paglno",
"S_PAGLRIP_DEADIDLE", "S_PAGLRIP_FADE1", "S_PAGLRIP_FADE2", "S_PAGLRIP_FADE3", "S_PAGLTRAIL_IDLE" )

mobjinfo[MT_JUG_PARAGLIDER] =
{
	doomednum       = -1,           -- has no attached thing
	spawnstate      = S_PAGL_SPAWNIDLE,
	spawnhealth     = 1,            -- can be shot down with an item!

	radius          = 16 * FRACUNIT,
	height          = 8 * FRACUNIT,
	flags           = MF_NOGRAVITY,

	dispoffset      = -1,             -- rendered over the sprite
	-- raisestate is used to know who to attach to
}

states[S_PAGL_SPAWNIDLE] =
{
	sprite = SPR_PAGL,
	frame = J,
	tics = 1,
	action = A_JugParaglideMovement,
	nextstate = S_PAGL_SPAWNIDLE
}

-- this is absolutely scuffed but it's much better than writing it manually
-- we do it like this because each tic HAS to run the action,
-- e.g. if it goes for 2 tics, the action won't run for one tic
local frameOrder = { J, J, K, K, L, K, L, M, L, L, M, M, N }

for i = 1, #frameOrder
	local stateToFreeslot = "S_PAGL_SPAWN" + i;
	freeslot(stateToFreeslot);

	local nextState
	if (i + 1) <= #frameOrder then
		nextState = _G[stateToFreeslot] + 1
	else
		nextState = S_PAGL_IDLE
	end

	states[_G[stateToFreeslot]] =
	{
		sprite = SPR_PAGL,
		frame = frameOrder[i],
		tics = 1,
		action = A_JugParaglideMovement,
		nextstate = nextState
	}
end

states[S_PAGL_IDLE] =
{
	sprite = SPR_PAGL,
	frame = A,
	tics = 1,
	action = A_JugParaglideMovement,
	nextstate = S_PAGL_IDLE
}


mobjinfo[MT_JUG_DEADGLIDER] =
{
	doomednum       = -1,           -- has no attached thing
	spawnstate      = S_PAGLRIP_DEADIDLE,
	spawnhealth     = 1,

	radius          = 8 * FRACUNIT,
	height          = 4 * FRACUNIT,
	flags           = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY,

	dispoffset      = -1,             -- rendered over the sprite
}

states[S_PAGLRIP_DEADIDLE] =
{
	sprite = SPR_PAGL,
	frame = TR_TRANS10|A, -- only at yoshimo's request
	tics = 105,
	nextstate = S_PAGLRIP_FADE1
}

states[S_PAGLRIP_FADE1] =
{
	sprite = SPR_PAGL,
	frame = TR_TRANS30|A,
	tics = 1,
	nextstate = S_PAGLRIP_FADE2
}

states[S_PAGLRIP_FADE2] =
{
	sprite = SPR_PAGL,
	frame = TR_TRANS60|A,
	tics = 1,
	nextstate = S_PAGLRIP_FADE3
}

states[S_PAGLRIP_FADE3] =
{
	sprite = SPR_PAGL,
	frame = TR_TRANS90|A,
	tics = 1,
	nextstate = S_NULL
}

mobjinfo[MT_JUG_GLIDERTRAIL] =
{
	doomednum       = -1,           -- has no attached thing
	spawnstate      = S_PAGLTRAIL_IDLE,
	spawnhealth     = 1,			-- changes depending on stored momentum

	radius          = FRACUNIT,
	height          = FRACUNIT,
	flags           = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY|MF_DONTENCOREMAP,
}

states[S_PAGLTRAIL_IDLE] =
{
	sprite = SPR_PAGM,
	frame = FF_FULLBRIGHT|A,
	tics = -1,
	nextstate = S_PAGLTRAIL_IDLE
}

-- sfxinfo[sfx_paglgo] = {false, 64, SF_TOTALLYSINGLE}
-- sfxinfo[sfx_paglno] = {false, 64, SF_TOTALLYSINGLE}

jglider.gliderDamageLogic = function(target, inflictor, source, damagetype)
	local player = target.target.player

	if inflictor ~= nil and
		player ~= nil and
		(player.powers[pw_flashing] or
		player.powers[pw_invulnerability] or
		player.kartstuff[k_invincibilitytimer] > 0 or
		player.kartstuff[k_growshrinktimer] > 0) then

		-- we generally don't tend to care how we got damaged
		-- we just need to check if it applies when the player is
		-- invulnerable, unless it's nil (caused by the world)
		K_DoInstashield(player)
		return false
	end

	if inflictor ~= nil and
		inflictor.player ~= nil then
		local player = inflictor.player

		if player.mo ~= nil and
			player.mo.paraglideMobj ~= nil then
			-- can't hit your own paraglider
			-- addresses thunder shield being a suicide button otherwise.
			if player.mo.paraglideMobj == target then
				return false
			end
		end
	end
end

jglider.handleTrailTimer = function(mo)
	if not mo.valid then return end

	mo.health = $ - 1
	P_SetScale(mo, (FRACUNIT / mo.extravalue1) * mo.health)

	if mo.health > 0 then return end
	P_KillMobj(mo)
end

if jglider.visualsVer == nil then
	addHook("ShouldDamage",
		function(target, inflictor, source, damagetype)
			jglider.gliderDamageLogic(target, inflictor, source, damagetype)
		end, MT_JUG_PARAGLIDER)
	addHook("MobjThinker",
		function(mo)
			jglider.handleTrailTimer(mo)
		end, MT_JUG_GLIDERTRAIL)
end

-- end
jglider.visualsVer = PARAGLIDERVISUALSVERSION

else
	if jglider.CVar_ParagliderDebug ~= nil and jglider.CVar_ParagliderDebug.value == 1 then
		print("\130GLIDER WARNING:\128 An older/same paraglider VISUALS version ("..PARAGLIDERVISUALSVERSION..") is being loaded, "..
				"current is "..jglider.visualsVer..", skipping...")
	end
end