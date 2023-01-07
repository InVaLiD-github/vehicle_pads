if SERVER then util.AddNetworkString("iPM.SendAllToClient") end

hook.Add("InitPostEntity", "iPMLoadShit", function()
	include('config.lua')
	AddCSLuaFile('config.lua')

	timer.Create("iPM.useless", 0, 1, function() 
		hook.Run("iPM_Loaded") 
	end)
	
	if SERVER then
		timer.Create("iPM.Wait", 5, 1, function()
			LoadIPMSpawnPads()
		end)
	end
end)