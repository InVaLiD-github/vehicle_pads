AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.

include('shared.lua')
 
util.AddNetworkString("ipm_show_spawnpad_menu")
util.AddNetworkString("ipm_spawnpad_setup")
util.AddNetworkString("ipm_remove_pad")


function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "PadNumber")
	self:NetworkVar("String", 0, "Faction")
	self:NetworkVar("Bool", 0, "Occupied")
end

function ENT:Initialize()
 
	if iPM == nil then iPM = {} end
	if iPM.SpawnPads == nil then 
		iPM.SpawnPads = {} 

		if iPM.Teams == nil then include('config.lua') end

		for t,v in pairs(iPM.Teams) do
			iPM.SpawnPads[t] = {}
		end
	end

	self:SetModel( "models/hunter/plates/plate8x8.mdl" )
	self:SetMaterial("Models/effects/vol_light001")
	self:SetColor4Part(255,255,255,1)
	self:SetRenderMode(1)
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox

    local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	self:SetCollisionGroup(COLLISION_GROUP_WORLD)

	if self:GetCreator() != nil && self:GetCreator():IsPlayer() then
		net.Start("ipm_show_spawnpad_menu")
			net.WriteEntity(self)
		net.Send(self:GetCreator())
	end

	net.Receive("ipm_remove_pad", function(len, ply)
		if ply == self:GetCreator() then
			self:Remove()
		end
	end)

	self.Occupied = false
	self.OccupyingShip = nil
	self.Initialized = false
	self.OccupyingShipWasDeleted = false
	self:SetOccupied(false)

	local min, max = self:GetModelBounds()

	local function UseConsole(ply)
		if self.Occupied == false then
			if iPM.Teams[self.team]["TEAMS"][ply:Team()] != nil then
				net.Start("pilot_vgui")
					net.WriteEntity(self)
				net.Send(ply)
			else
				ply:ChatPrint("iPM: You do not have access to spawn vehicles on this pad.")
			end
		else
			ply:ChatPrint("iPM: Pad "..self.PadNumber.." is already occupied!")
		end
	end

	self.Console1 = ents.Create("gmod_button")
	self.Console1:SetModel("models/hunter/plates/plate025x025.mdl")
	self.Console1.UseCooldown = CurTime()
	function self.Console1:Use(ply)
		if self.UseCooldown < CurTime() then
			UseConsole(ply)
			self.UseCooldown = CurTime()+3
		end
	end
	self.Console1:Spawn()
	if self.Console1:GetPhysicsObject() != nil then
		self.Console1:GetPhysicsObject():EnableMotion(false)
	end

	local ang = self:GetAngles()
    ang = ang + Angle(0,45,45)
    local pos = Vector(max.x, min.y/2 - max.y/2, max.z + 43)
    pos = self:LocalToWorld(pos)
	self.Console1:SetPos(pos)
	self.Console1:SetAngles(ang)
	self.Console1:SetParent(self)
	self.Console1:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self.Console1:SetRenderMode(1)
	self.Console1:SetColor(Color(0,0,0,0))

	self.Console2 = ents.Create("gmod_button")
	self.Console2:SetModel("models/hunter/plates/plate025x025.mdl")
	self.Console2.UseCooldown = CurTime()
	function self.Console2:Use(ply)
		if self.UseCooldown < CurTime() then
			UseConsole(ply)
			self.UseCooldown = CurTime()+3
		end
	end
	self.Console2:Spawn()
	if self.Console2:GetPhysicsObject() != nil then
		self.Console2:GetPhysicsObject():EnableMotion(false)
	end
	local ang = self:GetAngles()
    ang = ang + Angle(0,-135,45)
    local pos = Vector(min.x/2 + min.y/2, max.y, max.z + 43)
    pos = self:LocalToWorld(pos)
	self.Console2:SetPos(pos)
	self.Console2:SetAngles(ang)
	self.Console2:SetParent(self)
	self.Console2:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self.Console2:SetRenderMode(1)
	self.Console2:SetColor(Color(0,0,0,0))

	function self:initSelf(t, pN)
		self.team = t
		if pN == nil then
			self.PadNumber = table.Count(iPM.SpawnPads[t]) + 1
			self:SetPadNumber(self.PadNumber)
		else
			self.PadNumber = pN
			self:SetPadNumber(pN)
		end
		self:SetFaction(t)
		if !table.HasValue(iPM.SpawnPads[t], self) then
			table.insert(iPM.SpawnPads[t], self)
		end
	
		self.Initialized = true

		timer.Create("ipm.Fuck!"..self:GetCreationID(), 0.1, 1, function()
			net.Start("ipm_spawnpad_setup")
				net.WriteEntity(self)
			net.Broadcast()
		end)
	end

	net.Receive("ipm_spawnpad_setup", function(len, ply)
		local t = net.ReadString()
		self:initSelf(t)
	end)

	hook.Add("iPM.LoadFromData", "oa"..self:GetCreationID(), function(pad, t, pN)
		pad:initSelf(t, pN)
	end)
