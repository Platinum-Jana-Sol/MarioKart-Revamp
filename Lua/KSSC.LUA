--this is KartSoundScapes
freeslot("sfx_ksflap")

addHook("PlayerThink", function(player)
	if mapheaderinfo[gamemap].kartsoundscapes ~= "true" then return end
	if leveltime == 1 then player.flapjingleflag = false end
	player.flapjingle = $ or 0
	local currentmusic, dummy1, dummy2 = S_MusicInfo(player)
	local isPowerMusic
	if player.kartstuff[k_invincibilitytimer] > 0 or player.kartstuff[k_growshrinktimer] > 0
		isPowerMusic = true
	else
		isPowerMusic = false
	end
	--print(isPowerMusic)
	--print(player.flapjingle)
	if leveltime < 8*TICRATE then return end
	if player.laps == mapheaderinfo[gamemap].numlaps then return end
	--print("KSS enabled")
	if mapheaderinfo[gamemap].finallapmusic == "true"
		if player.laps == mapheaderinfo[gamemap].numlaps -1 --and S_MusicInfo(player) == mapheaderinfo[gamemap].music
			player.finallapmusic = true
			--print("On final lap")
		else
			player.finallapmusic = false
			--print("Not on final lap")
		end
	end
	if mapheaderinfo[gamemap].glidermusic == "true"
		if player.mo.paragliding == true --and S_MusicInfo(player) == mapheaderinfo[gamemap].music
			player.glidingmusic = true
			--print("Gliding")
		else
			player.glidingmusic = false
			--print("Not Gliding")
		end
	end
	
	if player.finallapmusic == true and mapheaderinfo[gamemap].finallapmusic == "true"
		if (tostring(currentmusic) == mapheaderinfo[gamemap].normalmusic or tostring(currentmusic) == mapheaderinfo[gamemap].glidermusic) and player.flapjingleflag ~= true
			S_StopMusic(player)
			S_StartSound(nil, sfx_ksflap, player)
			S_SetMusicPosition(0)
			player.flapjingle = 85
			player.flapjingleflag = true
		end
		if player.flapjingle < 1 and isPowerMusic == false
			if player.glidingmusic == true and mapheaderinfo[gamemap].glidermusic == "true"
				if tostring(currentmusic) ~= mapheaderinfo[gamemap].finalglider then S_ChangeMusic(mapheaderinfo[gamemap].finalglider, true, player, 0, S_GetMusicPosition(), 0, 0) end
			else
				if tostring(currentmusic) ~= mapheaderinfo[gamemap].finallap then S_ChangeMusic(tostring(mapheaderinfo[gamemap].finallap), true, player, 0, S_GetMusicPosition(), 0, 0) end
			end
		end
	else
		if isPowerMusic == false
			if player.glidingmusic == true and mapheaderinfo[gamemap].glidermusic == "true"
				if tostring(currentmusic) ~= mapheaderinfo[gamemap].normalglider then S_ChangeMusic( mapheaderinfo[gamemap].normalglider, true, player, 0, S_GetMusicPosition(), 0, 0) end
			else
				if tostring(currentmusic) ~= mapheaderinfo[gamemap].normalmusic then S_ChangeMusic(mapheaderinfo[gamemap].normalmusic, true, player, 0, S_GetMusicPosition(), 0, 0) end
			end
		end
	end
	if player.flapjingle > 0 then player.flapjingle = $ - 1 end
end)