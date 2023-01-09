-- This function saves the 'ipm_spawnpad' entities to a data file
function SaveIPMSpawnPads()
  -- Create a table to store the data of each 'ipm_spawnpad'
  local data = {}

  -- Iterate through all 'ipm_spawnpad' entities
  for _, pad in pairs(ents.GetAll()) do
    if pad:GetClass() == "ipm_landingpad" then
      if pad:GetPadNumber() != nil && pad:GetFaction() != nil then 
          table.insert(data, {
              padNumber = pad:GetPadNumber(),
              team = pad:GetFaction(),
              pos = pad:GetPos(),
              ang = pad:GetAngles()
          })
      end
    end
  end

  -- Convert the table to a JSON string
  local json = util.TableToJSON(data)

  -- Save the JSON string to a data file
  file.Write("landingpads.txt", json)
end

-- This function loads the 'ipm_spawnpad' data from the data file and
-- spawns the 'ipm_spawnpad' entities in the world
function LoadIPMSpawnPads()
  -- Read the data file
  local json = file.Read("landingpads.txt", "DATA")

  -- If the data file doesn't exist, do nothing
  if not json then return end

  -- Convert the JSON string back to a table
  local data = util.JSONToTable(json)

  if istable(data) && table.Count(data) >= 1 then
      -- Iterate through all 'ipm_spawnpad' data
      for _, padData in pairs(data) do
        -- Create a new 'ipm_spawnpad' entity with the saved data
        local pad = ents.Create("ipm_landingpad")
        pad:SetPos(padData.pos)
        pad:SetAngles(padData.ang)
        pad:Spawn()

        local physObj = pad:GetPhysicsObject()

        if IsValid(physObj) then
          physObj:EnableMotion(false)
        end

        timer.Create("iPM.SpawnPadButGottaWait"..pad:GetCreationID(), 0,1, function()
          if padData.padNumber != nil && padData.team != nil then
            if padData.padNumber != 0 && padData.team != "" then
              hook.Run("iPM.LoadFromData", pad, padData.team, padData.padNumber)
            end
          end
        end)
      end
    end
  end


-- This chat command allows superadmins to save the 'ipm_spawnpad' entities
concommand.Add("ipm_save", function(player)
  -- Check if the player is a superadmin
  if not table.HasValue(iPM.Admins, player:GetUserGroup()) then
    -- The player is not a superadmin, so do nothing
    return
  end

  -- The player is a superadmin, so save the 'ipm_spawnpad'
  SaveIPMSpawnPads()

  -- Inform the player that the 'ipm_spawnpad' entities have been saved
  player:ChatPrint("Saved all 'ipm_spawnpad' entities to data file.")
end)

hook.Add("PostCleanupMap", "iCP.RespawnPads", function()
    LoadIPMSpawnPads()
end)