
-- Create a net message for spawning Tie Fighters
util.AddNetworkString("spawn_tie_fighter")

if iPM == nil then iPM = {} end

function iPM.SendPadsToPlayer(ply)
	local tbl = {}
	for t, _ in pairs(iPM.SpawnPads) do
		for __, pad in pairs(iPM.SpawnPads[t]) do
			if pad.team != nil && pad.PadNumber != nil then
				table.insert(tbl, {pad, pad.team, pad.PadNumber})
			end
		end
	end

	net.Start('iPM.SendAllToClient')	
		net.WriteTable(tbl)
	net.Send(ply)
end

hook.Add("iPM_Loaded", "sv", function()
	if iPM.SpawnPads == nil then
		iPM.SpawnPads = {}

		if iPM.Teams == nil then include("config.lua") end
		for t,v in pairs(iPM.Teams) do
			iPM.SpawnPads[t] = {}
		end
	end

	-- Set the cooldown time for spawning Tie Fighters
	local cooldownTime = iPM.PilotCooldownTime

	-- Create a table to store the pilots on cooldown
	local pilotsOnCooldown = {}

	-- Create a net message for the vgui
	util.AddNetworkString("pilot_vgui")

	-- Create a chat command for accessing the vgui
	hook.Add("PlayerSay", "iPM.PlayerSay", function(ply, txt, team)
		if (txt == "!pilot" or txt == "/pilot") or (txt == "!spawn" or "/spawn") then

			for name,v in pairs(iPM.Teams) do
				if iPM.Teams[name]["TEAMS"][ply:Team()] != nil then
					if table.Count(iPM.SpawnPads[name]) >= 1 then
						net.Start("pilot_vgui")
						net.Send(ply)
					else
						ply:ChatPrint("iPM: It looks like your server administrator has not set up any spawn pads.")
					end
				end
			end

			return ""
		end
	end)

	-- Create a function to handle the net message for spawning Tie Fighters
	net.Receive("spawn_tie_fighter", function(len, ply)
		-- Check if the player is a member of an allowed team
		for name,v in pairs(iPM.Teams) do
			if iPM.Teams[name]['TEAMS'][ply:Team()] != nil then
				-- Check if the player is on cooldown
				if pilotsOnCooldown[ply] then
					ply:ChatPrint("You are currently on cooldown.")
					return
				end

				-- Get the selected Tie Fighter from the net message
				local selectedFighter = net.ReadString()
				local selectedPad = net.ReadEntity()

				-- Check if the selected Tie Fighter is in the list of allowed fighters
				if not table.HasValue(iPM.Teams[name]['TEAMS'][ply:Team()], selectedFighter) then return end

				local tieSpawned = false
				-- Spawn the selected Tie Fighter

				local function CreateTIEFighter(pad)
					local tieFighter = ents.Create(selectedFighter)
					tieFighter:Spawn()
					tieFighter:Activate()
					local angleOffset = Angle(0,0,0)
					for class,angle in pairs(iPM.Offsets) do
						if tieFighter:GetClass() == class then
							angleOffset = angle
						end
					end
					tieFighter:SetAngles(pad:GetAngles() + angleOffset)
					local pos1 = pad:GetPos()
					local maxs1 = pad:OBBMaxs()
					local mins1 = pad:OBBMins()
					local height1 = maxs1.z - mins1.z
					local maxs2 = tieFighter:OBBMaxs()
					local mins2 = tieFighter:OBBMins()
					local height2 = maxs2.z - mins2.z
					local physObj = tieFighter:GetPhysicsObject()
					if physObj:IsValid() then
						physObj:EnableMotion(false)
						tieFighter.oldMaterial = tieFighter:GetMaterial()
						timer.Create("iPM.stophammertime"..tieFighter:GetCreationID(), 0, 58, function()
							if physObj:IsValid() then
								physObj:EnableMotion(false)
								physObj:SetVelocity(Vector(0,0,0))
								tieFighter:SetMaterial("Models/effects/comball_tape")
								tieFighter:SetRenderMode(1)
								tieFighter:SetColor(Color(255,0,0))
							end
						end)
						timer.Create("iPM.WaitforAnim"..tieFighter:GetCreationID(), 4, 1, function()
							if physObj:IsValid() then
								physObj:EnableMotion(true)
								physObj:SetVelocity(Vector(0,0,-1))
								tieFighter:SetMaterial(tieFighter.oldMaterial)
								tieFighter:SetColor(Color(255,255,255))
							end
						end)
					end
					tieFighter:SetPos(pos1 - Vector(0, 0, height1-height2/1.9))
					tieSpawned = true
					ply:ChatPrint("iPM: Your vehicle has been placed on Pad "..pad.PadNumber..". You have "..iPM.ShipDespawnTime.." seconds to remove it from the pad or it will be deleted.")
					-- Set the player as the owner of the Tie Fighter
					tieFighter:SetNWEntity("owner", ply)
				end

				if selectedPad == nil or selectedPad:GetClass() == "worldspawn" then
					for k,v1 in pairs(iPM.SpawnPads[name]) do
						if tieSpawned == false then
							if v1.Occupied == false then
								CreateTIEFighter(v1)
							end
						end
					end
				else
					if selectedPad.Occupied == false then
						CreateTIEFighter(selectedPad)
					else
						ply:ChatPrint("iPM: Pad "..selectedPad.PadNumber.." is already occupied!")
					end
				end

				if tieSpawned == false then
					if selectedPad == nil then
						ply:ChatPrint("iPM: There are no available pads to place your ship!")
					end
				else
					-- Add the player to the list of pilots on cooldown
					pilotsOnCooldown[ply] = true

					-- Set a timer to remove the player from the list of pilots on cooldown
					timer.Create("cooldown_timer_" .. ply:SteamID64(), cooldownTime, 1, function()
						pilotsOnCooldown[ply] = nil
					end)
				end
			end
		end

	end)

	hook.Add("PlayerInitialSpawn", "iPM.PlayerLoaded", function(ply)
		timer.Create("iPM.waitonply"..ply:SteamID(), 0, 1, function()

			iPM.SendPadsToPlayer(ply)
		end)
	end)

end)