-- IMPORTANT!! NEWER VERSION WILL OVERRIDE OLDER VERSIONS
local PARAGLIDERHUDVERSION	= 4
if jglider == nil then
	rawset(_G, "jglider", {})
end

if jglider.HUDVer == nil or jglider.HUDVer < PARAGLIDERHUDVERSION then
-- start

local FRACUNIT 		= FRACUNIT
local ANG1			= ANG1

-- Funny HUD + Helpers
local function countActiveSplitScreenPlayers()
	local number = 0

	for p in displayplayers.iterate do
		if p.valid then number = $ + 1 end
	end

	return number
end

local function whichSplitscreenPlayerIsThis(thisPlayer)
	local number = 1
	local howManyPlayers = countActiveSplitScreenPlayers()

	if howManyPlayers == number then return number
	elseif howManyPlayers > 1 then
		for p in displayplayers.iterate do
			if p == thisPlayer then break
			else number = $ + 1
			end
		end
	end 

	return number
end

local function isPlayerItemBoxOccupied(player)

	if 	player.kartstuff[k_itemroulette] 	> 0 or 	-- under any roulette
		player.kartstuff[k_eggmanexplode]	> 0 or	-- getting eggman'd
		player.kartstuff[k_itemtype]       ~= 0	or	-- has item (-1 is sad face)
		player.kartstuff[k_curshield]		> 0 or	-- using thunder shield
		player.kartstuff[k_stealingtimer] 	> 0 or 	-- stealing something
		player.kartstuff[k_stolentimer]		> 0 or 	-- getting stolen from
		player.kartstuff[k_growshrinktimer] > 0 or  -- beeg
		player.kartstuff[k_rocketsneakertimer] > 0 or -- rocket sneakers
		player.kartstuff[k_itemheld] == true		-- dragging/deployed item
		
		return true
	end

	return false
end

local function GliderHUDCode(v, stplyr, cam)
	if PARAGLIDERHUDVERSION < jglider.HUDVer then
		return
	end

	if stplyr 			== nil 		or
		stplyr.valid 	== false 	or 
		stplyr.mo 		== nil 		or
		stplyr.mo.valid == false 	then
		return
	end

	if stplyr.mo.paragliding == true then
		local splitscreenNum = countActiveSplitScreenPlayers()

		local barX		= 10
		local barY 		= 11
		local barWidth 	= 40

		-- we move barY down if player has item/roulette/held/growth timer
		if isPlayerItemBoxOccupied(stplyr) then
			barY = $ + 43
		-- players with store/acrohell make the glider bar offset
		-- a little to prevent overlap
		elseif ac_styleCheck ~= nil and ac_styleCheck(stplyr, TS_STORE, true)
			and splitscreenNum <= 2 then
			barX = $ + 24
		end

		local flags		= V_SNAPTOTOP|V_HUDTRANS;
		local thisPlayer = whichSplitscreenPlayerIsThis(stplyr)

		if splitscreenNum > 1 then -- more than one
			if splitscreenNum == 2 then 	-- 2 players
				flags = $|V_SNAPTOLEFT 

				if thisPlayer == 2 then
					barY = $ + 106 			-- half the regular height + 8 offset pixels.
				end

			elseif splitscreenNum > 2 then	-- more than 2
				-- base pos values as ref. to the the smol item boxes
				barX 		= $ / 2
				barY 		= $ / 2
				barWidth 	= $ / 2 -- make it smol like the item box

				-- the hud snaps to the right on players 2 and 4
				-- left otherwise
				if thisPlayer % 2 == 0 then
					flags = $|V_SNAPTORIGHT
					barX  = 320 - barWidth - $
				else
					flags = $|V_SNAPTOLEFT
				end

				-- players 3 and 4 (lower ones) have their regular weird offset.
				if thisPlayer >= 3 then barY = $ + 108 end
			end
		else flags = $|V_SNAPTOLEFT
		end
		
		-- v.drawNum(barX, barY, thisPlayer, flags)
		local timer = stplyr.mo.letGoGliderTimer or 0
		if timer > 0 then
			local funnyCalc1 = FixedMul(FixedDiv(FixedDiv((barWidth * 100) * FRACUNIT, jglider.LETGOGLIDERTIMER * FRACUNIT), 100 * FRACUNIT), timer * FRACUNIT)
			local visualTimer = FixedInt(funnyCalc1)

			local barActualWidth = barWidth - visualTimer
			-- bg
			v.drawFill(barX, 	barY-1, barWidth, 		1, 21|flags)
			v.drawFill(barX-1, 	barY, 	barWidth + 2, 	1, 23|flags)
			v.drawFill(barX-1, 	barY+1, barWidth + 2, 	1, 24|flags) 
			v.drawFill(barX-1, 	barY+2, barWidth + 2, 	1, 25|flags)
			v.drawFill(barX, 	barY+3, barWidth, 		1, 26|flags)
			-- these parts move
			v.drawFill(barX+1, 	barY, 	barActualWidth - 2, 1, 7|flags)
			v.drawFill(barX, 	barY+1, barActualWidth, 	1, 9|flags)
			v.drawFill(barX+1, 	barY+2, barActualWidth - 2, 1, 12|flags)
		end
	end

	if jglider.CVar_ParagliderDebug.value == 1 then
		local consoleplayerMo = consoleplayer.mo

		v.drawString(0, 0, "Paragliding? " 		+ consoleplayerMo.paragliding)
		v.drawString(0, 10, "Will Paraglide? " 	+ consoleplayerMo.willParaglide)

		if (consoleplayerMo.paragliding) then
			v.drawString(0, 20, "momz: " + consoleplayerMo.momz)
			v.drawString(0, 30, "Vert.Mov.Inf: " + consoleplayerMo.glideVerticalMovement)
			v.drawString(0, 40, "Player Angle:\t" + consoleplayerMo.angle / ANG1)
			local turnRate = jglider.getTurnRateGlider(consoleplayer)
			local momAngle = R_PointToAngle2(0, 0, consoleplayerMo.momx, consoleplayerMo.momy)
			v.drawString(0, 50, "Momentum Angle:\t" + momAngle / ANG1)
			v.drawString(0, 60, "Angle Left:\t" + (abs(consoleplayerMo.angle) - abs(momAngle)) / ANG1)
			v.drawString(0, 70, "Turn Rate:\t" + turnRate / (ANG1 / 35))
			v.drawString(0, 80, "Stored Momentum:\t" + consoleplayerMo.storedGlideMomz)
			v.drawString(0, 90, "Target momz:\t" + consoleplayerMo.targetFallRt)
			v.drawString(0, 100, "Starting momz:\t" + consoleplayerMo.startFallVel)
		end
	end
end
hud.add(GliderHUDCode, "game")

-- end
jglider.HUDVer = PARAGLIDERHUDVERSION

else
	if jglider.CVar_ParagliderDebug ~= nil and jglider.CVar_ParagliderDebug.value == 1 then
		print("\130GLIDER WARNING:\128 An older/same paraglider HUD version ("..PARAGLIDERHUDVERSION..") is being loaded, "..
				"current is "..jglider.HUDVer..", skipping...")
	end
end