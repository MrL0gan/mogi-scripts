--- Team Assignment
--- by Yellow/@GlowingTail
local teamColors = {
	SKINCOLOR_TANGERINE,
	SKINCOLOR_SAPPHIRE
}

---Console variable that determines if players can change their own team assignment or not.
local CV_LockTeams = CV_RegisterVar{
	name = 			"lockteams",
	description = 	"Prevents players from being able to change their team assignment.",
	flags = 		CV_NETVAR,

	defaultvalue = "Off",
	possiblevalue = CV_OnOff
}

---Validates an userdata.
---@param ud userdata
---@return boolean
local function isValid(ud)
	return ud and ud.valid
end

---Syncs the set team colors.
---@param n function
local function syncTeamColors(n)
	teamColors = n($)
end

---Sets a team's color.
---@param caller player_t
---@param team string
---@param color string
local function setTeamColor(caller, team, color)
	if not teamplay
		CONS_Printf(caller, "\131NOTICE: \128This command cannot be used currently.")
		return end

	team = tonumber($)
	if not team
		CONS_Printf(caller, "setteamcolor <team> <color>: Sets a team's color.")
		return end

	if not teamColors[team]
		CONS_Printf(caller, "Team \$tostring(team)\ is not a valid team.")
		return end

	if not color
		CONS_Printf(caller, "Team \$tostring(team)\ color is currently \"\$R_GetNameByColor(teamColors[team])\\".")
		return end

	local teamcolor = R_GetColorByName(color)
	if not (teamcolor and skincolors[teamcolor] and skincolors[teamcolor].accessible)
		CONS_Printf(caller, "\"\$color\\" is not a possible value for \"setteamcolor\".")
		return end

	if teamColors[team] == teamcolor
		CONS_Printf(caller, "Team #\$team\'s color is already set to \"\$R_GetNameByColor(teamcolor)\\"!")
		return end

	teamColors[team] = teamcolor
	CONS_Printf(caller, "\131NOTICE: \128Team #\$team\'s color will change to \"\$R_GetNameByColor(teamColors[team])\\" next match.")
	chatprint("\130Teams: Team #\$team\'s color will change to \"\$R_GetNameByColor(teamColors[team])\\".", true)
end

---Allows players to select the team they want to be part of.
---@param player player_t
---@param team string
local function selectTeam(player, team)
	if not isValid(player)
		return end

	if not teamplay
		CONS_Printf(player, "\131NOTICE: \128This command cannot be used currently.")
		return end

	if CV_LockTeams.value
		CONS_Printf(player, "Server is not allowing team changes at the moment.")
		return end

	team = tonumber($)
	if not team
		CONS_Printf(player, "selectteam <team>: Allows you to set the team you want to be on.")
		return end

	if not teamColors[team]
		CONS_Printf(player, "Team \$tostring(team)\ is not a valid team.")
		return end

	if player.selectedteam == team
		CONS_Printf(player, "You're already on Team #\$team\!")
		return end

	player.selectedteam = team
	CONS_Printf(player, "\131NOTICE: \128Your change to Team #\$team\ will take effect next match.")
	chatprint("\130Teams: \$player.name\ will change to Team #\$team\.", true)
end

---Assigns the teams that the players have selected.
local setSelectedTeams = do
	if not teamplay
		return end

	for player in players.iterate do
		if not isValid(player)
			continue end

		player.team = player.selectedteam or $

		if teamColors[player.team]
			player.skincolor = teamColors[player.team]
		end
	end
end

addHook("NetVars", syncTeamColors)
addHook("MapLoad", setSelectedTeams)

COM_AddCommand("setteamcolor", setTeamColor, COM_ADMIN)
COM_AddCommand("selectteam",   selectTeam)
COM_AddCommand("selectteam2",  selectTeam, COM_PLAYER2)
COM_AddCommand("selectteam3",  selectTeam, COM_PLAYER3)
COM_AddCommand("selectteam4",  selectTeam, COM_PLAYER4)