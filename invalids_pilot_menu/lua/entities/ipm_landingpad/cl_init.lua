
include('shared.lua')

function ENT:Initialize()
    if table.Count(string.Explode("", self:GetPadNumber())) == 1 then
        self.PadNumber = "0"..self:GetPadNumber()
    else
        self.PadNumber = self:GetPadNumber()
    end

    if self.WasSetup == nil then self.WasSetup = false end
end

local function doRender(ent)
    -- Get the size of the text we are about to draw
    local text = "Pad "..ent.PadNumber
    surface.SetFont( "DermaLarge" )
    local tW, tH = surface.GetTextSize( "Pad "..ent.PadNumber )
    -- This defines amount of padding for the box around the text
    local pad = 5
    -- Draw a rectable. This has to be done before drawing the text, to prevent overlapping
    -- Notice how we start drawing in negative coordinates
    -- This is to make sure the 3d2d display rotates around our position by its center, not left corner
    surface.SetDrawColor( 255,255,255, 255 )
    surface.DrawOutlinedRect( -tW / 2 - pad, -pad, tW + pad * 2, tH + pad * 2, 2 )
    -- Draw some text
    draw.SimpleText( "Pad "..ent.PadNumber, "DermaLarge", -tW / 2, 0, Color(255,255,255) )
end

local function consoleRender(ent)

    -- Get the size of the text we are about to draw
    local text = ""
    local col = Color(255,255,255)
    if ent:GetOccupied() == true then
        text = "Occupied"
    else
        text = "Vacant"
    end
    surface.SetFont( "DermaLarge" )
    local tW1, tH1 = surface.GetTextSize( text )
    local tW2, tH2 = surface.GetTextSize( "Pad "..ent.PadNumber )

    local tW = tW1 + tW2
    local tH = (tH1 + tH2) - 35
    -- This defines amount of padding for the box around the text
    local padW = 15
    local padH = 35
    -- Draw a rectable. This has to be done before drawing the text, to prevent overlapping
    -- Notice how we start drawing in negative coordinates
    -- This is to make sure the 3d2d display rotates around our position by its center, not left corner
    surface.SetDrawColor( iPM.Teams[ent:GetFaction()]["COLOR"][1],iPM.Teams[ent:GetFaction()]["COLOR"][2],iPM.Teams[ent:GetFaction()]["COLOR"][3],50 )
    surface.DrawRect(-tW / 2 - padW, padW/2 - tH*2, tW + padW * 2, tH + padH*2)
    surface.SetDrawColor( iPM.Teams[ent:GetFaction()]["COLOR"][1],iPM.Teams[ent:GetFaction()]["COLOR"][2],iPM.Teams[ent:GetFaction()]["COLOR"][3], 255 )
    surface.DrawOutlinedRect( -tW / 2 - padW, padW/2 - tH*2, tW + padW * 2, tH + padH*2,  2)
    -- Draw some text
    draw.SimpleText( "Pad "..ent.PadNumber, "DermaLarge", -tW2 / 2, tH/2-tW2/2, Color(255,255,255) )
    draw.SimpleText( text, "DermaLarge", -tW1 / 2, tH/2-tH2/2, col )
end

function ENT:Draw()
    self:DrawModel()
    if self.WasSetup == true then
        if self:GetFaction() != "" then

            local col = Color(iPM.Teams[self:GetFaction()]["COLOR"][1], iPM.Teams[self:GetFaction()]["COLOR"][2], iPM.Teams[self:GetFaction()]["COLOR"][3])

            local min, max = self:GetModelBounds()
            local minWorld, maxWorld = self:LocalToWorld(min), self:LocalToWorld(max)

            -- Calculate the width and height of the rectangle in world coordinates
            local width = (maxWorld - minWorld):Length()
            local height = (maxWorld - minWorld):Length()

            cam.Start3D2D(self:GetPos(), self:GetAngles(), 0.7)
              surface.SetDrawColor(iPM.Teams[self:GetFaction()]["COLOR"][1], iPM.Teams[self:GetFaction()]["COLOR"][2], iPM.Teams[self:GetFaction()]["COLOR"][3], 255)
              surface.DrawOutlinedRect(-width/2, -height/2, width, height, 4)
            cam.End3D2D()

            cam.Start3D2D(self:GetPos(), self:GetAngles(), 1)
                surface.DrawCircle(0, 0, 100, col)
                surface.DrawCircle(0, 0, 75, col)
                surface.DrawCircle(0, 0, 50, col)
                surface.DrawCircle(0, 0, 25, Color(255,255,255))
                surface.DrawCircle(0, 0, 5, Color(255,255,255))
            cam.End3D2D()

            local min, max = self:GetModelBounds()
            local corner1 = max + Vector(0, 0, 10)
            local cornerWorld1 = self:LocalToWorld(corner1)

            local ang = self:GetAngles()

            ang.y = LocalPlayer():EyeAngles().y - 90
            ang.z = 90

            cam.Start3D2D(cornerWorld1, ang, 0.25)
                doRender(self)
            cam.End3D2D()

            local corner2 = min
            corner2.z = corner1.z
            local cornerWorld2 = self:LocalToWorld(corner2)

            cam.Start3D2D(cornerWorld2, ang, 0.25)
                doRender(self)
            cam.End3D2D()

            local ang = self:GetAngles()
            ang = ang + Angle(0,45,45)
            local pos = Vector(max.x, min.y/2 - max.y/2, max.z + 45)
            pos = self:LocalToWorld(pos)

            if LocalPlayer():GetPos():Distance(pos) < 400 then
                cam.Start3D2D(pos, ang, 0.1)
                    consoleRender(self)
                cam.End3D2D()
            end

            
            local ang = self:GetAngles()
            ang = ang + Angle(0,-135,45)
            local pos = Vector(min.x/2 + min.y/2, max.y, max.z + 45)
            pos = self:LocalToWorld(pos)
            if LocalPlayer():GetPos():Distance(pos) < 400 then
                cam.Start3D2D(pos, ang, 0.1)
                    consoleRender(self)
                cam.End3D2D()
            end
        end
    end
end

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "PadNumber")
    self:NetworkVar("String", 0, "Faction")
    self:NetworkVar("Bool", 0, "Occupied")
end

net.Receive("ipm_show_spawnpad_menu", function()
    local pad = net.ReadEntity()
    local frame = vgui.Create("XPFrame")
    frame:SetSize(ScrW()/8, ScrH()/8)
    frame:Center()
    frame:SetTitle("Select Faction")
    frame:MakePopup()
    frame.ProperlyClosed = false

    function frame:OnRemove()
        if frame.ProperlyClosed == false then
            net.Start("ipm_remove_pad")
            net.SendToServer()
        end
    end

    local dropdown = vgui.Create("XPComboBox", frame)
    dropdown:DockMargin(10, 10, 10, 10)
    dropdown:Dock(TOP)
    dropdown:SetValue("Select Owning Faction..")

    for name,v in pairs(iPM.Teams) do
        dropdown:AddChoice(name)
    end

    function dropdown:OnSelect(i, v, d)
        if dropdown.submit != nil then dropdown.submit:Remove() end

        dropdown.submit = vgui.Create("XPButton", frame)
        dropdown.submit:DockMargin(10, 10, 10, 10)
        dropdown.submit:Dock(BOTTOM)
        dropdown.submit:SetText("Make Landing Pad")

        function dropdown.submit:DoClick()
            net.Start("ipm_spawnpad_setup")
            net.WriteString(v)
            net.SendToServer()

            frame.ProperlyClosed = true
            frame:Close()
        end
    end
end)

