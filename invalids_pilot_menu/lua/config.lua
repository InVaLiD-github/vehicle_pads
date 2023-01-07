if iPM == nil then iPM = {} end //getchur grubby hands off this


iPM.PilotCooldownTime = 2*60 // Time until a pilot can spawn another ship, Runs in seconds, so 2*60 is 2 minutes
iPM.ShipDespawnTime = 5*60 // Time until a ship landed on a pad is despawned. Runs in seconds, so 5*60 is 5 minutes


--[[ 
	Team Configuration.

	This is going to require explanation.
	The overall format should go as follows:

		["<TEAM NAME>"] = {
			["TEAMS"] = {
				[<TEAM_EXAMPLE>] = {"<ship_1>", "<ship_2>"},
				[<TEAM_EXAMPLE2>] = {"<ship_2>"},
			},
			["COLOR"] = {<R>, <G>, <B>}
		},

	The values that start with '<' and end with a '>' are user-modifiable. anything that doesn't have these can not be modified or the script will break.
		^ Note that, you shouldn't actually have the '<' and '>' in the values; these symbols are just for explanatory purposes. Here's a real-world example:

		["IMPERIALS"] = {
			["TEAMS"] = {
				[TEAM_A] = {"lfs_tiehunter", "lunasflightschool_tieadvanceddigger", "lunasflightschool_tiefighterdigger", "lunasflightschool_niksacokica_74-z_speeder_bike"},
				[TEAM_B] = {"lfs_tiehunter", "lunasflightschool_niksacokica_74-z_speeder_bike"},
			},
			["COLOR"] = {88, 175, 252}
		},

--]] 

iPM.Teams = {// Don't Touch

	-- Add teams beween these two brackets, and delete this comment.
	-- BE SURE TO READ THE EXPLANATION ABOVE

}// Don't Touch


--[[ 
	Below are the angle offsets, if you're having issues with ships spawning backwards on the pad (or just awkwardly) then add the classname in square brackets and fiddle with the angle.

	EX: ["lunasflightschool_awing"] = Angle(0,90,0), 
--]] 

iPM.Offsets = { // Don't Touch

	-- Add offsets here, delete the comments like you did with iPM.Teams :)
	-- IF YOU DIDN'T ALREADY, READ THE EXPLANATION ABOVE!

} // Don't touch


















































































-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DO NOT TOUCH BELOW THIS LINE UNLESS YOU WANT SHIT TO BE BROKEN!
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
for name,v in pairs(iPM.Teams) do
	iPM.Ships = {}
	for k,v1 in pairs(iPM.Teams[name]["TEAMS"]) do
		for k1, v1 in pairs(iPM.Teams[name]["TEAMS"][k]) do
			if !table.HasValue(iPM.Ships, v1) then
				table.insert(iPM.Ships, v1)
			end
		end
	end
end