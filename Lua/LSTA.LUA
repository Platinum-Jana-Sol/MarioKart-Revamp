freeslot("MT_LUIGISTATUE", "S_STATUE", "SPR_STUE")

addHook("MobjSpawn", function(mobj)
    if gamemap ~= 864 then return end
    mobj.scale = 2 * FRACUNIT
end,MT_LUIGISTATUE)