if SERVER then 
	util.AddNetworkString("iPM.SendAllToClient") 
	util.AddNetworkString("iPM.ClientReady")
	AddCSLuaFile('ipm/ipm_config.lua')
end

if CLIENT then
	iPM = {}

	net.Receive("iPM.ClientReady", function()
		include('ipm/ipm_config.lua')
		hook.Run("iPM_Loaded")
	end)
end

if SERVER then
	local firstPlayerSpawned = false
	local load_queue = {}

	hook.Add("PlayerInitialSpawn", "iPM._PIS", function(ply)
		load_queue[ ply ] = true

		if firstPlayerSpawned == true then return end

		include('ipm/ipm_config.lua')

		LoadIPMSpawnPads()

		hook.Run("iPM_Loaded")

		firstPlayerSpawned = true
	end)

	hook.Add( "StartCommand", "iPM._SC", function( ply, cmd )
		if load_queue[ ply ] and not cmd:IsForced() then
			load_queue[ ply ] = nil

			net.Start("iPM.ClientReady")
			net.Send(ply)
		end
	end )
end