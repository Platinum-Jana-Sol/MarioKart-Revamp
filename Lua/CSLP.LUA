--Copy Slope fix, by Jana Sol
freeslot("MT_ROCKTREE")
addHook("MobjThinker", function(mobj)
	if leveltime == 1 then
		if mobj.subsector.sector.f_slope ~= nil then
			mobj.z = P_GetZAt(mobj.subsector.sector.f_slope, mobj.x, mobj.y)
		end
	end
end, MT_ROCKTREE)

addHook("MobjThinker", function(mobj)
	if gamemap == 887 then
		mobj.scale = 4*FRACUNIT
	end
end, MT_FALLINGROCK)

addHook("MobjSpawn", function(mobj)
	if gamemap == 887 then
		mobj.scale = 2*FRACUNIT
	end
end, MT_ROCKTREE)