end

function ENT:OnRemove()
	for t,v in pairs(iPM.SpawnPads) do
		for k,v1 in pairs(iPM.SpawnPads[t]) do
			if v1 == self then
				iPM.SpawnPads[t][k] = nil
			end
		end
	end
end

function ENT:Use( activator, caller )
    return
end

function ENT:Think()
	if self.Initialized then

	    local maxs = self:OBBMaxs()
		local mins = self:OBBMins()

		for _, ent in pairs(ents.FindInBox(self:GetPos() - mins, self:GetPos() - (maxs - Vector(0,0,250)))) do
			if table.HasValue(iPM.Ships, ent:GetClass()) then

				if self.Occupied == false then
					self.OccupyingShip = ent
					if self.OccupyingShip != nil then 

						local pad = self
						function self.OccupyingShip:OnRemove()
							pad.OccupyingShipWasDeleted = true
							pad.Occupied = false
							pad:SetOccupied(false)
							pad.OccupyingShip = nil
						end

						self.Occupied = true
						self:SetOccupied(true)
						self.OccupyingShipWasDeleted = false

						timer.Create("iPM.StayingCheck"..self:GetCreationID(), 5, 1, function()
							if self.OccupyingShip != nil then
								if self.OccupyingShip.LastPlayer != nil && self.OccupyingShip.LastPlayer:IsPlayer() then
									self.OccupyingShip.LastPlayer:ChatPrint("Pad "..self.PadNumber..": Your vehicle is occupying this pad, it will be removed in "..iPM.ShipDespawnTime.." seconds.")
								end

								timer.Create("iPM.RemoveShip"..self:GetCreationID(), iPM.ShipDespawnTime, 1, function()
									self.OccupyingShip:Remove()
								end)
							end
						end)
					end
				end

			end
		end

		if self.Occupied == true && self.OccupyingShipWasDeleted == false then
			if self.OccupyingShip != NULL && IsEntity(self.OccupyingShip) && self.OccupyingShip != nil && !self.OccupyingShip:GetPos():WithinAABox(self:GetPos() - mins, self:GetPos() - (maxs - Vector(0,0,250))) then
				
				if self.OccupyingShip:GetDriver() != nil && self.OccupyingShip:GetDriver():IsPlayer() then
					self.OccupyingShip.LastPlayer = self.OccupyingShip:GetDriver()
				end
				
				if timer.Exists("iPM.RemoveShip"..self:GetCreationID()) then
					timer.Stop("iPM.RemoveShip"..self:GetCreationID())
				end

				self.OccupyingShip = nil
				self.Occupied = false
				self:SetOccupied(false)
			end

			if self.OccupyingShip == NULL then
				if timer.Exists("iPM.RemoveShip"..self:GetCreationID()) then
					timer.Stop("iPM.RemoveShip"..self:GetCreationID())
				end

				self.OccupyingShip = nil
				self.Occupied = false
				self:SetOccupied(false)
			end
		end

	end
end