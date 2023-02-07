/* Freeslots */
freeslot(
	"MT_RANDOMITEMBOX",
	"MT_RANDOMITEMBOXSPAWNER"
)

/* Random Item Spawner */
local function SpawnBox(thing)
	if (thing.spawnpoint.valid and thing.angle != 0) then -- Check spawnpoint validity
		if ((leveltime / TICRATE) % (AngleFixed(thing.angle)/FRACUNIT) == 0 and leveltime % TICRATE == 0 and leveltime > 35) then -- Check how often to spawn Random Items
			local spawnedobject = P_SpawnMobj(thing.x, thing.y, thing.z, MT_RANDOMITEMBOX)
			spawnedobject.spawnpoint = thing.spawnpoint
			spawnedobject.spawneditem = true
		end
	end
end -- Close function

local function GiveItem(thing, other)
	if (other.player and not other.player.spectator) then
		if (P_CanPickupItem(other.player, 1)) then
			other.player.kartstuff[k_itemroulette] = 1
			thing.fuse = 72 -- Time until item box respawn in tics
			return false -- "Kill" item box
		end
	end
	return true -- Do nothing
end -- Close function

local function RespawnBox(thing)
	local SpawnedObject = P_SpawnMobj(thing.x, thing.y, thing.z, MT_RANDOMITEMBOX)
	SpawnedObject.spawnpoint = thing.spawnpoint
	return true
end -- Close function

local function SetObjectVars(thing)
	thing.flagsassigned = false
	thing.spawneditem	= false
end -- Close function

local function SetObjectFlags(thing)
	if (thing.flagsassigned == false) then
		if ((thing.spawnpoint.options & (MTF_AMBUSH)) and thing.spawneditem == false) then else
			thing.flags = $ & ~(MF_NOGRAVITY)
		end
		thing.flagsassigned = true
	end
	/* Make sure to remove item eventually */
	if P_CheckDeathPitCollide(thing)
		P_RemoveMobj(thing)
	end
end -- Close function

addHook("TouchSpecial",	GiveItem,		MT_RANDOMITEMBOX)
addHook("MobjFuse",		RespawnBox,		MT_RANDOMITEMBOX)
addHook("MobjThinker",	SetObjectFlags,	MT_RANDOMITEMBOX)
addHook("MobjSpawn",	SetObjectVars,	MT_RANDOMITEMBOX)

addHook("MobjCollide",	do return false end,	MT_RANDOMITEMBOX) -- Don't collide with objects

addHook("MobjThinker",	SpawnBox,	MT_RANDOMITEMBOXSPAWNER)