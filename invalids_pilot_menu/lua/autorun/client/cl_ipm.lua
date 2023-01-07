hook.Add("iPM_Loaded", "cl", function()

	-- Create a table to store the icons for the Tie Fighters
	local tieFighterIcons = {}

	-- Create a function to draw the vgui
	local function drawVGUI(pad)
		-- Create the frame for the vgui
		local frame = vgui.Create("XPFrame")
		frame:SetSize(ScrW()/8, ScrH()/8)

		frame:SetTitle("Vehicle Spawn Menu")
		frame:SetVisible(true)
		-- Center the frame on the player's screen
		frame:Center()
		frame:MakePopup()

		local dropdown = vgui.Create("XPComboBox", frame)
		dropdown:DockMargin(10, 10, 10, 10)
		dropdown:Dock(TOP)
		dropdown:SetValue("Select Ship..")

		dropdown.added = {}
		-- Loop through the list of Tie Fighters
		for name, v in pairs(iPM.Teams) do
			for k,v1 in pairs(list.Get("SpawnableEntities")) do
				if iPM.Teams[name]['TEAMS'][LocalPlayer():Team()] != nil then
					if table.HasValue(iPM.Teams[name]["TEAMS"][LocalPlayer():Team()], v1.ClassName) then
						v1.SpawnName = k
						if !table.HasValue(dropdown.added, v1.SpawnName) then
							dropdown:AddChoice(v1.PrintName, {v1.PrintName, v1.ClassName})
							table.insert(dropdown.added, v1.SpawnName)
						end
					end
				end
			end
		end

		function dropdown:OnSelect(index, text, data)
			if dropdown.button != nil then dropdown.button:Remove() end

			-- Create the button for spawning Tie Fighters
			dropdown.button = vgui.Create("XPButton", frame)
			dropdown.button:DockMargin(10, 10, 10, 10)
			dropdown.button:Dock(BOTTOM)
			dropdown.button:SetText("Spawn "..data[1])

			-- Create a function for the button's OnClick event
			function dropdown.button:DoClick()
				net.Start("spawn_tie_fighter")
					net.WriteString(data[2])
					net.WriteEntity((pad or nil))
				net.SendToServer()

				frame:Close()
			end
		end

	end

	-- Create a net message to receive the vgui
	net.Receive("pilot_vgui", function()
		local pad = net.ReadEntity()
		drawVGUI((pad or nil))
	end)

	-- Create a hook to gray out the button if the player is on cooldown
	hook.Add("Think", "cooldown_think", function()
		-- Check if the vgui frame exists
		if not frame then return end

		-- Check if the player is on cooldown
		local onCooldown = net.ReadBool()

		-- Set the button's color based on the cooldown status
		button:SetColor(onCooldown and Color(100, 100, 100) or Color(255, 255, 255))

	end)


	function iPM.ClientSetup(ent)
	    if table.Count(string.Explode("", ent:GetPadNumber())) == 1 then
	        ent.PadNumber = "0"..ent:GetPadNumber()
	    else
	        ent.PadNumber = ent:GetPadNumber()
	    end

	    ent.WasSetup = true
	end

	net.Receive("ipm_spawnpad_setup", function()
	    local ent = net.ReadEntity()
	    iPM.ClientSetup(ent)
	end)
end)

net.Receive("iPM.SendAllToClient", function()
	if iPM == nil then iPM = {} end
	hook.Run("iPM_Loaded") 
	local spawnpads = net.ReadTable()
	timer.Create("iPM.ImGoingToShitABrick", 1, 1, function()
		for _, ent in pairs(ents.GetAll()) do
			if ent:GetClass() == "ipm_landingpad" then
				iPM.ClientSetup(ent)
			end
		end
	end)
	
end)